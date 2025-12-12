import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../services/token_storage_service.dart';

/// Authentication interceptor
///
/// Automatically adds JWT token to all authenticated requests
/// and handles token refresh when needed.
class AuthInterceptor extends Interceptor {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final Dio _dio;
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
  _pendingRequests = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (_isPublicEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Add access token to request
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConfig.authorizationHeader] =
          '${ApiConfig.bearerPrefix}$token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // Skip refresh for auth endpoints
      if (_isPublicEndpoint(requestOptions.path)) {
        handler.next(err);
        return;
      }

      // Queue request if already refreshing
      if (_isRefreshing) {
        return _queueRequest(requestOptions, handler);
      }

      _isRefreshing = true;

      try {
        // Attempt to refresh token
        final newToken = await _refreshToken();

        if (newToken != null) {
          // Retry original request with new token
          final opts = requestOptions;
          opts.headers[ApiConfig.authorizationHeader] =
              '${ApiConfig.bearerPrefix}$newToken';

          final response = await _dio.fetch(opts);
          handler.resolve(response);

          // Process queued requests
          _processQueuedRequests(newToken);
        } else {
          // Refresh failed - clear tokens and reject
          await _tokenStorage.clearAll();
          handler.reject(err);
        }
      } catch (e) {
        // Refresh failed - clear tokens
        await _tokenStorage.clearAll();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
        _pendingRequests.clear();
      }
    } else {
      handler.next(err);
    }
  }

  /// Check if endpoint is public (doesn't require auth)
  bool _isPublicEndpoint(String path) {
    final publicPaths = [
      '/auth/register',
      '/auth/login',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/verify-email',
      '/auth/oauth',
      '/search',
      '/hashtags',
    ];

    return publicPaths.any((publicPath) => path.contains(publicPath));
  }

  /// Refresh access token using refresh token
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'Content-Type': ApiConfig.contentType,
            'Accept': ApiConfig.accept,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['data']?['token'] as String?;
        if (newAccessToken != null) {
          await _tokenStorage.saveAccessToken(newAccessToken);
          return newAccessToken;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Queue request while token is being refreshed
  void _queueRequest(RequestOptions options, ErrorInterceptorHandler handler) {
    _pendingRequests.add((options: options, handler: handler));
  }

  /// Process all queued requests with new token
  void _processQueuedRequests(String newToken) {
    for (final pending in _pendingRequests) {
      pending.options.headers[ApiConfig.authorizationHeader] =
          '${ApiConfig.bearerPrefix}$newToken';

      _dio
          .fetch(pending.options)
          .then(
            (response) => pending.handler.resolve(response),
            onError: (error) => pending.handler.reject(
              error is DioException
                  ? error
                  : DioException(requestOptions: pending.options, error: error),
            ),
          );
    }
  }
}
