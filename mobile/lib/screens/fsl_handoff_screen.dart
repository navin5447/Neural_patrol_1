import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/repository.dart';
import '../models/case_file.dart';
import '../models/fsl_handoff.dart';
import '../models/sample.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/section_card.dart';
import '../widgets/workflow_stepper.dart';

const List<String> kPhysicalStatuses = [
  'sealed_for_confirmation',
  'dispatched_in_transit',
  'received_by_fsl',
];

class FslHandoffScreen extends StatefulWidget {
  final Sample sample;
  final CaseFile caseFile;

  const FslHandoffScreen({super.key, required this.sample, required this.caseFile});

  @override
  State<FslHandoffScreen> createState() => _FslHandoffScreenState();
}

class _FslHandoffScreenState extends State<FslHandoffScreen> {
  late final TextEditingController _destinationController;
  String _physicalStatus = kPhysicalStatuses.first;
  bool _submitting = false;
  String? _error;
  FslHandoff? _handoff;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(text: 'AUTHORIZED FSL — ${widget.sample.location ?? 'Regional Lab'}');
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Dispatch to FSL?',
      message: 'This marks the sample as handed off for confirmatory lab testing. The field result stays a separate presumptive record.',
      confirmLabel: 'DISPATCH',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = context.read<Repository>();
    final userId = context.read<AppSession>().currentUser?.id ?? 0;
    try {
      final handoff = await repo.createFslHandoff(
        sampleId: widget.sample.id,
        qrCodeValue: '${widget.sample.sampleCode}::FSL-HANDOFF',
        dispatchedByUserId: userId,
        destinationLab: _destinationController.text.trim().isEmpty ? 'AUTHORIZED FSL' : _destinationController.text.trim(),
        physicalSampleStatus: _physicalStatus,
      );
      await repo.addCustodyEvent(
        sampleId: widget.sample.id,
        eventType: 'confirmatory_sample_dispatched',
        whoUserId: userId,
        whatAction: 'Confirmatory sample dispatched to ${handoff.destinationLab}',
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _handoff = handoff;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not record FSL handoff: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_handoff != null) {
      return _HandoffConfirmedView(handoff: _handoff!, sample: widget.sample);
    }
    return Scaffold(
      appBar: AppBar(title: Text('FSL Handoff · ${widget.sample.sampleCode}')),
      body: Column(
        children: [
          const WorkflowStepper(currentIndex: 5),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                SectionCard(
                  title: 'Confirmatory sample request',
                  titleIcon: Icons.local_shipping_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _destinationController,
                        decoration: const InputDecoration(labelText: 'Destination authorized FSL', prefixIcon: Icon(Icons.local_hospital_outlined)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _physicalStatus,
                        decoration: const InputDecoration(labelText: 'Physical sample status', prefixIcon: Icon(Icons.inventory_2_outlined)),
                        items: kPhysicalStatuses
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase())))
                            .toList(),
                        onChanged: (v) => setState(() => _physicalStatus = v ?? _physicalStatus),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionCard(
                  child: const Text(
                    'The field result stays a separate presumptive record. Only the authorized FSL analyst can enter the confirmatory result once the physical sample is received.',
                    style: AppText.bodyMuted,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: _submitting ? const Text('DISPATCHING…') : const Text('DISPATCH TO FSL'),
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HandoffConfirmedView extends StatelessWidget {
  final FslHandoff handoff;
  final Sample sample;

  const _HandoffConfirmedView({required this.handoff, required this.sample});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handoff Recorded'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withValues(alpha: 0.14)),
              child: const Icon(Icons.local_shipping, color: AppColors.success, size: 30),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(child: Text(sample.sampleCode, style: AppText.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          Center(child: Text('Dispatched to ${handoff.destinationLab}', style: AppText.bodyMuted, textAlign: TextAlign.center)),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: QrImageView(data: handoff.qrCodeValue, size: 180, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Status',
            titleIcon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Field status: ${handoff.fieldStatus.replaceAll('_', ' ')}', style: AppText.body),
                Text('Physical status: ${handoff.physicalSampleStatus.replaceAll('_', ' ')}', style: AppText.body),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('BACK TO DASHBOARD'),
          ),
        ],
      ),
    );
  }
}
