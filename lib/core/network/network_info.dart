import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_error_mapper.dart';

/// Interface for checking network connectivity
abstract class NetworkInfo {
  /// Check if device is connected to internet
  Future<bool> get isConnected;
}

/// Implementation of NetworkInfo using Dio
///
/// Probes our own API host rather than a third-party site: that is the host
/// the app actually needs, and it stays reachable on networks that block
/// sites like Google. Expects a bare [Dio] — no base URL, auth or tenant
/// headers — so the probe never triggers a token refresh.
class NetworkInfoImpl implements NetworkInfo {
  final Dio dio;

  NetworkInfoImpl(this.dio);

  static const Duration _probeTimeout = Duration(seconds: 3);

  @override
  Future<bool> get isConnected async {
    try {
      await dio.head<void>(
        AppConstants.baseUrl,
        options: Options(
          sendTimeout: _probeTimeout,
          receiveTimeout: _probeTimeout,
          // Any HTTP status proves the server answered; only a transport
          // error means we are offline.
          validateStatus: (_) => true,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Adds the headers every request needs and normalises transport errors into a
/// [Failure] carried on `DioException.error`, which [BaseRepository] unwraps.
///
/// Register this **after** any interceptor that needs to inspect the raw
/// response (e.g. AuthInterceptor's 401 refresh) — it rejects the error chain.
class NetworkInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add common headers
    options.headers.addAll({
      AppConstants.acceptHeader: AppConstants.jsonContentType,
      AppConstants.userAgentHeader: 'NextOn App ${AppConstants.appVersion}',
    });

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convert Dio exceptions to Failure
    final failure = ApiErrorMapper.fromDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: failure,
      ),
    );
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Successful response handling
    super.onResponse(response, handler);
  }
}
