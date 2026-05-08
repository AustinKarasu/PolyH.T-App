class LockedAttempt {
  LockedAttempt({
    required this.id,
    required this.testTitle,
    required this.studentName,
    required this.branchName,
    required this.blockedAt,
    this.collegeId,
    this.blockedReason,
  });

  final int id;
  final String testTitle;
  final String studentName;
  final String branchName;
  final DateTime blockedAt;
  final String? collegeId;
  final String? blockedReason;

  factory LockedAttempt.fromJson(Map<String, dynamic> json) {
    return LockedAttempt(
      id: json['id'] as int,
      testTitle: json['test_title'] as String,
      studentName: json['student_name'] as String,
      branchName: json['branch_name'] as String,
      blockedAt: DateTime.parse(json['blocked_at'] as String),
      collegeId: json['college_id'] as String?,
      blockedReason: json['blocked_reason'] as String?,
    );
  }
}
