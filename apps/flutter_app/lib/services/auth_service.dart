import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';
import 'mock_data_service.dart';

class AuthService {
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  /**
   * Restores persisted user profile from local storage on app start
   */
  UserProfile? getPersistedUser() {
    final raw = _prefs.getString(AppConstants.keyUserProfile);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /**
   * Authenticate via Persistent Custom Users, Supabase, or seeded demo accounts
   */
  Future<UserProfile> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check if Super Admin login with customizable persistent password
    if (cleanEmail == 'admin@lensiq.cloud') {
      final expectedPass = _prefs.getString('lensiq_admin_password') ?? 'password123';
      if (password.isNotEmpty && password != expectedPass) {
        throw Exception('Incorrect password for Super Admin account.');
      }
      final superAdmin = MockDataService.demoUsers.firstWhere(
        (u) => u.email == 'admin@lensiq.cloud',
      );
      await _persistSession(superAdmin, 'demo_token_${superAdmin.id}');
      return superAdmin;
    }

    // 2. Check for registered custom users in persistent storage
    final customUsersRaw = _prefs.getString('lensiq_custom_users');
    if (customUsersRaw != null) {
      try {
        final Map<String, dynamic> customUsers = jsonDecode(customUsersRaw);
        if (customUsers.containsKey(cleanEmail)) {
          final userEntry = customUsers[cleanEmail] as Map<String, dynamic>;
          final storedPass = userEntry['password'] as String? ?? '';
          if (password.isNotEmpty && password != storedPass) {
            throw Exception('Incorrect password. Please verify your credentials.');
          }
          final profile = UserProfile.fromJson(userEntry['profile'] as Map<String, dynamic>);
          await _persistSession(profile, 'token_${profile.id}');
          return profile;
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
    }

    // 3. Check for seeded demo credentials
    final matchedDemo = MockDataService.demoUsers.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => const UserProfile(
        id: '',
        email: '',
        fullName: '',
        role: UserRole.branchSecurity,
      ),
    );

    if (matchedDemo.id.isNotEmpty) {
      await _persistSession(matchedDemo, 'demo_token_${matchedDemo.id}');
      return matchedDemo;
    }

    // 4. Fallback to live Supabase Authentication if initialized
    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.client!.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );

        final user = res.user;
        if (user == null) {
          throw Exception('Authentication succeeded but user record is null.');
        }

        // Fetch user role and tenant metadata
        final roleStr = user.userMetadata?['role'] as String? ?? 'branch_security';
        final userProfile = UserProfile(
          id: user.id,
          email: user.email ?? cleanEmail,
          fullName: user.userMetadata?['full_name'] ?? 'Enterprise User',
          role: UserRole.fromString(roleStr),
          companyId: user.userMetadata?['company_id'],
          brandId: user.userMetadata?['brand_id'],
          branchId: user.userMetadata?['branch_id'],
        );

        await _persistSession(userProfile, res.session?.accessToken ?? 'session_token');
        return userProfile;
      } catch (e) {
        throw Exception('Login failed: ${e.toString().replaceAll('Exception:', '').trim()}');
      }
    }

    // If Supabase is not connected and email wasn't found
    throw Exception('User account "$cleanEmail" not found. You can add new user accounts in the Users section.');
  }

  /**
   * Change password for Super Admin or current user
   */
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final expected = _prefs.getString('lensiq_admin_password') ?? 'password123';
    if (currentPassword != expected) {
      throw Exception('Current password does not match.');
    }
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }
    await _prefs.setString('lensiq_admin_password', newPassword);
    return true;
  }

  /**
   * Register a custom user into persistent local storage
   */
  Future<void> registerCustomUser(UserProfile profile, String password) async {
    final customUsersRaw = _prefs.getString('lensiq_custom_users');
    Map<String, dynamic> customUsers = {};
    if (customUsersRaw != null) {
      try {
        customUsers = jsonDecode(customUsersRaw) as Map<String, dynamic>;
      } catch (_) {}
    }
    customUsers[profile.email.trim().toLowerCase()] = {
      'password': password.isNotEmpty ? password : 'password123',
      'profile': profile.toJson(),
    };
    await _prefs.setString('lensiq_custom_users', jsonEncode(customUsers));
  }

  /**
   * Retrieve all custom registered users
   */
  List<UserProfile> getCustomUsers() {
    final customUsersRaw = _prefs.getString('lensiq_custom_users');
    if (customUsersRaw == null) return [];
    try {
      final Map<String, dynamic> customUsers = jsonDecode(customUsersRaw);
      return customUsers.values
          .map((v) => UserProfile.fromJson((v as Map<String, dynamic>)['profile'] as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /**
   * Switch role instantly for demo / pairing presentation
   */
  Future<UserProfile> switchDemoRole(UserRole role) async {
    final demoUser = MockDataService.demoUsers.firstWhere(
      (u) => u.role == role,
      orElse: () => MockDataService.demoUsers.first,
    );

    await _persistSession(demoUser, 'demo_token_${demoUser.id}');
    return demoUser;
  }

  /**
   * Sign out and clear stored session
   */
  Future<void> logout() async {
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client?.auth.signOut();
      } catch (_) {}
    }
    await _prefs.remove(AppConstants.keyUserProfile);
    await _prefs.remove(AppConstants.keyAuthToken);
  }

  Future<void> _persistSession(UserProfile profile, String token) async {
    await _prefs.setString(AppConstants.keyUserProfile, jsonEncode(profile.toJson()));
    await _prefs.setString(AppConstants.keyAuthToken, token);
  }
}
