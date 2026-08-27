class BackendConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: '',
  );
}

