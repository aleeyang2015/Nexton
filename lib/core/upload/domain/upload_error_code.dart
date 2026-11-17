import '../../errors/failure.dart';

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

  /// The token [failure] carries, when it is one of the upload's.
  static String? tokenOf(Failure failure) => failure.maybeWhen(
    validation: (message, _, _) => _all.contains(message) ? message : null,
    orElse: () => null,
  );
}
