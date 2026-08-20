class CaseFile {
  final int id;
  final String caseNumber;
  final String? title;
  final String? location;
  final int createdByUserId;
  final DateTime createdAt;
  final bool pendingSync;

  const CaseFile({
    required this.id,
    required this.caseNumber,
    this.title,
    this.location,
    required this.createdByUserId,
    required this.createdAt,
    this.pendingSync = false,
  });

  factory CaseFile.fromJson(Map<String, dynamic> json, {bool pendingSync = false}) => CaseFile(
        id: json['id'] as int,
        caseNumber: json['case_number'] as String,
        title: json['title'] as String?,
        location: json['location'] as String?,
        createdByUserId: json['created_by_user_id'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        pendingSync: pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_number': caseNumber,
        'title': title,
        'location': location,
        'created_by_user_id': createdByUserId,
        'created_at': createdAt.toIso8601String(),
      };
}
