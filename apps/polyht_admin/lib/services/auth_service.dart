import '../models/app_user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AppUser> login(String identifier, String password) async {
    final data = await _apiClient.post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    if (user.role != 'admin') {
      throw Exception('Admin access only');
    }
    await _tokenStorage.saveToken(data['token'] as String);
    return user;
  }

  Future<AppUser> me() async {
    final data = await _apiClient.get('/auth/me');
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    if (user.role != 'admin') {
      await _tokenStorage.clear();
      throw Exception('Admin access only');
    }
    return user;
  }

  Future<void> logout() async {
    await _apiClient.postEmpty('/auth/logout').catchError((_) {});
    await _tokenStorage.clear();
  }
}
