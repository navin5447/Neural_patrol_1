class Sample {
  final int id;
  final int caseId;
  final String sampleCode;
  final String sampleType;
  final String? location;
  final String? officerName;
  final String? date;
  final String? time;
  final String? notes;
  final double? gpsLat;
  final double? gpsLon;
  final String? deviceId;
  final String? operatorId;
  final bool sealedStatus;
  final bool preservedStatus;
  final DateTime createdAt;
  final bool pendingSync;

  const Sample({
    required this.id,
    required this.caseId,
    required this.sampleCode,
    required this.sampleType,
    this.location,
    this.officerName,
    this.date,
    this.time,
    this.notes,
    this.gpsLat,
    this.gpsLon,
    this.deviceId,
    this.operatorId,
    this.sealedStatus = false,
    this.preservedStatus = false,
    required this.createdAt,
    this.pendingSync = false,
  });

  factory Sample.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => Sample(
        id: json['id'] as int,
        caseId: json['case_id'] as int,
        sampleCode: json['sample_code'] as String,
        sampleType: json['sample_type'] as String,
        location: json['location'] as String?,
        officerName: json['officer_name'] as String?,
        date: json['date'] as String?,
        time: json['time'] as String?,
        notes: json['notes'] as String?,
        gpsLat: (json['gps_lat'] as num?)?.toDouble(),
        gpsLon: (json['gps_lon'] as num?)?.toDouble(),
        deviceId: json['device_id']?.toString(),
        operatorId: json['operator_id']?.toString(),
        sealedStatus: json['sealed_status'] as bool? ?? false,
        preservedStatus: json['preserved_status'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'sample_code': sampleCode,
        'sample_type': sampleType,
        'location': location,
        'officer_name': officerName,
        'date': date,
        'time': time,
        'notes': notes,
        'gps_lat': gpsLat,
        'gps_lon': gpsLon,
        'device_id': deviceId,
        'operator_id': operatorId,
        'sealed_status': sealedStatus,
        'preserved_status': preservedStatus,
        'created_at': createdAt.toIso8601String(),
      };
}
