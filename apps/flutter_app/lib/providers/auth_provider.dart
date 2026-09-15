import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  UserProfile? _currentUser;
  List<UserProfile> _allUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository) {
    _restorePersistedSession();
    loadUsers();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserProfile> get allUsers => _allUsers;

  UserRole? get currentRole => _currentUser?.role;

  void loadUsers() {
    _allUsers = _repository.getAllUsers();
    notifyListeners();
  }

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
      loadUsers();
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
      loadUsers();
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

  Future<bool> resetUserPassword(String email, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.resetUserPassword(email, newPassword);
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

  Future<void> saveOrUpdateUser(UserProfile profile, {String? password}) async {
    await _repository.saveOrUpdateUser(profile, password: password);
    if (_currentUser?.id == profile.id || _currentUser?.email.toLowerCase() == profile.email.toLowerCase()) {
      _currentUser = profile;
    }
    loadUsers();
  }

  Future<void> registerUser(UserProfile profile, String password) async {
    await saveOrUpdateUser(profile, password: password);
  }

  Future<bool> deleteUser(String userId) async {
    await _repository.deleteUser(userId);
    loadUsers();
    return true;
  }

  Future<bool> updateCurrentUserProfile(String fullName, String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCurrentUserProfile(fullName, email);
      _currentUser = updated;
      loadUsers();
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
