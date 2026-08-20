import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/case_file.dart';
import '../models/device_info.dart';
import '../models/sample.dart';
import '../models/test_run.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/workflow_stepper.dart';
import 'result_capture_screen.dart';

enum _RunState { connecting, ready, preheat, running, validation, complete }

extension on _RunState {
  String get label => switch (this) {
        _RunState.connecting => 'CONNECTING',
        _RunState.ready => 'READY',
        _RunState.preheat => 'PREHEAT',
        _RunState.running => 'RUNNING — AMPLIFICATION',
        _RunState.validation => 'VALIDATION',
        _RunState.complete => 'COMPLETE',
      };

  Color get color => switch (this) {
        _RunState.connecting => AppColors.textMuted,
        _RunState.ready => AppColors.info,
        _RunState.preheat => AppColors.warning,
        _RunState.running => AppColors.accent,
        _RunState.validation => AppColors.teal,
        _RunState.complete => AppColors.success,
      };
}

class DeviceConnectionScreen extends StatefulWidget {
  final Sample sample;
  final CaseFile caseFile;

  const DeviceConnectionScreen({super.key, required this.sample, required this.caseFile});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  DeviceInfo? _device;
  TestRun? _testRun;
  _RunState _state = _RunState.connecting;
  double _progress = 0;
  double _temperature = 24.0;
  Timer? _timer;
  String? _error;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    final repo = context.read<Repository>();
    try {
      final device = await repo.connectDevice(
        deviceName: 'NP FIELD UNIT 01',
        serialNumber: 'NP-FU-000${widget.sample.caseId}',
        hwVersion: 'r1',
      );
      final testRun = await repo.createTestRun(sampleId: widget.sample.id, deviceId: device.id);
      if (!mounted) return;
      setState(() {
        _device = device;
        _testRun = testRun;
        _state = _RunState.ready;
      });
      _startCycle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not connect to field device: $e');
    }
  }

  void _startCycle() {
    _timer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      setState(() {
        _progress = (_progress + 2.2).clamp(0, 100).toDouble();
        if (_progress < 8) {
          _state = _RunState.ready;
          _temperature = 24 + _rand.nextDouble();
        } else if (_progress < 32) {
          _state = _RunState.preheat;
          _temperature = 24 + ((_progress - 8) / 24) * 40 + _rand.nextDouble() * 0.6;
        } else if (_progress < 88) {
          _state = _RunState.running;
          _temperature = 63.5 + _rand.nextDouble() * 1.2;
        } else if (_progress < 99) {
          _state = _RunState.validation;
          _temperature = 62.0;
        } else {
          _state = _RunState.complete;
          _temperature = 45.0;
        }
      });

      if (_testRun != null && (_progress.toInt() % 10 == 0)) {
        context.read<Repository>().sendTelemetry(_testRun!.id, {
          'state': _state.name,
          'temperature': double.parse(_temperature.toStringAsFixed(2)),
          'progress': _progress.toInt(),
        });
      }

      if (_state == _RunState.complete) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Device · ${widget.sample.sampleCode}')),
      body: Column(
        children: [
          const WorkflowStepper(currentIndex: 1),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                SectionCard(
                  title: 'Field unit',
                  titleIcon: Icons.bluetooth,
                  child: Row(
                    children: [
                      Icon(_device != null ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                          color: _device != null ? AppColors.success : AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_device?.deviceName ?? 'NP FIELD UNIT 01', style: AppText.bodyStrong),
                            if (_device != null)
                              Text('Serial ${_device!.serialNumber} · ${_device!.hwVersion ?? ''}', style: AppText.caption),
                          ],
                        ),
                      ),
                      Text(_device != null ? 'CONNECTED' : 'CONNECTING…',
                          style: TextStyle(color: _device != null ? AppColors.success : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_error != null)
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(onPressed: _connect, child: const Text('RETRY CONNECTION')),
                      ],
                    ),
                  )
                else
                  SectionCard(
                    title: 'Process state',
                    titleIcon: Icons.science,
                    accent: _state.color,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 190,
                          width: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 190,
                                width: 190,
                                child: CircularProgressIndicator(
                                  value: _progress / 100,
                                  strokeWidth: 10,
                                  backgroundColor: AppColors.surfaceRaised,
                                  valueColor: AlwaysStoppedAnimation(_state.color),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.device_thermostat, color: _state.color, size: 20),
                                  const SizedBox(height: 4),
                                  Text('${_temperature.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text('${_progress.toInt()}%', style: AppText.caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _state.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(_state.label, style: TextStyle(color: _state.color, fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 12.5)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Sample ${widget.sample.sampleCode}', style: AppText.mono),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('CAPTURE RESULT STRIP'),
                  onPressed: _state == _RunState.complete
                      ? () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => ResultCaptureScreen(sample: widget.sample, caseFile: widget.caseFile, testRun: _testRun!),
                          ))
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
