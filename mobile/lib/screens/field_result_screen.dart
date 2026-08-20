import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/case_file.dart';
import '../models/sample.dart';
import '../models/test_run.dart';
import '../services/strip_analyzer.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/presumptive_banner.dart';
import '../widgets/section_card.dart';
import '../widgets/workflow_stepper.dart';
import 'evidence_record_screen.dart';
import 'fsl_handoff_screen.dart';

/// Species entries that warrant immediate escalation get their own color so
/// they never read as "just another routine result" at a glance.
bool _isEscalation(String indication) => indication.toUpperCase().contains('HUMAN');

class FieldResultScreen extends StatefulWidget {
  final Sample sample;
  final CaseFile caseFile;
  final TestRun testRun;
  final StripAnalysisResult analysis;
  final Uint8List imageBytes;

  const FieldResultScreen({
    super.key,
    required this.sample,
    required this.caseFile,
    required this.testRun,
    required this.analysis,
    required this.imageBytes,
  });

  @override
  State<FieldResultScreen> createState() => _FieldResultScreenState();
}

class _FieldResultScreenState extends State<FieldResultScreen> {
  final _memoController = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _addMemo() async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add field memo'),
        content: TextField(controller: _memoController, maxLines: 4, decoration: const InputDecoration(labelText: 'Note')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(_memoController.text.trim()), child: const Text('ADD')),
        ],
      ),
    );
    if (note == null || note.isEmpty || !mounted) return;
    final userId = context.read<AppSession>().currentUser?.id ?? 0;
    await context.read<Repository>().addCustodyEvent(
          sampleId: widget.sample.id,
          eventType: 'field_note',
          whoUserId: userId,
          whatAction: 'Field memo added',
          notes: note,
        );
    if (!mounted) return;
    _memoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memo added to custody record.')));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = context.read<Repository>();
    final userId = context.read<AppSession>().currentUser?.id ?? 0;
    try {
      await repo.createFieldResult(
        testRunId: widget.testRun.id,
        sampleId: widget.sample.id,
        targetIndication: widget.analysis.targetIndication,
        controlValid: widget.analysis.controlLineValid,
        qualityScore: widget.analysis.qualityScore,
        recordedByUserId: userId,
        imageRef: widget.analysis.imageHash,
      );
      await repo.createEvidenceImage(
        sampleId: widget.sample.id,
        testRunId: widget.testRun.id,
        storageUri: 'data:image/jpeg;base64,${base64Encode(widget.imageBytes)}',
        imageHash: widget.analysis.imageHash,
        capturedByUserId: userId,
      );
      await repo.addCustodyEvent(
        sampleId: widget.sample.id,
        eventType: 'field_result_recorded',
        whoUserId: userId,
        whatAction: 'Presumptive field result recorded: ${widget.analysis.targetIndication}',
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save field result: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final escalation = _isEscalation(a.targetIndication);
    final resultColor = escalation ? AppColors.escalation : AppColors.accent;
    return Scaffold(
      appBar: AppBar(title: Text('Field Result · ${widget.sample.sampleCode}')),
      body: Column(
        children: [
          const WorkflowStepper(currentIndex: 3),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const PresumptiveBanner(),
                const SizedBox(height: AppSpacing.md),
                if (escalation)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.escalation.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.escalation.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.priority_high, color: AppColors.escalation),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ESCALATE IMMEDIATELY — notify supervisor before proceeding.',
                            style: TextStyle(color: AppColors.escalation, fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: resultColor.withValues(alpha: 0.4)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.memory(widget.imageBytes, height: 180, fit: BoxFit.cover, width: double.infinity),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TARGET INDICATION', style: AppText.eyebrow),
                            const SizedBox(height: 6),
                            Text(a.targetIndication, style: TextStyle(color: resultColor, fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(child: _stat('CONTROL', a.controlLineValid ? 'VALID' : 'INVALID', a.controlLineValid ? AppColors.success : AppColors.danger)),
                                Expanded(child: _stat('QUALITY', '${(a.qualityScore * 100).toStringAsFixed(0)}%', AppColors.textPrimary)),
                                Expanded(child: _stat('STATUS', 'PRESUMPTIVE', AppColors.warning)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard(
                  title: 'Case & sample',
                  titleIcon: Icons.folder_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Case', widget.caseFile.caseNumber),
                      _kv('Sample', widget.sample.sampleCode),
                      _kv('Test run', '#${widget.testRun.id}'),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (!_saved) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: _saving ? const Text('SAVING…') : const Text('SAVE FIELD RESULT'),
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('ADD MEMO'),
                    onPressed: _addMemo,
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('SEND FOR FSL CONFIRMATION'),
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => FslHandoffScreen(sample: widget.sample, caseFile: widget.caseFile),
                    )),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('VIEW EVIDENCE RECORD'),
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => EvidenceRecordScreen(sample: widget.sample, caseFile: widget.caseFile),
                    )),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(key, style: AppText.caption)),
          Expanded(child: Text(value, style: AppText.bodyStrong)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
      ],
    );
  }
}
