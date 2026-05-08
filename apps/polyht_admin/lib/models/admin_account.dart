class AdminAccount {
  AdminAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
  });

  final int id;
  final String fullName;
  final String email;
  final bool isActive;

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
