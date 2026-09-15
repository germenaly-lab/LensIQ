import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  UserProfile? getPersistedUser() => _authService.getPersistedUser();

  Future<UserProfile> login(String email, String password) =>
      _authService.loginWithEmail(email, password);

  Future<UserProfile> switchDemoRole(UserRole role) =>
      _authService.switchDemoRole(role);

  Future<bool> changePassword(String currentPassword, String newPassword) =>
      _authService.changePassword(currentPassword, newPassword);

  Future<void> registerUser(UserProfile profile, String password) =>
      _authService.registerCustomUser(profile, password);

  List<UserProfile> getCustomUsers() => _authService.getCustomUsers();

  Future<void> logout() => _authService.logout();
}
