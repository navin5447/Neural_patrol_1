import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/repository.dart';
import '../models/case_file.dart';
import '../models/sample.dart';
import '../services/location_service.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/workflow_stepper.dart';
import 'device_connection_screen.dart';

const List<String> kSampleTypes = [
  'Suspected Meat Tissue',
  'Bone Fragment',
  'Blood Stain',
  'Hide / Skin',
  'Hair / Fur',
  'Horn / Claw / Nail',
  'Other Biological Material',
];

class CreateSampleScreen extends StatefulWidget {
  final CaseFile caseFile;

  const CreateSampleScreen({super.key, required this.caseFile});

  @override
  State<CreateSampleScreen> createState() => _CreateSampleScreenState();
}

class _CreateSampleScreenState extends State<CreateSampleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _officerNameController = TextEditingController();
  String _sampleType = kSampleTypes.first;
  double? _gpsLat;
  double? _gpsLon;
  bool _locating = false;
  bool _submitting = false;
  String? _error;
  Sample? _createdSample;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppSession>().currentUser;
    _locationController.text = widget.caseFile.location ?? '';
    _officerNameController.text = user?.name ?? 'Field Officer';
    _captureLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _officerNameController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _locating = true);
    final position = await LocationService().capture();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (position != null) {
        _gpsLat = position.latitude;
        _gpsLon = position.longitude;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final now = DateTime.now();
    final repo = context.read<Repository>();
    try {
      final sample = await repo.createSample(
        caseId: widget.caseFile.id,
        sampleType: _sampleType,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        officerName: _officerNameController.text.trim().isEmpty ? 'Field Officer' : _officerNameController.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(now),
        time: DateFormat('HH:mm').format(now),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        gpsLat: _gpsLat,
        gpsLon: _gpsLon,
      );
      if (!mounted) return;
      setState(() {
        _createdSample = sample;
        _submitting = false;
      });
      await repo.addCustodyEvent(
        sampleId: sample.id,
        eventType: 'registered',
        whoUserId: context.read<AppSession>().currentUser?.id ?? 0,
        whatAction: 'Sample registered in field ($_sampleType)',
        whereLocation: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not register sample: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdSample != null) {
      return _SampleCreatedView(sample: _createdSample!, caseFile: widget.caseFile);
    }
    return Scaffold(
      appBar: AppBar(title: Text('New Sample · ${widget.caseFile.caseNumber}')),
      body: Column(
        children: [
          const WorkflowStepper(currentIndex: 0),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  SectionCard(
                    title: 'Sample details',
                    titleIcon: Icons.science_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _sampleType,
                          decoration: const InputDecoration(labelText: 'Sample type', prefixIcon: Icon(Icons.biotech_outlined)),
                          items: kSampleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _sampleType = v ?? _sampleType),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required for the evidence record' : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(_gpsLat != null ? Icons.gps_fixed : Icons.gps_not_fixed, size: 14, color: _gpsLat != null ? AppColors.success : AppColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _locating
                                    ? 'Acquiring GPS fix…'
                                    : _gpsLat != null
                                        ? 'GPS: ${_gpsLat!.toStringAsFixed(5)}, ${_gpsLon!.toStringAsFixed(5)}'
                                        : 'GPS unavailable — proceeding without coordinates',
                                style: AppText.caption,
                              ),
                            ),
                            TextButton(onPressed: _locating ? null : _captureLocation, child: const Text('RETRY')),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _officerNameController,
                          decoration: const InputDecoration(labelText: 'Officer name', prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Officer name is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes)),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentOn))
                        : const Text('REGISTER SAMPLE'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleCreatedView extends StatelessWidget {
  final Sample sample;
  final CaseFile caseFile;

  const _SampleCreatedView({required this.sample, required this.caseFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sample Registered'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withValues(alpha: 0.14)),
                  child: const Icon(Icons.check, color: AppColors.success, size: 32),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(sample.sampleCode, style: AppText.mono.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(sample.sampleType, style: AppText.bodyMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: QrImageView(data: sample.sampleCode, size: 200, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Chain of custody',
            titleIcon: Icons.link,
            child: const Text(
              'A "registered" custody event has been recorded for this sample. Seal and preserve the physical evidence before connecting the field device.',
              style: AppText.bodyMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('CONNECT FIELD DEVICE'),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => DeviceConnectionScreen(sample: sample, caseFile: caseFile)),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('BACK TO DASHBOARD'),
          ),
        ],
      ),
    );
  }
}
