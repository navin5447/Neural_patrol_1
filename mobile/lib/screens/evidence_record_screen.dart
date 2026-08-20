import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/repository.dart';
import '../models/audit_log_entry.dart';
import '../models/case_file.dart';
import '../models/field_result.dart';
import '../models/sample.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import 'custody_timeline_screen.dart';
import 'device_connection_screen.dart';
import 'fsl_handoff_screen.dart';

class EvidenceRecordScreen extends StatefulWidget {
  final Sample sample;
  final CaseFile caseFile;

  const EvidenceRecordScreen({super.key, required this.sample, required this.caseFile});

  @override
  State<EvidenceRecordScreen> createState() => _EvidenceRecordScreenState();
}

class _EvidenceRecordScreenState extends State<EvidenceRecordScreen> {
  late Future<List<FieldResult>> _resultsFuture;
  late Future<List<AuditLogEntry>> _auditFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<Repository>();
    _resultsFuture = repo.listFieldResults(widget.sample.id);
    _auditFuture = repo.getAudit(widget.sample.id);
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sample;
    final c = widget.caseFile;
    return Scaffold(
      appBar: AppBar(title: Text('Evidence · ${s.sampleCode}')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await Future.wait([_resultsFuture, _auditFuture]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _copy('Sample code', s.sampleCode),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: QrImageView(data: s.sampleCode, size: 150, backgroundColor: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: () => _copy('Sample code', s.sampleCode),
                icon: const Icon(Icons.copy, size: 14),
                label: Text(s.sampleCode, style: AppText.mono),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Digital evidence record',
              titleIcon: Icons.badge_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _kv('Case ID', c.caseNumber),
                  _kv('Sample ID', s.sampleCode),
                  _kv('Sample type', s.sampleType),
                  _kv('Officer', s.officerName ?? '—'),
                  _kv('Registered', DateFormat('MMM d, yyyy HH:mm').format(s.createdAt)),
                  _kv('Location', s.location ?? '—'),
                  if (s.gpsLat != null) _kv('GPS', '${s.gpsLat!.toStringAsFixed(5)}, ${s.gpsLon!.toStringAsFixed(5)}'),
                  if (s.pendingSync) const Padding(padding: EdgeInsets.only(top: 8), child: StatusPill(label: 'AWAITING SYNC TO SERVER', color: AppColors.warning)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Field result status',
              titleIcon: Icons.fact_check_outlined,
              child: FutureBuilder<List<FieldResult>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Could not load field results.', style: TextStyle(color: AppColors.danger, fontSize: 12.5));
                  }
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return const Text('No field result recorded yet for this sample.', style: AppText.bodyMuted);
                  }
                  final latest = results.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _kv('Status', 'PRESUMPTIVE'),
                      _kv('Target indication', latest.targetIndication ?? '—'),
                      _kv('Control valid', latest.controlValid ? 'Yes' : 'No'),
                      _kv('Quality score', '${(latest.qualityScore * 100).toStringAsFixed(0)}%'),
                      _kv('Recorded', DateFormat('MMM d, yyyy HH:mm').format(latest.recordedAt)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Audit trail',
              titleIcon: Icons.verified_outlined,
              child: FutureBuilder<List<AuditLogEntry>>(
                future: _auditFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Could not load the audit trail.', style: TextStyle(color: AppColors.danger, fontSize: 12.5));
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return const Text('No synced audit entries yet.', style: AppText.bodyMuted);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: logs
                        .map((l) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${l.action.replaceAll('_', ' ')} — ${DateFormat('MMM d HH:mm').format(l.timestamp)}',
                                        style: AppText.bodyMuted),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              icon: const Icon(Icons.timeline),
              label: const Text('CHAIN OF CUSTODY TIMELINE'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustodyTimelineScreen(sample: s, caseFile: c))),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('CONTINUE FIELD TEST WORKFLOW'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeviceConnectionScreen(sample: s, caseFile: c))),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('FSL HANDOFF'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FslHandoffScreen(sample: s, caseFile: c))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppText.bodyMuted),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: AppText.bodyStrong)),
        ],
      ),
    );
  }
}
