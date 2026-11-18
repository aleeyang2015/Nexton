/// The photo change's own refusals (#59), as tokens for
/// `failure_localizer.dart` to say in plain words. Every other answer goes
/// through the shared texts.
abstract final class ProfilePhotoError {
  /// No file, or not a JPEG or PNG photo.
  static const String tokenNotImage = 'profilePhotoNotImage';

  /// Over the 5,000,000-byte limit (on the phone, or the server's 413).
  static const String tokenTooLarge = 'profilePhotoTooLarge';
}
