class AttemptReport {
  AttemptReport({
    required this.attemptId,
    required this.testId,
    required this.testTitle,
    required this.studentId,
    required this.fullName,
    required this.branchName,
    required this.semester,
    required this.status,
    required this.events,
    required this.blockedActions,
    required this.aiSummary,
    this.boardRollNo,
    this.rollNo,
    this.collegeId,
    this.email,
    this.phone,
    this.collegeName,
    this.courseName,
    this.guardianName,
    this.branchCode,
    this.startedAt,
    this.lastSeenAt,
    this.completedAt,
    this.blockedAt,
    this.blockedReason,
    this.timeTakenSeconds,
  });

  final int attemptId;
  final int testId;
  final String testTitle;
  final int studentId;
  final String fullName;
  final String branchName;
  final int semester;
  final String status;
  final List<AttemptReportEvent> events;
  final List<AttemptReportEvent> blockedActions;
  final String aiSummary;
  final String? boardRollNo;
  final String? rollNo;
  final String? collegeId;
  final String? email;
  final String? phone;
  final String? collegeName;
  final String? courseName;
  final String? guardianName;
  final String? branchCode;
  final DateTime? startedAt;
  final DateTime? lastSeenAt;
  final DateTime? completedAt;
  final DateTime? blockedAt;
  final String? blockedReason;
  final int? timeTakenSeconds;

  factory AttemptReport.fromJson(Map<String, dynamic> json) {
    return AttemptReport(
      attemptId: json['attempt_id'] as int,
      testId: json['test_id'] as int,
      testTitle: json['test_title'] as String,
      studentId: json['student_id'] as int,
      fullName: json['full_name'] as String,
      branchName: json['branch_name'] as String,
      semester: json['semester'] as int? ?? 1,
      status: json['status'] as String? ?? 'started',
      events: _events(json['events']),
      blockedActions: _events(json['blocked_actions']),
      aiSummary: json['ai_summary'] as String? ?? '',
      boardRollNo: json['board_roll_no'] as String?,
      rollNo: json['roll_no'] as String?,
      collegeId: json['college_id'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      collegeName: json['college_name'] as String?,
      courseName: json['course_name'] as String?,
      guardianName: json['guardian_name'] as String?,
      branchCode: json['branch_code'] as String?,
      startedAt: _date(json['started_at']),
      lastSeenAt: _date(json['last_seen_at']),
      completedAt: _date(json['completed_at']),
      blockedAt: _date(json['blocked_at']),
      blockedReason: json['blocked_reason'] as String?,
      timeTakenSeconds: (json['time_taken_seconds'] as num?)?.toInt(),
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<AttemptReportEvent> _events(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((event) =>
            AttemptReportEvent.fromJson(Map<String, dynamic>.from(event)))
        .toList();
  }
}

class AttemptReportEvent {
  AttemptReportEvent({
    required this.eventType,
    this.severity,
    this.message,
    this.createdAt,
  });

  final String eventType;
  final String? severity;
  final String? message;
  final DateTime? createdAt;

  factory AttemptReportEvent.fromJson(Map<String, dynamic> json) {
    return AttemptReportEvent(
      eventType: json['event_type'] as String? ?? '',
      severity: json['severity'] as String?,
      message: json['message'] as String?,
      createdAt: AttemptReport._date(json['created_at']),
    );
  }
}
