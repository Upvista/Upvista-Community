class AppConfig {
  // Backend API Configuration
  // Update these URLs to match your backend
  static const String baseUrl = 'http://localhost:8081';
  static const String wsUrl = 'ws://localhost:8081/ws';

  // For production, use environment variables:
  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'https://api.upvista.com',
  // );

  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // App Configuration
  static const String appName = 'Upvista Community';
  static const String appVersion = '1.0.0';

  // WebSocket Configuration
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const int wsMaxReconnectAttempts = 5;
  static const Duration wsHeartbeatInterval = Duration(seconds: 30);

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
