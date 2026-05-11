import '../models/app_user.dart';
import 'api_client.dart';

class StudentService {
  StudentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<List<AppUser>> fetchStudents({int? branchId, String? search}) async {
    final params = <String>[];
    if (branchId != null) params.add('branchId=$branchId');
    if (search != null && search.isNotEmpty) params.add('search=$search');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await _apiClient.get('/students$query');
    return (data['students'] as List).map((j) => AppUser.fromJson(j)).toList();
  }

  Future<AppUser> fetchStudent(int id) async {
    final data = await _apiClient.get('/students/$id');
    return AppUser.fromJson(data['student']);
  }
}
