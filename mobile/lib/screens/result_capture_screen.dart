import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/case_file.dart';
import '../models/sample.dart';
import '../models/test_run.dart';
import '../services/strip_analyzer.dart';
import '../theme/app_theme.dart';
import '../widgets/presumptive_banner.dart';
import '../widgets/section_card.dart';
import '../widgets/workflow_stepper.dart';
import 'field_result_screen.dart';

class ResultCaptureScreen extends StatefulWidget {
  final Sample sample;
  final CaseFile caseFile;
  final TestRun testRun;

  const ResultCaptureScreen({super.key, required this.sample, required this.caseFile, required this.testRun});

  @override
  State<ResultCaptureScreen> createState() => _ResultCaptureScreenState();
}

class _ResultCaptureScreenState extends State<ResultCaptureScreen> {
  Uint8List? _imageBytes;
  StripAnalysisResult? _result;
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _imageBytes = null;
    });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (file == null) {
        setState(() => _busy = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final analysis = StripAnalyzer().analyze(bytes);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _result = analysis;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not capture image: $e';
      });
    }
  }

  void _retry() {
    setState(() {
      _imageBytes = null;
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Result Capture · ${widget.sample.sampleCode}')),
      body: Column(
        children: [
          const WorkflowStepper(currentIndex: 2),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                SectionCard(
                  title: 'Detection strip readout',
                  titleIcon: Icons.qr_code_scanner,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_imageBytes == null) ...[
                        Container(
                          height: 200,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _busy
                              ? const CircularProgressIndicator()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.qr_code_scanner, color: AppColors.textMuted, size: 44),
                                    SizedBox(height: 8),
                                    Text('Photograph the detection strip', style: AppText.bodyMuted),
                                  ],
                                ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('CAMERA'),
                                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('GALLERY'),
                                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.memory(_imageBytes!, height: 220, fit: BoxFit.cover, width: double.infinity),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _AnalysisSummary(result: _result!),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  PresumptiveBanner(invalid: _result!.isInvalidTest),
                  const SizedBox(height: AppSpacing.xl),
                  if (_result!.isInvalidTest)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('DISCARD & RECAPTURE'),
                      onPressed: _retry,
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('CONTINUE TO FIELD RESULT'),
                          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => FieldResultScreen(
                              sample: widget.sample,
                              caseFile: widget.caseFile,
                              testRun: widget.testRun,
                              analysis: _result!,
                              imageBytes: _imageBytes!,
                            ),
                          )),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('RECAPTURE'),
                          onPressed: _retry,
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSummary extends StatelessWidget {
  final StripAnalysisResult result;

  const _AnalysisSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(Icons.linear_scale, 'Control line', result.controlLineValid ? 'DETECTED' : 'NOT DETECTED', result.controlLineValid ? AppColors.success : AppColors.danger),
          const Divider(height: 18),
          _row(Icons.pest_control_outlined, 'Target indication', result.targetIndication, AppColors.accent),
          const Divider(height: 18),
          _row(Icons.speed, 'Quality score', '${(result.qualityScore * 100).toStringAsFixed(0)}%', AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppText.bodyMuted)),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
