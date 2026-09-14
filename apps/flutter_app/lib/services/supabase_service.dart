import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized && _client != null;
  static SupabaseClient? get client => _client;

  /**
   * Initializes Supabase safely with fallback to offline/mock mode
   */
  static Future<void> initialize() async {
    try {
      if (AppConfig.forceDemoMode) {
        debugPrint('[SupabaseService] forceDemoMode is true, skipping cloud initialization.');
        return;
      }

      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: kDebugMode,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('[SupabaseService] Connected to Supabase successfully.');
    } catch (e) {
      _isInitialized = false;
      _client = null;
      debugPrint('[SupabaseService] Supabase initialization failed or running offline: $e');
    }
  }

  static User? get currentUser => _client?.auth.currentUser;
  static Session? get currentSession => _client?.auth.currentSession;
  static Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;
}
