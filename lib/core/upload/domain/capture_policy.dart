import 'local_file.dart';

/// Where a file can come from.
enum CaptureSource { camera, gallery, file }

/// Which sources a screen offers (owner's decision 23).
enum CapturePolicy {
  /// The camera alone: off-site proof must be taken there and then.
  cameraOnly,

  /// Camera, gallery or an image file: the "forgot to scan" photo.
  photo,

  /// The same sources, for the profile photo, whose upload takes JPEG and
  /// PNG only: a gallery photo is asked for as a compatible image (#59: an
  /// iPhone gallery photo is a HEIC).
  profilePhoto,

  /// Camera, gallery, or an image or PDF file: a leave document.
  document;

  /// The sources offered, in the order the sheet lists them.
  List<CaptureSource> get sources => switch (this) {
    cameraOnly => const [CaptureSource.camera],
    photo || profilePhoto || document => CaptureSource.values,
  };

  /// A PDF may be chosen as the file.
  bool get allowsPdf => this == document;

  /// A gallery photo must come as an image every browser shows (JPEG or
  /// PNG), not the phone's own format.
  bool get wantsCompatibleImage => this == profilePhoto;
}

/// How a pick ended.
sealed class CaptureResult {
  const CaptureResult();
}

/// A file was taken or chosen.
class Captured extends CaptureResult {
  const Captured(this.file);

  final LocalFile file;
}

/// The user backed out: nothing to do.
class CaptureCancelled extends CaptureResult {
  const CaptureCancelled();
}

/// The phone would not let the App use the camera or the photos. Nothing
/// reports it yet: `file_picker`'s gallery and file pickers need no
/// permission, and the camera screen says its own refusal.
class CaptureDenied extends CaptureResult {
  const CaptureDenied();
}

/// The picker failed for another reason: pick again.
class CaptureFailed extends CaptureResult {
  const CaptureFailed();
}
