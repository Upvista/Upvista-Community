import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/connectivity_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'utils/error_handler.dart';
import 'exceptions/api_exception.dart';

/// Main API Client
///
/// Production-ready HTTP client with:
/// - Automatic token management
/// - Error handling
/// - Request/response interceptors
/// - Retry logic
/// - Connectivity checking
/// - Timeout handling
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final ConnectivityService _connectivity = ConnectivityService();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
        headers: {
          'Content-Type': ApiConfig.contentType,
          'Accept': ApiConfig.accept,
        },
        validateStatus: (status) {
          // Accept status codes < 500 as success
          // We'll handle 4xx errors in error handler
          return status != null && status < 500;
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(_dio),
      LoggingInterceptor(
        logRequests: true, // Set to false in production
        logResponses: true, // Set to false in production
        logErrors: true,
      ),
    ]);

    // Initialize connectivity service
    _connectivity.initialize();
  }

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Get underlying Dio instance (use sparingly)
  Dio get dio => _dio;

  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    return _handleRequest<T>(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
      fromJson: fromJson,
    );
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    return _handleRequest<T>(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      fromJson: fromJson,
    );
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    return _handleRequest<T>(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      fromJson: fromJson,
    );
  }

  /// PATCH request
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    return _handleRequest<T>(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      fromJson: fromJson,
    );
  }

  /// DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    return _handleRequest<T>(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      fromJson: fromJson,
    );
  }

  /// Handle request with retry logic and error handling
  Future<T> _handleRequest<T>(
    Future<Response> Function() request, {
    T Function(dynamic)? fromJson,
    int retryCount = 0,
  }) async {
    try {
      // Check connectivity before making request
      final isConnected = await _connectivity.checkConnectivity();
      if (!isConnected) {
        throw const NetworkException(
          'No internet connection. Please check your network settings.',
        );
      }

      // Make request
      final response = await request();

      // Handle response
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw ErrorHandler.handleDioError(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }

      // Parse response
      if (fromJson != null) {
        return fromJson(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      // Convert DioException to ApiException
      throw ErrorHandler.handleDioError(e);
    } on ApiException {
      // Re-throw ApiException as-is
      rethrow;
    } catch (e) {
      // Handle unexpected errors
      throw NetworkException(
        'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Upload file (multipart/form-data)
  Future<T> uploadFile<T>(
    String path,
    String filePath, {
    String fileKey = 'file',
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final isConnected = await _connectivity.checkConnectivity();
      if (!isConnected) {
        throw const NetworkException(
          'No internet connection. Please check your network settings.',
        );
      }

      final formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(filePath),
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw ErrorHandler.handleDioError(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }

      if (fromJson != null) {
        return fromJson(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Upload failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Update base URL (useful for environment switching)
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Clear all interceptors (use with caution)
  void clearInterceptors() {
    _dio.interceptors.clear();
  }
}
