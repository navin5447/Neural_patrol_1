class TestRun {
  final int id;
  final int sampleId;
  final int deviceId;
  final String? assayProfileId;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool pendingSync;

  const TestRun({
    required this.id,
    required this.sampleId,
    required this.deviceId,
    this.assayProfileId,
    this.status = 'started',
    required this.startedAt,
    this.completedAt,
    this.pendingSync = false,
  });

  factory TestRun.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => TestRun(
        id: json['id'] as int,
        sampleId: json['sample_id'] as int,
        deviceId: json['device_id'] as int,
        assayProfileId: json['assay_profile_id'] as String?,
        status: json['status'] as String? ?? 'started',
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ?? DateTime.now(),
        completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sample_id': sampleId,
        'device_id': deviceId,
        'assay_profile_id': assayProfileId,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };
}
