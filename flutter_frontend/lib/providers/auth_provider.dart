import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._apiService);

  bool get isAuthenticated => _apiService.isAuthenticated;
  User? get currentUser => _apiService.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.login(username, password);
      if (!success) {
        _errorMessage = 'Invalid royal credentials. Please verify your login.';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Authentication connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> demoLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _apiService.demoLogin();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _apiService.logout();
    notifyListeners();
  }
}
