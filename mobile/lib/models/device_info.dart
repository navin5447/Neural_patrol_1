class DeviceInfo {
  final int id;
  final String deviceName;
  final String serialNumber;
  final String? hwVersion;
  final String status;
  final DateTime lastSeenAt;
  final bool pendingSync;

  const DeviceInfo({
    required this.id,
    required this.deviceName,
    required this.serialNumber,
    this.hwVersion,
    this.status = 'connected',
    required this.lastSeenAt,
    this.pendingSync = false,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => DeviceInfo(
        id: json['id'] as int,
        deviceName: json['device_name'] as String,
        serialNumber: json['serial_number'] as String,
        hwVersion: json['hw_version'] as String?,
        status: json['status'] as String? ?? 'connected',
        lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? '') ?? DateTime.now(),
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_name': deviceName,
        'serial_number': serialNumber,
        'hw_version': hwVersion,
        'status': status,
        'last_seen_at': lastSeenAt.toIso8601String(),
      };
}
