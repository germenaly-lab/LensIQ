import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';
import 'mock_data_service.dart';

class AuthService {
  final SharedPreferences _prefs;
  static const String keyUserDirectory = 'lensiq_users_directory';

  AuthService(this._prefs);

  /**
   * Retrieves all users from persistent local storage
   */
  List<UserProfile> getAllUsers() {
    final raw = _prefs.getString(keyUserDirectory);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        return list.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // Initialize default directory once if not present
    final initialList = <UserProfile>[];

    // Seed default Super Admin (editable / deletable)
    final defaultAdmin = const UserProfile(
      id: 'usr-super-admin-01',
      email: 'admin@lensiq.cloud',
      fullName: 'Super Admin',
      role: UserRole.superAdmin,
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      authorizedBranchIds: [
        '33333333-3333-3333-3333-333333333333',
        '33333333-3333-3333-3333-333333333334',
        '33333333-3333-3333-3333-333333333335',
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
      ],
    );
    initialList.add(defaultAdmin);

    // Seed Sara and Tamer
    for (final u in MockDataService.demoUsers) {
      if (u.id != defaultAdmin.id) {
        initialList.add(u);
      }
    }

    // Merge any previously saved custom users
    final customUsersRaw = _prefs.getString('lensiq_custom_users');
    if (customUsersRaw != null) {
      try {
        final Map<String, dynamic> customUsers = jsonDecode(customUsersRaw);
        for (final entry in customUsers.values) {
          final profile = UserProfile.fromJson((entry as Map<String, dynamic>)['profile'] as Map<String, dynamic>);
          if (!initialList.any((x) => x.id == profile.id || x.email.toLowerCase() == profile.email.toLowerCase())) {
            initialList.insert(0, profile);
          }
        }
      } catch (_) {}
    }

    _saveUserDirectory(initialList);
    return initialList;
  }

  Future<void> _saveUserDirectory(List<UserProfile> users) async {
    final list = users.map((u) => u.toJson()).toList();
    await _prefs.setString(keyUserDirectory, jsonEncode(list));
  }

  /**
   * Saves or updates a user in the persistent directory
   */
  Future<void> saveOrUpdateUser(UserProfile user, {String? password}) async {
    final users = getAllUsers();
    final idx = users.indexWhere((u) => u.id == user.id || u.email.toLowerCase() == user.email.toLowerCase());
    if (idx != -1) {
      users[idx] = user;
    } else {
      users.insert(0, user);
    }
    await _saveUserDirectory(users);

    if (password != null && password.isNotEmpty) {
      await resetUserPassword(user.email, password);
    }

    // If updating current active session
    final current = getPersistedUser();
    if (current != null && (current.id == user.id || current.email.toLowerCase() == user.email.toLowerCase())) {
      final token = _prefs.getString(AppConstants.keyAuthToken) ?? 'token_${user.id}';
      await _persistSession(user, token);
    }
  }

  /**
   * Permanently deletes a user from the persistent directory
   */
  Future<void> deleteUser(String userId) async {
    final users = getAllUsers();
    final userToDelete = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => const UserProfile(id: '', email: '', fullName: '', role: UserRole.branchSecurity),
    );
    users.removeWhere((u) => u.id == userId);
    await _saveUserDirectory(users);

