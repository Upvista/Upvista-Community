/// API Configuration for Asteria Backend
///
/// This file contains all API-related configuration constants.
/// For production, these values should be loaded from environment variables.
class ApiConfig {
  // Base URLs
  // IMPORTANT: Choose the correct URL based on your testing environment:
  //
  // For Android Emulator (MUST USE THIS):
  // static const String baseUrl = 'http://10.0.2.2:8081/api/v1';
  //
  // For Physical Android Device (use your PC's IP - current: 10.172.47.27):
  static const String baseUrl = 'http://192.168.100.187:8081/api/v1';
  //
  // For iOS Simulator:
  // static const String baseUrl = 'http://localhost:8081/api/v1';
  //
  // Find your IP: Windows (ipconfig) or Mac/Linux (ifconfig)
  static const String wsUrl = 'ws://10.172.47.27:8081/ws';

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

  // Retry configuration - Optimized for speed
  static const int maxRetries = 1; // Reduced from 3 (faster failure detection)
  static const Duration retryDelay = Duration(
    milliseconds: 500,
  ); // Reduced from 1s

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
