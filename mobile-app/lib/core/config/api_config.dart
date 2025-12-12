/// API Configuration for Asteria Backend
///
/// This file contains all API-related configuration constants.
/// For production, these values should be loaded from environment variables.
class ApiConfig {
  // Base URLs
  static const String baseUrl = 'http://localhost:8081/api/v1';
  static const String wsUrl = 'ws://localhost:8081/ws';

  // For production, use:
  // static const String baseUrl = 'https://api.asteria.app/api/v1';
  // static const String wsUrl = 'wss://api.asteria.app/ws';

  // API Endpoints
  static const String auth = '/auth';
  static const String account = '/account';
  static const String posts = '/posts';
  static const String feed = '/feed';
  static const String messages = '/messages';
  static const String conversations = '/conversations';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String relationships = '/relationships';
  static const String hashtags = '/hashtags';

  // Timeouts (in milliseconds)
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // Token storage keys
  static const String accessTokenKey = 'asteria_access_token';
  static const String refreshTokenKey = 'asteria_refresh_token';
  static const String userDataKey = 'asteria_user_data';

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
