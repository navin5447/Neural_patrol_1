import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single write that could not reach the backend and is queued for replay
/// once connectivity returns. [body] may reference other locally-generated
/// (negative) ids, which the repository resolves against [PendingOp.idRefs]
/// at replay time once the real server ids are known.
class PendingOp {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> body;
  final String entityLabel;
  final String entityType;
  final int localEntityId;
  final List<String> idRefFields;
  final DateTime createdAt;

  PendingOp({
    required this.id,
    required this.method,
    required this.path,
    required this.body,
    required this.entityLabel,
    required this.entityType,
    required this.localEntityId,
    this.idRefFields = const [],
    required this.createdAt,
  });

  factory PendingOp.fromJson(Map<String, dynamic> json) => PendingOp(
        id: json['id'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        body: Map<String, dynamic>.from(json['body'] as Map),
        entityLabel: json['entityLabel'] as String,
        entityType: json['entityType'] as String,
        localEntityId: json['localEntityId'] as int,
        idRefFields: (json['idRefFields'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'body': body,
        'entityLabel': entityLabel,
        'entityType': entityType,
        'localEntityId': localEntityId,
        'idRefFields': idRefFields,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// SharedPreferences-backed offline cache for every entity list the app
/// shows, plus a durable queue of writes that failed to reach the backend.
/// This is what lets the field workflow keep working end-to-end even when
/// the officer's device has no signal.
class LocalStore {
  static const _idSeqKey = 'local.id_seq';
  static const _pendingOpsKey = 'local.pending_ops';

  String _listKey(String entity) => 'local.list.$entity';

  Future<List<Map<String, dynamic>>> getList(String entity) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_listKey(entity));
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> setList(String entity, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey(entity), jsonEncode(items));
  }

  Future<void> upsert(String entity, Map<String, dynamic> item) async {
    final items = await getList(entity);
    final idx = items.indexWhere((e) => e['id'] == item['id']);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.insert(0, item);
    }
    await setList(entity, items);
  }

  Future<void> replaceLocalId(String entity, int localId, Map<String, dynamic> serverItem) async {
    final items = await getList(entity);
    final idx = items.indexWhere((e) => e['id'] == localId);
    if (idx >= 0) {
      items[idx] = serverItem;
    } else {
      items.insert(0, serverItem);
    }
    await setList(entity, items);
  }

  Future<int> nextLocalId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_idSeqKey) ?? 0;
    final next = current - 1;
    await prefs.setInt(_idSeqKey, next);
    return next;
  }

  Future<List<PendingOp>> getPendingOps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingOpsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => PendingOp.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _setPendingOps(List<PendingOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOpsKey, jsonEncode(ops.map((e) => e.toJson()).toList()));
  }

  Future<void> addPendingOp(PendingOp op) async {
    final ops = await getPendingOps();
    ops.add(op);
    await _setPendingOps(ops);
  }

  Future<void> removePendingOp(String id) async {
    final ops = await getPendingOps();
    ops.removeWhere((e) => e.id == id);
    await _setPendingOps(ops);
  }

  Future<int> pendingCount() async => (await getPendingOps()).length;

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('local.'));
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
  }
}
