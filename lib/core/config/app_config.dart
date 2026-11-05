class AppConfig {
  AppConfig._();

  static const String appName = 'Vehicle Management System';
  static const String appVersion = '1.0.0';

  // Base URL for Backend API
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  // Increased to 60s to accommodate Render / free tier container cold starts
  static const Duration requestTimeout = Duration(seconds: 60);
}
