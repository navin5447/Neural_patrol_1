import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Presumptive species panel used purely for this demo prototype. A real
/// deployment plugs in a validated multiplex lateral-flow chemistry and a
/// trained strip-reader model here — this list exists so the UI has
/// something concrete to display end to end.
const List<String> kSpeciesPanel = [
  'Not Detected',
  'Bovine (Cattle) - Presumptive',
  'Bubaline (Buffalo) - Presumptive',
  'Caprine (Goat) - Presumptive',
  'Ovine (Sheep) - Presumptive',
  'Suid (Pig) - Presumptive',
  'Human - Presumptive (Escalate Immediately)',
];

class StripAnalysisResult {
  final bool controlLineValid;
  final String targetIndication;
  final double targetIntensity;
  final double qualityScore;
  final String imageHash;

  const StripAnalysisResult({
    required this.controlLineValid,
    required this.targetIndication,
    required this.targetIntensity,
    required this.qualityScore,
    required this.imageHash,
  });

  bool get isInvalidTest => !controlLineValid;
}

/// Deterministic, offline, on-device stand-in for the OpenCV strip-reader
/// pipeline described in the architecture doc. It hashes the captured image
/// so the same photo always reproduces the same presumptive result during a
/// demo, without shipping a real trained model or a native OpenCV binding.
class StripAnalyzer {
  StripAnalysisResult analyze(Uint8List imageBytes) {
    final digest = sha256.convert(imageBytes);
    final bytes = digest.bytes;

    final controlRoll = bytes[0] % 100;
    final controlLineValid = controlRoll < 90;

    final intensityRoll = bytes[1] % 100;
    final targetIntensity = intensityRoll / 100.0;

    final qualityRoll = 55 + (bytes[2] % 45);
    final qualityScore = qualityRoll / 100.0;

    String targetIndication;
    if (!controlLineValid) {
      targetIndication = 'INVALID TEST - CONTROL LINE NOT DETECTED';
    } else if (targetIntensity < 0.15) {
      targetIndication = kSpeciesPanel[0];
    } else {
      final speciesIndex = 1 + (bytes[3] % (kSpeciesPanel.length - 1));
      targetIndication = kSpeciesPanel[speciesIndex];
    }

    return StripAnalysisResult(
      controlLineValid: controlLineValid,
      targetIndication: targetIndication,
      targetIntensity: targetIntensity,
      qualityScore: qualityScore,
      imageHash: digest.toString(),
    );
  }
}
