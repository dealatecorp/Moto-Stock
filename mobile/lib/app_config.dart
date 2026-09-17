class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseKey => supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;

  static bool get hasSupabaseValues =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static bool get hasPartialSupabaseValues =>
      supabaseUrl.isNotEmpty != supabaseKey.isNotEmpty;
}
