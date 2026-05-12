import '../models/admin_account.dart';
import 'api_client.dart';

class AdminService {
  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AdminAccount>> fetchAdmins() async {
    final data = await _apiClient.get('/admins');
    return (data['admins'] as List).map((item) => AdminAccount.fromJson(item)).toList();
  }

  Future<void> createAdmin({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _apiClient.post('/admins', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<void> setActive(int adminId, bool isActive) async {
    await _apiClient.patch('/admins/$adminId/active', {'isActive': isActive});
  }

  Future<void> setPrimary(int adminId) async {
    await _apiClient.patch('/admins/$adminId/primary', {});
  }

  Future<void> deleteAdmin(int adminId) async {
    await _apiClient.delete('/admins/$adminId');
  }
}
