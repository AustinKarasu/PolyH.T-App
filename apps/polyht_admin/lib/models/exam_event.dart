class ExamEvent {
  ExamEvent({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.studentName,
    required this.branchName,
    required this.testTitle,
    required this.createdAt,
    this.message,
    this.collegeId,
  });

  final int id;
  final String eventType;
  final String severity;
  final String studentName;
  final String branchName;
  final String testTitle;
  final DateTime createdAt;
  final String? message;
  final String? collegeId;

  factory ExamEvent.fromJson(Map<String, dynamic> json) {
    return ExamEvent(
      id: json['id'] as int,
      eventType: json['event_type'] as String,
      severity: json['severity'] as String,
      studentName: json['student_name'] as String,
      branchName: json['branch_name'] as String,
      testTitle: json['test_title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      message: json['message'] as String?,
      collegeId: json['college_id'] as String?,
    );
  }
}
