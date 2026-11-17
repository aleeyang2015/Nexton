import 'package:dio/dio.dart';

import '../../errors/failure.dart';
import '../../network/api_response.dart';

/// The upload's refusals and the tokens they become, for
/// `failure_localizer.dart` to say in plain words.
class UploadErrorCode {
  const UploadErrorCode._();

  static const String tokenFileTooLarge = 'uploadFileTooLarge';
  static const String tokenInvalidFile = 'uploadInvalidFile';
  static const String tokenStorageUnavailable = 'uploadStorageUnavailable';

  /// Not from the server: the phone would not let the App use the camera or
  /// the photos.
  static const String tokenPermissionDenied = 'uploadPermissionDenied';

  static const Set<String> _all = {
    tokenFileTooLarge,
    tokenInvalidFile,
    tokenStorageUnavailable,
    tokenPermissionDenied,
  };

  /// The token a refused upload stands for, or null when it is none of
  /// these (no signal, a 500: the shared handling says it).
  ///
  /// - `413`, by status: the server's body limit answers the generic code
  ///   `ERROR`; `FILE_TOO_LARGE` is the handler's own (never reached today).
  /// - `INVALID_REQUEST`: the file could not be read.
  /// - `STORAGE_UNAVAILABLE`, or a `404`: a server with no storage has no
  ///   upload route at all.
  static String? tokenForResponse(DioException error) {
    final status = error.response?.statusCode;
    final code = ApiError.tryParse(error.response?.data)?.code;
    if (status == 413 || code == 'FILE_TOO_LARGE') return tokenFileTooLarge;
    if (code == 'INVALID_REQUEST') return tokenInvalidFile;
    if (code == 'STORAGE_UNAVAILABLE' || status == 404) {
      return tokenStorageUnavailable;
    }
    return null;
  }

  /// The token [failure] carries, when it is one of the upload's.
  static String? tokenOf(Failure failure) => failure.maybeWhen(
    validation: (message, _, _) => _all.contains(message) ? message : null,
    orElse: () => null,
  );
}
