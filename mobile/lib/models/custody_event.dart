class CustodyEvent {
  final int id;
  final int sampleId;
  final String eventType;
  final int whoUserId;
  final String whatAction;
  final DateTime whenTs;
  final String? whereLocation;
  final String? notes;
  final String? previousHash;
  final String? currentHash;
  final bool isImmutable;
  final bool pendingSync;

  const CustodyEvent({
    required this.id,
    required this.sampleId,
    required this.eventType,
    required this.whoUserId,
    required this.whatAction,
    required this.whenTs,
    this.whereLocation,
    this.notes,
    this.previousHash,
    this.currentHash,
    this.isImmutable = true,
    this.pendingSync = false,
  });

  factory CustodyEvent.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => CustodyEvent(
        id: json['id'] as int,
        sampleId: json['sample_id'] as int,
        eventType: json['event_type'] as String,
        whoUserId: json['who_user_id'] as int,
        whatAction: json['what_action'] as String,
        whenTs: DateTime.tryParse(json['when_ts']?.toString() ?? '') ?? DateTime.now(),
        whereLocation: json['where_location'] as String?,
        notes: json['notes'] as String?,
        previousHash: json['previous_hash'] as String?,
        currentHash: json['current_hash'] as String?,
        isImmutable: json['is_immutable'] as bool? ?? true,
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sample_id': sampleId,
        'event_type': eventType,
        'who_user_id': whoUserId,
        'what_action': whatAction,
        'when_ts': whenTs.toIso8601String(),
        'where_location': whereLocation,
        'notes': notes,
        'previous_hash': previousHash,
        'current_hash': currentHash,
        'is_immutable': isImmutable,
      };
}
