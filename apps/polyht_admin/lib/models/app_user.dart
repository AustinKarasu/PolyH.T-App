class AppUser {
  AppUser({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.collegeId,
    this.branchId,
    this.branchName,
    this.branchCode,
  });

  final int id;
  final String fullName;
  final String role;
  final String? email;
  final String? collegeId;
  final int? branchId;
  final String? branchName;
  final String? branchCode;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
      collegeId: json['college_id'] as String?,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
      branchCode: json['branch_code'] as String?,
    );
  }
}
