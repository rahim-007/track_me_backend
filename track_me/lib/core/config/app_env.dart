/// Environment configuration
/// Values are injected at build time via --dart-define
class AppEnv {
  AppEnv._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://track-me-backend-pe6j.onrender.com/api', // Render (cloud) backend
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isProduction =>
      const bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static bool get isDevelopment => !isProduction;
}
