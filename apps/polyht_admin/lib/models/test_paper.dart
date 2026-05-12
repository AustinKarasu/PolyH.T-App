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
      isActive: _boolFromJson(json['is_active']),
      originalFilename: json['original_filename'] as String?,
    );
  }

  static bool _boolFromJson(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return true;
  }
}
