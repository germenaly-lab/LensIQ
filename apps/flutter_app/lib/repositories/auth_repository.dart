import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  UserProfile? getPersistedUser() => _authService.getPersistedUser();

  List<UserProfile> getAllUsers() => _authService.getAllUsers();

  Future<UserProfile> login(String email, String password) =>
      _authService.loginWithEmail(email, password);

  Future<UserProfile> switchDemoRole(UserRole role) =>
      _authService.switchDemoRole(role);

  Future<bool> changePassword(String currentPassword, String newPassword) =>
      _authService.changePassword(currentPassword, newPassword);

  Future<bool> resetUserPassword(String email, String newPassword) =>
      _authService.resetUserPassword(email, newPassword);

  Future<void> saveOrUpdateUser(UserProfile profile, {String? password}) =>
      _authService.saveOrUpdateUser(profile, password: password);

  Future<void> registerUser(UserProfile profile, String password) =>
      _authService.registerCustomUser(profile, password);

  Future<void> deleteUser(String userId) =>
      _authService.deleteUser(userId);

  Future<UserProfile> updateCurrentUserProfile(String fullName, String email) =>
      _authService.updateCurrentUserProfile(fullName, email);

  List<UserProfile> getCustomUsers() => _authService.getCustomUsers();

  Future<void> logout() => _authService.logout();
}
