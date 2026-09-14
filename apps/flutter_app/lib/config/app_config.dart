/**
 * AppConfig
 * Runtime environment configuration for LensIQ Flutter Application.
 * Supports configurable API Base URL, Supabase credentials, and Demo Mode toggles.
 */
class AppConfig {
  // Backend & Streaming Gateway URLs
  static String backendBaseUrl = 'http://localhost:4000/api/v1';
  static String streamingGatewayBaseUrl = 'https://stream.lensiq.cloud';

  // Supabase Configuration
  static String supabaseUrl = 'https://lensiq-demo.supabase.co';
  static String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_anon_key_for_offline_and_demo';

  // Demo / Offline Mode Indicator
  static bool forceDemoMode = false;

  static void updateBackendUrl(String url) {
    backendBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
