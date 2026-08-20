class FieldResult {
  final int id;
  final int testRunId;
  final int sampleId;
  final String status;
  final String? targetIndication;
  final bool controlValid;
  final double qualityScore;
  final String? imageRef;
  final String? rawResultPayload;
  final int recordedByUserId;
  final DateTime recordedAt;
  final String? previousRecordHash;
  final String? currentRecordHash;
  final bool pendingSync;

  const FieldResult({
    required this.id,
    required this.testRunId,
    required this.sampleId,
    this.status = 'presumptive',
    this.targetIndication,
    this.controlValid = false,
    this.qualityScore = 0.0,
    this.imageRef,
    this.rawResultPayload,
    required this.recordedByUserId,
    required this.recordedAt,
    this.previousRecordHash,
    this.currentRecordHash,
    this.pendingSync = false,
  });

  factory FieldResult.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => FieldResult(
        id: json['id'] as int,
        testRunId: json['test_run_id'] as int,
        sampleId: json['sample_id'] as int,
        status: json['status'] as String? ?? 'presumptive',
        targetIndication: json['target_indication'] as String?,
        controlValid: json['control_valid'] as bool? ?? false,
        qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
        imageRef: json['image_ref'] as String?,
        rawResultPayload: json['raw_result_payload'] as String?,
        recordedByUserId: json['recorded_by_user_id'] as int,
        recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? '') ?? DateTime.now(),
        previousRecordHash: json['previous_record_hash'] as String?,
        currentRecordHash: json['current_record_hash'] as String?,
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'test_run_id': testRunId,
        'sample_id': sampleId,
        'status': status,
        'target_indication': targetIndication,
        'control_valid': controlValid,
        'quality_score': qualityScore,
        'image_ref': imageRef,
        'raw_result_payload': rawResultPayload,
        'recorded_by_user_id': recordedByUserId,
        'recorded_at': recordedAt.toIso8601String(),
        'previous_record_hash': previousRecordHash,
        'current_record_hash': currentRecordHash,
      };
}
