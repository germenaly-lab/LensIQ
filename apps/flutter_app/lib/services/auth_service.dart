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
   * Authenticate via Supabase or seeded demo accounts
   */
  Future<UserProfile> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check for seeded demo credentials (instant offline/demo evaluation)
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

    // 2. Fallback to live Supabase Authentication if initialized
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

    // If Supabase is not connected and email wasn't demo
    throw Exception('Invalid credentials. For quick demo, use admin@lensiq.cloud, brand@ego.demo, or security@ego-moa.demo');
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
