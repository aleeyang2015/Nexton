import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../domain/capture_policy.dart';
import '../domain/local_file.dart';

/// Takes a photo or picks a file. An interface, so a test uses a fake and
/// no platform plugin runs.
abstract class FileCapture {
  /// The App's own camera screen.
  Future<CaptureResult> takePhoto(BuildContext context);

  /// A photo from the phone's gallery.
  Future<CaptureResult> pickPhoto();

  /// A file: an image (`jpg`, `jpeg`, `png`), or a PDF too when
  /// [allowPdf].
  Future<CaptureResult> pickFile({required bool allowPdf});
}

/// The real one: the App's in-app camera screen (opened by [openCamera], as
/// the App's router knows it) and `file_picker` for the gallery and files.
///
/// Photos are not shrunk (no extra package): the camera shoots 720p JPEGs,
/// well under the limit, and a chosen photo or file is held to it by the
/// upload's size check.
class FilePickerCapture implements FileCapture {
  const FilePickerCapture({required this.openCamera});

  final Future<LocalFile?> Function(BuildContext context) openCamera;

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];

  @override
  Future<CaptureResult> takePhoto(BuildContext context) async {
    final file = await openCamera(context);
    return file == null ? const CaptureCancelled() : Captured(file);
  }

  @override
  Future<CaptureResult> pickPhoto() => _pick(type: FileType.image);

  @override
  Future<CaptureResult> pickFile({required bool allowPdf}) => _pick(
    type: FileType.custom,
    extensions: [...imageExtensions, if (allowPdf) 'pdf'],
  );

  Future<CaptureResult> _pick({
    required FileType type,
    List<String>? extensions,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: extensions,
      );
      final file = result?.files.singleOrNull;
      final path = file?.path;
      if (file == null || path == null) return const CaptureCancelled();
      return Captured(LocalFile(path: path, name: file.name));
    } on PlatformException catch (error) {
      return resultOf(error);
    }
  }

  /// What a `file_picker` error means for the user. A picker already open
  /// (`already_active` on Android, `multiple_request` on iOS: a second tap)
  /// is a back-out; any other (`unknown_path`, `file_picker_error`, …) is
  /// "pick again". Never thrown on to the screen.
  static CaptureResult resultOf(PlatformException error) =>
      switch (error.code) {
        'already_active' || 'multiple_request' => const CaptureCancelled(),
        _ => const CaptureFailed(),
      };
}
