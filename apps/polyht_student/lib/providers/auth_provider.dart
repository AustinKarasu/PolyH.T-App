import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _tokenStorage = TokenStorage();

  AppUser? user;
  bool isLoading = true;
  String? error;

  bool get isAuthenticated => user != null;

  Future<void> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token != null) {
      try {
        user = await _authService.me();
      } catch (_) {
        await _tokenStorage.clear();
        user = null;
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await _authService.login(identifier, password);
    } catch (err) {
      error = err.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    notifyListeners();
  }
}
