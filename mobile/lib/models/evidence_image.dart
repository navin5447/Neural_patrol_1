class EvidenceImage {
  final int id;
  final int sampleId;
  final int testRunId;
  final String storageUri;
  final String imageHash;
  final String? imageMetadata;
  final int capturedByUserId;
  final DateTime capturedAt;
  final bool pendingSync;

  const EvidenceImage({
    required this.id,
    required this.sampleId,
    required this.testRunId,
    required this.storageUri,
    required this.imageHash,
    this.imageMetadata,
    required this.capturedByUserId,
    required this.capturedAt,
    this.pendingSync = false,
  });

  factory EvidenceImage.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => EvidenceImage(
        id: json['id'] as int,
        sampleId: json['sample_id'] as int,
        testRunId: json['test_run_id'] as int,
        storageUri: json['storage_uri'] as String,
        imageHash: json['image_hash'] as String,
        imageMetadata: json['image_metadata'] as String?,
        capturedByUserId: json['captured_by_user_id'] as int,
        capturedAt: DateTime.tryParse(json['captured_at']?.toString() ?? '') ?? DateTime.now(),
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sample_id': sampleId,
        'test_run_id': testRunId,
        'storage_uri': storageUri,
        'image_hash': imageHash,
        'image_metadata': imageMetadata,
        'captured_by_user_id': capturedByUserId,
        'captured_at': capturedAt.toIso8601String(),
      };
}
