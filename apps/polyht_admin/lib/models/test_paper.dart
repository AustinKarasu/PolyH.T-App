class TestPaper {
  TestPaper({
    required this.id,
    required this.title,
    required this.branchName,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.timeLimitMinutes,
    required this.isActive,
    this.originalFilename,
  });

  final int id;
  final String title;
  final String branchName;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final int timeLimitMinutes;
  final bool isActive;
  final String? originalFilename;

  factory TestPaper.fromJson(Map<String, dynamic> json) {
    return TestPaper(
      id: json['id'] as int,
      title: json['title'] as String,
      branchName: json['branch_name'] as String,
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
      timeLimitMinutes: json['time_limit_minutes'] as int,
      isActive: (json['is_active'] as int? ?? 1) == 1 || json['is_active'] == true,
      originalFilename: json['original_filename'] as String?,
    );
  }
}
