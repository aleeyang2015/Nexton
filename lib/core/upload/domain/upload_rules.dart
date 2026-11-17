/// The rules every upload follows (`POST /uploads`).
class UploadRules {
  const UploadRules._();

  /// Largest file the App sends, in bytes. The server refuses any body over
  /// 5 MiB (5,242,880) with a `413`; the multipart wrapping counts towards
  /// it, so the file itself is held to 5,000,000. Checked on the phone, so a
  /// big file is refused before it is sent.
  static const int maxBytes = 5000000;
}

/// The `folder` an upload is sent with: part of where the server stores it.
class UploadFolder {
  const UploadFolder._();

  static const String leave = 'leave';
  static const String offsite = 'offsite';

  /// The "forgot to scan" photo.
  static const String correction = 'correction';
}
