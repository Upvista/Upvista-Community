import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Logging interceptor for API requests
///
/// Logs all API requests and responses for debugging.
/// In production, this can be disabled or configured
/// to only log errors.
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  final bool logRequests;
  final bool logResponses;
  final bool logErrors;

  LoggingInterceptor({
    this.logRequests = true,
    this.logResponses = true,
    this.logErrors = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (logRequests) {
      _logger.d(
        'REQUEST[${options.method}] => PATH: ${options.path}\n'
        'Headers: ${options.headers}\n'
        'Data: ${options.data}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (logResponses) {
      _logger.i(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n'
        'Data: ${response.data}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (logErrors) {
      _logger.e(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}\n'
        'Message: ${err.message}\n'
        'Error: ${err.error}\n'
        'Response: ${err.response?.data}',
      );
    }
    handler.next(err);
  }
}