    // Clean up custom users record if present
    if (userToDelete.email.isNotEmpty) {
      final customUsersRaw = _prefs.getString('lensiq_custom_users');
      if (customUsersRaw != null) {
        try {
          final Map<String, dynamic> customUsers = jsonDecode(customUsersRaw);
          customUsers.remove(userToDelete.email.toLowerCase());
          await _prefs.setString('lensiq_custom_users', jsonEncode(customUsers));
        } catch (_) {}
      }
    }
  }

  /**
   * Updates the profile of the currently logged-in user
   */
  Future<UserProfile> updateCurrentUserProfile(String fullName, String email) async {
    final current = getPersistedUser();
    if (current == null) throw Exception('No active user found');
    final updated = current.copyWith(
      fullName: fullName.trim(),
      email: email.trim(),
    );
    await saveOrUpdateUser(updated);
    return updated;
  }

  /**
   * Restores persisted user profile from local storage on app start
   */
  UserProfile? getPersistedUser() {
    final raw = _prefs.getString(AppConstants.keyUserProfile);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final user = UserProfile.fromJson(json);
      // Synchronize with directory to ensure latest edits (e.g. name/email) are reflected
      final all = getAllUsers();
      final updated = all.firstWhere(
        (u) => u.id == user.id || u.email.toLowerCase() == user.email.toLowerCase(),
        orElse: () => user,
      );
      return updated;
    } catch (_) {
      return null;
    }
  }

  /**
   * Authenticate via Persistent User Directory, Supabase, or seeded demo accounts
   */
  Future<UserProfile> loginWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final allUsers = getAllUsers();

    final matched = allUsers.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => const UserProfile(id: '', email: '', fullName: '', role: UserRole.branchSecurity),
    );

    if (matched.id.isNotEmpty) {
      // Validate password
      if (cleanEmail == 'admin@lensiq.cloud' || matched.role == UserRole.superAdmin) {
        final expectedPass = _prefs.getString('lensiq_admin_password') ?? 'password123';
        if (password.isNotEmpty && password != expectedPass) {
          throw Exception('Incorrect password for Super Admin account.');
        }
      } else {
        final customUsersRaw = _prefs.getString('lensiq_custom_users');
        if (customUsersRaw != null) {
          try {
            final Map<String, dynamic> customUsers = jsonDecode(customUsersRaw);
            if (customUsers.containsKey(cleanEmail)) {
              final userEntry = customUsers[cleanEmail] as Map<String, dynamic>;
              final storedPass = userEntry['password'] as String? ?? 'password123';
              if (password.isNotEmpty && password != storedPass) {
                throw Exception('Incorrect password. Please verify your credentials.');
              }
            }
          } catch (e) {
            if (e is Exception) rethrow;
          }
        }
      }

      await _persistSession(matched, 'token_${matched.id}');
      return matched;
    }

    // Fallback to live Supabase Authentication if initialized
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
        await saveOrUpdateUser(userProfile);
        return userProfile;
      } catch (e) {
        throw Exception('Login failed: ${e.toString().replaceAll('Exception:', '').trim()}');
      }
    }

    throw Exception('User account "$cleanEmail" not found. You can add new user accounts in the Users section.');
  }

  /**
   * Change password for current logged-in user
   */
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }

    final currentUser = getPersistedUser();
    final cleanEmail = currentUser?.email.toLowerCase() ?? 'admin@lensiq.cloud';

    if (cleanEmail == 'admin@lensiq.cloud' || currentUser?.role == UserRole.superAdmin) {
      final expected = _prefs.getString('lensiq_admin_password') ?? 'password123';
      if (currentPassword != expected) {
        throw Exception('Current password does not match.');
      }
      await _prefs.setString('lensiq_admin_password', newPassword);
      return true;
    }

    final customUsersRaw = _prefs.getString('lensiq_custom_users');
    if (customUsersRaw != null) {
      final Map<String, dynamic> customUsers = jsonDecode(customUsersRaw);
      if (customUsers.containsKey(cleanEmail)) {
        final entry = Map<String, dynamic>.from(customUsers[cleanEmail] as Map);
        final stored = entry['password'] as String? ?? 'password123';
        if (currentPassword != stored) {
          throw Exception('Current password does not match.');
        }
        entry['password'] = newPassword;
        customUsers[cleanEmail] = entry;
        await _prefs.setString('lensiq_custom_users', jsonEncode(customUsers));
        return true;
      }
    }

    final expected = _prefs.getString('lensiq_admin_password') ?? 'password123';
    if (currentPassword != expected) {
      throw Exception('Current password does not match.');
    }
    await _prefs.setString('lensiq_admin_password', newPassword);
    return true;
  }

  /**
   * Directly reset or update password for any specific user (Admin privilege)
   */
  Future<bool> resetUserPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }

    if (cleanEmail == 'admin@lensiq.cloud') {
      await _prefs.setString('lensiq_admin_password', newPassword);
      return true;
    }

    final customUsersRaw = _prefs.getString('lensiq_custom_users');
    Map<String, dynamic> customUsers = {};
    if (customUsersRaw != null) {
      try {
        customUsers = jsonDecode(customUsersRaw) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (customUsers.containsKey(cleanEmail)) {
      final userEntry = Map<String, dynamic>.from(customUsers[cleanEmail] as Map);
      userEntry['password'] = newPassword;
      customUsers[cleanEmail] = userEntry;
      await _prefs.setString('lensiq_custom_users', jsonEncode(customUsers));
      return true;
    } else {
      final all = getAllUsers();
      final matched = all.firstWhere(
        (u) => u.email.toLowerCase() == cleanEmail,
        orElse: () => UserProfile(
          id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          email: cleanEmail,
          fullName: 'User',
          role: UserRole.branchSecurity,
        ),
      );
      customUsers[cleanEmail] = {
        'password': newPassword,
        'profile': matched.toJson(),
      };
      await _prefs.setString('lensiq_custom_users', jsonEncode(customUsers));
      return true;
    }
  }

  /**
   * Register a custom user into persistent local storage
   */
  Future<void> registerCustomUser(UserProfile profile, String password) async {
    await saveOrUpdateUser(profile, password: password);
  }

  /**
   * Retrieve all registered users
   */
  List<UserProfile> getCustomUsers() {
    return getAllUsers();
  }

  /**
   * Switch role instantly for demo / pairing presentation
   */
  Future<UserProfile> switchDemoRole(UserRole role) async {
    final all = getAllUsers();
    final demoUser = all.firstWhere(
      (u) => u.role == role,
      orElse: () => all.isNotEmpty ? all.first : MockDataService.demoUsers.first,
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
