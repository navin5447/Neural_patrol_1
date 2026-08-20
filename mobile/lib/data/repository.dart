import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/audit_log_entry.dart';
import '../models/case_file.dart';
import '../models/custody_event.dart';
import '../models/dashboard_summary.dart';
import '../models/device_info.dart';
import '../models/evidence_image.dart';
import '../models/field_result.dart';
import '../models/fsl_handoff.dart';
import '../models/sample.dart';
import '../models/test_run.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/local_store.dart';

/// Maps foreign-key style body fields to the entity type they reference, so
/// [Repository.syncPending] can rewrite locally-generated negative ids to
/// the real server ids once a dependency has synced.
const Map<String, String> _refEntityForField = {
  'case_id': 'cases',
  'sample_id': 'samples',
  'test_run_id': 'test_runs',
};

/// Data-access layer for every SpeciesTrace entity. Every write is
/// online-first: it tries the FastAPI backend, and only falls back to a
/// local, queued-for-sync record if the network itself is unreachable.
/// Validation/auth errors from a reachable server are never swallowed —
/// they propagate so the UI can show the officer what went wrong.
class Repository extends ChangeNotifier {
  final ApiClient api;
  final LocalStore local;
  final _rand = Random();

  bool _online = true;
  int _pendingCount = 0;
  bool _syncing = false;

  Repository({required this.api, required this.local}) {
    _refreshPendingCount();
  }

  bool get isOnline => _online;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _syncing;

  void _setOnline(bool value) {
    if (_online != value) {
      _online = value;
      notifyListeners();
    }
  }

  Future<void> _refreshPendingCount() async {
    _pendingCount = await local.pendingCount();
    notifyListeners();
  }

  String _newOpId() => '${DateTime.now().microsecondsSinceEpoch}-${_rand.nextInt(1 << 32)}';

  // ---------------------------------------------------------------------
  // Generic helpers
  // ---------------------------------------------------------------------

