class AdminAccount {
  AdminAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
    required this.twoFactorEnabled,
    required this.isPrimaryAdmin,
  });

  final int id;
  final String fullName;
  final String email;
  final bool isActive;
  final bool twoFactorEnabled;
  final bool isPrimaryAdmin;

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      twoFactorEnabled: json['two_factor_enabled'] == true || json['two_factor_enabled'] == 1,
      isPrimaryAdmin: json['is_primary_admin'] == true || json['is_primary_admin'] == 1,
    );
  }
}
