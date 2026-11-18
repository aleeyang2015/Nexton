import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';

/// The photo change's own refusals (#59) and the tokens they become, for
/// `failure_localizer.dart` to say in plain words. Every other answer
/// (`EMPLOYEE_NOT_FOUND`, `FORBIDDEN`, `MODULE_NOT_ACTIVE`, a 5xx, no
/// signal) goes through the shared texts.
class ProfilePhotoErrorCode {
  const ProfilePhotoErrorCode._();

  static const String tokenNotImage = 'profilePhotoNotImage';
  static const String tokenTooLarge = 'profilePhotoTooLarge';

  /// The token [error] stands for, or null: a `413` (the server's body
  /// limit answers the generic `ERROR`) is too large; `INVALID_REQUEST` is
  /// no file, or not an image.
  static String? tokenForResponse(DioException error) {
    if (error.response?.statusCode == 413) return tokenTooLarge;
    final code = ApiError.tryParse(error.response?.data)?.code;
    if (code == 'INVALID_REQUEST') return tokenNotImage;
    return null;
  }
}
