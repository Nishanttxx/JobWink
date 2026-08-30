class SupabaseConfig {
  static const String _rawUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: String.fromEnvironment(
      'supabase_url',
      defaultValue: String.fromEnvironment(
        'SUPABASE_PROJECT_URL',
        defaultValue: String.fromEnvironment(
          'VITE_SUPABASE_URL',
          defaultValue: String.fromEnvironment(
            'NEXT_PUBLIC_SUPABASE_URL',
            defaultValue: '',
          ),
        ),
      ),
    ),
  );

  static const String _rawAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_KEY',
      defaultValue: String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: String.fromEnvironment(
          'SUPABASE_PUBLIC_KEY',
          defaultValue: String.fromEnvironment(
            'supabase_anon_key',
            defaultValue: String.fromEnvironment(
              'VITE_SUPABASE_ANON_KEY',
              defaultValue: String.fromEnvironment(
                'NEXT_PUBLIC_SUPABASE_ANON_KEY',
                defaultValue: '',
              ),
            ),
          ),
        ),
      ),
    ),
  );

  static String get url {
    var u = _sanitize(_rawUrl);
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static String get anonKey => _sanitize(_rawAnonKey);

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      anonKey.length >= 20 &&
      (url.startsWith('http://') || url.startsWith('https://'));

  static String _sanitize(String val) {
    var v = val.trim();
    if (v.isEmpty || v == 'null' || v == 'undefined' || v == '""' || v == "''") {
      return '';
    }
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1).trim();
    }
    return v;
  }
}
