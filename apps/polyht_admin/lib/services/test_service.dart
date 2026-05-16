import '../models/branch.dart';
import '../models/attempt_report.dart';
import '../models/exam_event.dart';
import '../models/locked_attempt.dart';
import '../models/test_paper.dart';
import 'api_client.dart';

class TestService {
  TestService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Branch>> fetchBranches() async {
    final data = await _apiClient.get('/branches');
    return (data['branches'] as List)
        .map((item) => Branch.fromJson(item))
        .toList();
  }

  Future<List<TestPaper>> fetchTests() async {
    final data = await _apiClient.get('/tests');
    return (data['tests'] as List)
        .map((item) => TestPaper.fromJson(item))
        .toList();
  }

  Future<void> uploadTest({
    required String title,
    required int branchId,
    required int semester,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required int timeLimitMinutes,
    String? pdfPath,
    List<int>? pdfBytes,
    required String pdfName,
  }) async {
    await _apiClient.uploadTest(
      title: title,
      branchId: branchId,
      semester: semester,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      timeLimitMinutes: timeLimitMinutes,
      pdfPath: pdfPath,
      pdfBytes: pdfBytes,
      pdfName: pdfName,
    );
  }

  Future<void> replacePdf({
    required int testId,
    String? pdfPath,
    List<int>? pdfBytes,
    required String pdfName,
  }) async {
    await _apiClient.replacePdf(
        testId: testId, pdfPath: pdfPath, pdfBytes: pdfBytes, pdfName: pdfName);
  }

  Future<void> deleteTest(int testId) async {
    await _apiClient.delete('/tests/$testId');
  }

  Future<void> setTestActive(
      {required int testId, required bool isActive}) async {
    await _apiClient.patch('/tests/$testId/active', {'isActive': isActive});
  }

  Future<void> endTestNow(int testId) async {
    await _apiClient.postEmpty('/tests/$testId/end');
  }

  Future<List<ExamEvent>> fetchEvents({int? branchId}) async {
    final query = branchId == null ? '' : '?branchId=$branchId';
    final data = await _apiClient.get('/attempts/admin/events$query');
    return (data['events'] as List)
        .map((item) => ExamEvent.fromJson(item))
        .toList();
  }

  Future<List<LockedAttempt>> fetchLockedAttempts({int? branchId}) async {
    final query = branchId == null ? '' : '?branchId=$branchId';
    final data = await _apiClient.get('/attempts/admin/locked$query');
    return (data['attempts'] as List)
        .map((item) => LockedAttempt.fromJson(item))
        .toList();
  }

  Future<List<AttemptReport>> fetchAttemptReports(
      {int? testId, int? branchId}) async {
    final params = <String>[
      if (testId != null) 'testId=$testId',
      if (branchId != null) 'branchId=$branchId',
    ];
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await _apiClient.get('/attempts/admin/reports$query');
    return (data['reports'] as List)
        .map((item) => AttemptReport.fromJson(item))
        .toList();
  }

  Future<void> allowAttempt(int attemptId) async {
    await _apiClient.postEmpty('/attempts/admin/$attemptId/allow');
  }

  Future<String> downloadPdf(int testId) => _apiClient.downloadPdf(testId);
}
