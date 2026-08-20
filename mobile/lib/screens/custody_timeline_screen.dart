import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/case_file.dart';
import '../models/custody_event.dart';
import '../models/sample.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/status_pill.dart';

const Map<String, IconData> _eventIcons = {
  'registered': Icons.assignment_turned_in_outlined,
  'sealed': Icons.lock_outline,
  'field_test_started': Icons.science_outlined,
  'field_result_recorded': Icons.fact_check_outlined,
  'field_note': Icons.sticky_note_2_outlined,
  'confirmatory_sample_dispatched': Icons.local_shipping_outlined,
  'manual_note': Icons.edit_note_outlined,
};

class CustodyTimelineScreen extends StatefulWidget {
  final Sample sample;
  final CaseFile caseFile;

  const CustodyTimelineScreen({super.key, required this.sample, required this.caseFile});

  @override
  State<CustodyTimelineScreen> createState() => _CustodyTimelineScreenState();
}

class _CustodyTimelineScreenState extends State<CustodyTimelineScreen> {
  late Future<List<CustodyEvent>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<Repository>().listCustodyEvents(widget.sample.id);
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add custody note'),
        content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(labelText: 'Note')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('ADD')),
        ],
      ),
    );
    if (note == null || note.isEmpty || !mounted) return;
    final userId = context.read<AppSession>().currentUser?.id ?? 0;
    await context.read<Repository>().addCustodyEvent(
          sampleId: widget.sample.id,
          eventType: 'manual_note',
          whoUserId: userId,
          whatAction: 'Supervisor / officer note added',
          notes: note,
        );
    if (!mounted) return;
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custody · ${widget.sample.sampleCode}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Append-only, hash-chained evidentiary log', style: AppText.caption),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('ADD NOTE'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _future;
        },
        child: FutureBuilder<List<CustodyEvent>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [ErrorState(message: 'Could not load the custody log.', onRetry: () => setState(_load))]);
            }
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return ListView(children: const [
                EmptyState(icon: Icons.history_toggle_off, title: 'No custody events yet', message: 'Events append automatically as the sample moves through the workflow.'),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 90),
              itemCount: events.length,
              itemBuilder: (context, i) {
                final e = events[i];
                final isLast = i == events.length - 1;
                return _TimelineTile(event: e, isLast: isLast);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final CustodyEvent event;
  final bool isLast;

  const _TimelineTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final icon = _eventIcons[event.eventType] ?? Icons.circle_outlined;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.surfaceRaised, shape: BoxShape.circle, border: Border.all(color: AppColors.accent.withValues(alpha: 0.5))),
                child: Icon(icon, size: 16, color: AppColors.accent),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(event.eventType.replaceAll('_', ' ').toUpperCase(), style: AppText.eyebrow)),
                        if (event.pendingSync) const StatusPill(label: 'PENDING', color: AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(event.whatAction, style: AppText.body),
                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(event.notes!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM d, HH:mm:ss').format(event.whenTs), style: AppText.caption),
                        if (event.whereLocation != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Flexible(child: Text(event.whereLocation!, style: AppText.caption, overflow: TextOverflow.ellipsis)),
                        ],
                      ],
                    ),
                    if (event.currentHash != null) ...[
                      const SizedBox(height: 6),
                      Text('hash ${_short(event.currentHash!)}', style: AppText.mono),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _short(String hash) => hash.length > 16 ? '${hash.substring(0, 8)}…${hash.substring(hash.length - 6)}' : hash;
}