  List<T> _toModels<T>(
    List<Map<String, dynamic>> raw,
    T Function(Map<String, dynamic> json, {bool pendingSync}) fromJson,
  ) {
    return raw.map((e) {
      final id = e['id'];
      final pending = id is num && id < 0;
      return fromJson(e, pendingSync: pending);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchListMerged(
    String path,
    Map<String, dynamic>? query,
    String cacheKey,
  ) async {
    try {
      final result = await api.get(path, query: query);
      final serverItems = (result as List).cast<Map<String, dynamic>>();
      final existing = await local.getList(cacheKey);
      final pendingOnly = existing.where((e) => (e['id'] as num) < 0).toList();
      final merged = [...pendingOnly, ...serverItems];
      await local.setList(cacheKey, merged);
      _setOnline(true);
      unawaited(syncPending());
      return merged;
    } on ApiNetworkException {
      _setOnline(false);
      return local.getList(cacheKey);
    }
  }

  Future<T> _createWithFallback<T>({
    required String path,
    required Map<String, dynamic> body,
    required String entityType,
    required T Function(Map<String, dynamic> json, {bool pendingSync}) fromJson,
    List<String> cacheKeys = const [],
    Map<String, dynamic> Function()? localDefaults,
  }) async {
    try {
      final json = await api.post(path, body: body) as Map<String, dynamic>;
      for (final key in cacheKeys) {
        await local.upsert(key, json);
      }
      _setOnline(true);
      unawaited(syncPending());
      return fromJson(json, pendingSync: false);
    } on ApiNetworkException {
      _setOnline(false);
      final localId = await local.nextLocalId();
      final localJson = {
        ...body,
        ...?localDefaults?.call(),
        'id': localId,
      };
      for (final key in cacheKeys) {
        await local.upsert(key, localJson);
      }
      await local.addPendingOp(PendingOp(
        id: _newOpId(),
        method: 'POST',
        path: path,
        body: body,
        entityLabel: entityType,
        entityType: entityType,
        localEntityId: localId,
        idRefFields: _refEntityForField.keys.toList(),
        createdAt: DateTime.now(),
      ));
      await _refreshPendingCount();
      return fromJson(localJson, pendingSync: true);
    }
  }

  /// Best-effort replay of everything queued while offline. Safe to call
  /// repeatedly (e.g. on pull-to-refresh or after a successful call) — it
  /// no-ops quickly if there's nothing pending or the network is still down.
  Future<void> syncPending() async {
    if (_syncing) return;
    final ops = await local.getPendingOps();
    if (ops.isEmpty) return;
    _syncing = true;
    notifyListeners();

    final idMap = <String, Map<int, int>>{};
    try {
      for (final op in ops) {
        final resolvedBody = Map<String, dynamic>.from(op.body);
        var blocked = false;
        for (final entry in _refEntityForField.entries) {
          final value = resolvedBody[entry.key];
          if (value is num && value < 0) {
            final resolved = idMap[entry.value]?[value.toInt()];
            if (resolved != null) {
              resolvedBody[entry.key] = resolved;
            } else {
              blocked = true;
            }
          }
        }
        if (blocked) continue;

        try {
          final json = await api.post(op.path, body: resolvedBody) as Map<String, dynamic>;
          final serverId = json['id'] as int;
          idMap.putIfAbsent(op.entityType, () => {})[op.localEntityId] = serverId;
          await local.replaceLocalId(op.entityType, op.localEntityId, json);
          await local.removePendingOp(op.id);
          _setOnline(true);
        } on ApiNetworkException {
          _setOnline(false);
          break;
        } on ApiHttpException {
          // Server reachable but permanently rejected this queued write
          // (e.g. stale reference). Drop it rather than retry forever.
          await local.removePendingOp(op.id);
        }
      }
    } finally {
      _syncing = false;
      await _refreshPendingCount();
    }
  }

  // ---------------------------------------------------------------------
  // Cases
  // ---------------------------------------------------------------------

  Future<List<CaseFile>> listCases() async {
    final raw = await _fetchListMerged('/cases', null, 'cases');
    return _toModels(raw, CaseFile.fromJson);
  }

  Future<CaseFile> createCase({required String caseNumber, String? title, String? location}) {
    return _createWithFallback(
      path: '/cases',
      body: {'case_number': caseNumber, 'title': title, 'location': location},
      entityType: 'cases',
      fromJson: CaseFile.fromJson,
      cacheKeys: ['cases'],
      localDefaults: () => {'created_at': DateTime.now().toIso8601String(), 'created_by_user_id': 0},
    );
  }

  // ---------------------------------------------------------------------
  // Samples
  // ---------------------------------------------------------------------

  Future<List<Sample>> listSamples({int? caseId}) async {
    final cacheKey = caseId != null ? 'samples_case_$caseId' : 'samples';
    final raw = await _fetchListMerged('/samples', caseId != null ? {'case_id': caseId} : null, cacheKey);
    return _toModels(raw, Sample.fromJson);
  }

  Future<Sample> createSample({
    required int caseId,
    required String sampleType,
    String? location,
    String? officerName,
    String? date,
    String? time,
    String? notes,
    double? gpsLat,
    double? gpsLon,
    String? deviceId,
    String? operatorId,
  }) {
    return _createWithFallback(
      path: '/samples',
      body: {
        'case_id': caseId,
        'sample_type': sampleType,
        'location': location,
        'officer_name': officerName,
        'date': date,
        'time': time,
        'notes': notes,
        'gps_lat': gpsLat,
        'gps_lon': gpsLon,
        'device_id': deviceId,
        'operator_id': operatorId,
      },
      entityType: 'samples',
      fromJson: Sample.fromJson,
      cacheKeys: ['samples', 'samples_case_$caseId'],
      localDefaults: () => {
        'sample_code': 'PENDING-${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
        'sealed_status': false,
        'preserved_status': false,
      },
    );
  }

  // ---------------------------------------------------------------------
  // Custody events
  // ---------------------------------------------------------------------

  Future<List<CustodyEvent>> listCustodyEvents(int sampleId) async {
    final raw = await _fetchListMerged('/samples/$sampleId/custody-events', null, 'custody_events_$sampleId');
    return _toModels(raw, CustodyEvent.fromJson);
  }

  Future<CustodyEvent> addCustodyEvent({
    required int sampleId,
    required String eventType,
    required int whoUserId,
    required String whatAction,
    String? whereLocation,
    String? notes,
  }) {
    return _createWithFallback(
      path: '/samples/$sampleId/custody-events',
      body: {
        'sample_id': sampleId,
        'event_type': eventType,
        'who_user_id': whoUserId,
        'what_action': whatAction,
        'where_location': whereLocation,
        'notes': notes,
      },
      entityType: 'custody_events',
      fromJson: CustodyEvent.fromJson,
      cacheKeys: ['custody_events_$sampleId'],
      localDefaults: () => {
        'when_ts': DateTime.now().toIso8601String(),
        'previous_hash': 'PENDING_SYNC',
        'current_hash': 'PENDING_SYNC',
        'is_immutable': true,
      },
    );
  }

  // ---------------------------------------------------------------------
  // Devices
  // ---------------------------------------------------------------------

  Future<List<DeviceInfo>> listDevices() async {
    final raw = await _fetchListMerged('/devices', null, 'devices');
    return _toModels(raw, DeviceInfo.fromJson);
  }

  Future<DeviceInfo> connectDevice({required String deviceName, required String serialNumber, String? hwVersion}) {
    return _createWithFallback(
      path: '/devices/connect',
      body: {'device_name': deviceName, 'serial_number': serialNumber, 'hw_version': hwVersion},
      entityType: 'devices',
      fromJson: DeviceInfo.fromJson,
      cacheKeys: ['devices'],
      localDefaults: () => {'status': 'connected', 'last_seen_at': DateTime.now().toIso8601String()},
    );
  }

  // ---------------------------------------------------------------------
  // Test runs + telemetry
  // ---------------------------------------------------------------------

  Future<TestRun> createTestRun({required int sampleId, required int deviceId, String? assayProfileId}) {
    return _createWithFallback(
      path: '/test-runs',
      body: {
        'sample_id': sampleId,
        'device_id': deviceId,
        'assay_profile_id': assayProfileId ?? 'research_validation_dependent',
      },
      entityType: 'test_runs',
      fromJson: TestRun.fromJson,
      cacheKeys: ['test_runs'],
      localDefaults: () => {'status': 'started', 'started_at': DateTime.now().toIso8601String()},
    );
  }

  /// Telemetry is ephemeral simulated device chatter, not evidentiary data,
  /// so it is fire-and-forget: dropped silently if offline rather than
  /// queued for replay.
  Future<void> sendTelemetry(int testRunId, Map<String, dynamic> payload) async {
    if (testRunId < 0) return;
    try {
      await api.post('/test-runs/$testRunId/telemetry', body: payload);
    } on ApiNetworkException {
      _setOnline(false);
    } on ApiHttpException {
      // Ignore — telemetry has no evidentiary consequence.
    }
  }

  // ---------------------------------------------------------------------
  // Field results
  // ---------------------------------------------------------------------

  Future<FieldResult> createFieldResult({
    required int testRunId,
    required int sampleId,
    required String targetIndication,
    required bool controlValid,
    required double qualityScore,
    required int recordedByUserId,
    String? imageRef,
    String? rawResultPayload,
  }) {
    return _createWithFallback(
      path: '/field-results',
      body: {
        'test_run_id': testRunId,
        'sample_id': sampleId,
        'status': 'presumptive',
        'target_indication': targetIndication,
        'control_valid': controlValid,
        'quality_score': qualityScore,
        'image_ref': imageRef,
        'raw_result_payload': rawResultPayload,
        'recorded_by_user_id': recordedByUserId,
      },
      entityType: 'field_results',
      fromJson: FieldResult.fromJson,
      cacheKeys: ['field_results_$sampleId', 'field_results_all'],
      localDefaults: () => {
        'recorded_at': DateTime.now().toIso8601String(),
        'previous_record_hash': 'PENDING_SYNC',
        'current_record_hash': 'PENDING_SYNC',
      },
    );
  }

  Future<List<FieldResult>> listFieldResults(int sampleId) async {
    final raw = await _fetchListMerged('/samples/$sampleId/field-results', null, 'field_results_$sampleId');
    return _toModels(raw, FieldResult.fromJson);
  }

  // ---------------------------------------------------------------------
  // Evidence images
  // ---------------------------------------------------------------------

  Future<EvidenceImage> createEvidenceImage({
    required int sampleId,
    required int testRunId,
    required String storageUri,
    required String imageHash,
    required int capturedByUserId,
    String? imageMetadata,
  }) {
    return _createWithFallback(
      path: '/evidence-images',
      body: {
        'sample_id': sampleId,
        'test_run_id': testRunId,
        'storage_uri': storageUri,
        'image_hash': imageHash,
        'image_metadata': imageMetadata,
        'captured_by_user_id': capturedByUserId,
      },
      entityType: 'evidence_images',
      fromJson: EvidenceImage.fromJson,
      cacheKeys: ['evidence_images_$sampleId'],
      localDefaults: () => {'captured_at': DateTime.now().toIso8601String()},
    );
  }

  // ---------------------------------------------------------------------
  // FSL handoffs
  // ---------------------------------------------------------------------

  Future<FslHandoff> createFslHandoff({
    required int sampleId,
    required String qrCodeValue,
    required int dispatchedByUserId,
    String destinationLab = 'AUTHORIZED FSL',
    String physicalSampleStatus = 'sealed_for_confirmation',
  }) {
    return _createWithFallback(
      path: '/fsl-handoffs',
      body: {
        'sample_id': sampleId,
        'destination_lab': destinationLab,
        'field_status': 'presumptive_result_recorded',
        'physical_sample_status': physicalSampleStatus,
        'qr_code_value': qrCodeValue,
        'dispatched_by_user_id': dispatchedByUserId,
      },
      entityType: 'fsl_handoffs',
      fromJson: FslHandoff.fromJson,
      cacheKeys: ['fsl_handoffs_$sampleId', 'fsl_handoffs_all'],
      localDefaults: () => {'dispatched_at': DateTime.now().toIso8601String()},
    );
  }

  Future<List<FslHandoff>> listFslHandoffs(int sampleId) async {
    final raw = await _fetchListMerged('/samples/$sampleId/fsl-handoffs', null, 'fsl_handoffs_$sampleId');
    return _toModels(raw, FslHandoff.fromJson);
  }

  // ---------------------------------------------------------------------
  // Audit + dashboard
  // ---------------------------------------------------------------------

  Future<List<AuditLogEntry>> getAudit(int sampleId) async {
    try {
      final result = await api.get('/audit/$sampleId') as List;
      _setOnline(true);
      return result.cast<Map<String, dynamic>>().map(AuditLogEntry.fromJson).toList();
    } on ApiNetworkException {
      _setOnline(false);
      return [];
    }
  }

  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final json = await api.get('/dashboard/summary') as Map<String, dynamic>;
      _setOnline(true);
      unawaited(syncPending());
      return DashboardSummary.fromJson(json);
    } on ApiNetworkException {
      _setOnline(false);
      final cases = await local.getList('cases');
      final samples = await local.getList('samples');
      final fieldResults = await local.getList('field_results_all');
      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      return DashboardSummary(
        activeCases: cases.length,
        todaysSamples: samples.where((s) => s['date'] == todayStr).length,
        pendingFsl: 0,
        fieldResultsCount: fieldResults.length,
      );
    }
  }
}
