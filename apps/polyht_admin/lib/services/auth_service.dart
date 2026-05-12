import '../models/app_user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AppUser> login(String identifier, String password, {String? totpCode}) async {
    final data = await _apiClient.post('/auth/login', {
      'identifier': identifier,
      'password': password,
      if (totpCode != null && totpCode.isNotEmpty) 'totpCode': totpCode,
    });
    if (data['requiresTwoFactor'] == true) {
      throw Exception('2FA code required');
    }
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

  Future<Map<String, dynamic>> setupTwoFactor() async {
    return await _apiClient.post('/auth/2fa/setup', {}) as Map<String, dynamic>;
  }

  Future<AppUser> enableTwoFactor(String code) async {
    final data = await _apiClient.post('/auth/2fa/enable', {'code': code});
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> disableTwoFactor(String code) async {
    final data = await _apiClient.post('/auth/2fa/disable', {'code': code});
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
