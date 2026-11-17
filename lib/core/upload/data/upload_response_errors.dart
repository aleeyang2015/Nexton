import 'package:dio/dio.dart';

import '../../network/api_response.dart';
import '../domain/upload_error_code.dart';

/// The `UploadErrorCode` token a refused upload stands for, or null when it
/// is none of these (no signal, a 500: the shared handling says it).
///
/// - `413`, by status: the server's body limit answers the generic code
///   `ERROR`; `FILE_TOO_LARGE` is the handler's own (never reached today).
/// - `INVALID_REQUEST`: the file could not be read.
/// - `STORAGE_UNAVAILABLE`, or a `404`: a server with no storage has no
///   upload route at all.
String? uploadTokenForResponse(DioException error) {
  final status = error.response?.statusCode;
  final code = ApiError.tryParse(error.response?.data)?.code;
  if (status == 413 || code == 'FILE_TOO_LARGE') {
    return UploadErrorCode.tokenFileTooLarge;
  }
  if (code == 'INVALID_REQUEST') return UploadErrorCode.tokenInvalidFile;
  if (code == 'STORAGE_UNAVAILABLE' || status == 404) {
    return UploadErrorCode.tokenStorageUnavailable;
  }
  return null;
}
