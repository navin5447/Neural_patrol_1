class AppUser {
  final int id;
  final String officerId;
  final String name;
  final String role;
  final String status;

  const AppUser({
    required this.id,
    required this.officerId,
    required this.name,
    required this.role,
    this.status = 'active',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        officerId: json['officer_id'] as String,
        name: json['name'] as String,
        role: json['role'] as String? ?? 'field_officer',
        status: json['status'] as String? ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'officer_id': officerId,
        'name': name,
        'role': role,
        'status': status,
      };
}
