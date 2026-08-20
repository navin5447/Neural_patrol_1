class AuditLogEntry {
  final int id;
  final int sampleId;
  final String entityType;
  final int entityId;
  final String action;
  final int actorUserId;
  final DateTime timestamp;
  final String? summary;
  final String? previousHash;
  final String? currentHash;

  const AuditLogEntry({
    required this.id,
    required this.sampleId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.actorUserId,
    required this.timestamp,
    this.summary,
    this.previousHash,
    this.currentHash,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as int,
        sampleId: json['sample_id'] as int,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as int,
        action: json['action'] as String,
        actorUserId: json['actor_user_id'] as int,
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
        summary: json['summary'] as String?,
        previousHash: json['previous_hash'] as String?,
        currentHash: json['current_hash'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sample_id': sampleId,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'actor_user_id': actorUserId,
        'timestamp': timestamp.toIso8601String(),
        'summary': summary,
        'previous_hash': previousHash,
        'current_hash': currentHash,
      };
}
