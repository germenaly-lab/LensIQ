import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository) {
    _restorePersistedSession();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserRole? get currentRole => _currentUser?.role;

  void _restorePersistedSession() {
    _currentUser = _repository.getPersistedUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> switchDemoRole(UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.switchDemoRole(role);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.changePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> registerUser(UserProfile profile, String password) async {
    await _repository.registerUser(profile, password);
    notifyListeners();
  }

  List<UserProfile> getCustomUsers() => _repository.getCustomUsers();

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _repository.logout();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
