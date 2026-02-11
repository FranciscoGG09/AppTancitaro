import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final SharedPreferences prefs;
  final ApiService apiService;

  User? _currentUser;
  bool _isLoading = false;

  AuthService(this.prefs, this.apiService) {
    _loadCurrentUser();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Verificar si el perfil está completo
  bool get isProfileComplete {
    return _currentUser?.isProfileComplete ?? false;
  }

  Future<void> _loadCurrentUser() async {
    if (await isLoggedIn()) {
      _currentUser = await apiService.getUserProfile();
      notifyListeners();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await apiService.login(email, password);

      if (success) {
        await _loadCurrentUser();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await apiService.register(email, password);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );

      if (success) {
        _currentUser = await apiService.getUserProfile();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('profile_complete');

    _currentUser = null;
    notifyListeners();
  }
}
