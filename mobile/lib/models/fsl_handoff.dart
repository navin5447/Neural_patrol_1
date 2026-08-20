class FslHandoff {
  final int id;
  final int sampleId;
  final String destinationLab;
  final String fieldStatus;
  final String physicalSampleStatus;
  final String qrCodeValue;
  final int dispatchedByUserId;
  final DateTime dispatchedAt;
  final DateTime? receivingAcknowledgedAt;
  final bool pendingSync;

  const FslHandoff({
    required this.id,
    required this.sampleId,
    required this.destinationLab,
    this.fieldStatus = 'presumptive_result_recorded',
    this.physicalSampleStatus = 'sealed_for_confirmation',
    required this.qrCodeValue,
    required this.dispatchedByUserId,
    required this.dispatchedAt,
    this.receivingAcknowledgedAt,
    this.pendingSync = false,
  });

  factory FslHandoff.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => FslHandoff(
        id: json['id'] as int,
        sampleId: json['sample_id'] as int,
        destinationLab: json['destination_lab'] as String,
        fieldStatus: json['field_status'] as String? ?? 'presumptive_result_recorded',
        physicalSampleStatus: json['physical_sample_status'] as String? ?? 'sealed_for_confirmation',
        qrCodeValue: json['qr_code_value'] as String,
        dispatchedByUserId: json['dispatched_by_user_id'] as int,
        dispatchedAt: DateTime.tryParse(json['dispatched_at']?.toString() ?? '') ?? DateTime.now(),
        receivingAcknowledgedAt: json['receiving_acknowledged_at'] != null
            ? DateTime.tryParse(json['receiving_acknowledged_at'].toString())
            : null,
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sample_id': sampleId,
        'destination_lab': destinationLab,
        'field_status': fieldStatus,
        'physical_sample_status': physicalSampleStatus,
        'qr_code_value': qrCodeValue,
        'dispatched_by_user_id': dispatchedByUserId,
        'dispatched_at': dispatchedAt.toIso8601String(),
        'receiving_acknowledged_at': receivingAcknowledgedAt?.toIso8601String(),
      };
}
