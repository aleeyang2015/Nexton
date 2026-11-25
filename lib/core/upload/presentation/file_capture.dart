import 'dart:io' show Platform;

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

  /// A photo from the phone's gallery. With [compatible], one every
  /// browser shows (a JPEG for an iPhone's HEIC), where the phone can say.
  Future<CaptureResult> pickPhoto({bool compatible = false});

  /// A file: an image (`jpg`, `jpeg`, `png`), or a PDF too when
  /// [allowPdf].
  Future<CaptureResult> pickFile({required bool allowPdf});
}

/// Opens the phone's chooser: `file_picker`'s `FilePicker.pickFiles`, with
/// only the options the App sets.
typedef PickFiles =
    Future<FilePickerResult?> Function({
      required FileType type,
      List<String>? allowedExtensions,
      required int compressionQuality,
    });

Future<FilePickerResult?> _filePicker({
  required FileType type,
  List<String>? allowedExtensions,
  required int compressionQuality,
}) => FilePicker.pickFiles(
  type: type,
  allowedExtensions: allowedExtensions,
  compressionQuality: compressionQuality,
);

/// The real one: the App's in-app camera screen (opened by [openCamera], as
/// the App's router knows it) and `file_picker` for the gallery and files.
///
/// Photos are not shrunk (no extra package): the camera shoots 720p JPEGs,
/// well under the limit, and a chosen photo or file is held to it by the
/// upload's size check.
class FilePickerCapture implements FileCapture {
  const FilePickerCapture({
    required this.openCamera,
    PickFiles? pickFiles,
    bool? isIOS,
  }) : _pickFiles = pickFiles,
       _isIOS = isIOS;

  final Future<LocalFile?> Function(BuildContext context) openCamera;

  /// `file_picker`'s chooser; a test passes its own.
  final PickFiles? _pickFiles;

  /// Whether this is an iPhone; a test says which.
  final bool? _isIOS;

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];

  @override
  Future<CaptureResult> takePhoto(BuildContext context) async {
    final file = await openCamera(context);
    return file == null ? const CaptureCancelled() : Captured(file);
  }

  /// An iPhone gallery photo is usually a HEIC, which the profile photo's
  /// upload refuses (#59). Any value above 0 makes `file_picker` ask iOS's
  /// photo picker for the photo's compatible version
  /// (`PHPickerConfigurationAssetRepresentationModeCompatible`): iOS hands
  /// over a JPEG, turned the right way up; the number is not used there.
  /// Only when [pickPhoto] is asked for it: the JPEG is bigger than the
  /// HEIC, and the other uploads take a HEIC as it is. Android always
  /// keeps 0, the original file: there the plugin would re-encode the whole
  /// photo in memory and drop its rotation.
  static const int iosCompatibleQuality = 100;

  @override
  Future<CaptureResult> pickPhoto({bool compatible = false}) => _pick(
    type: FileType.image,
    compressionQuality: compatible && (_isIOS ?? Platform.isIOS)
        ? iosCompatibleQuality
        : 0,
  );

  @override
  Future<CaptureResult> pickFile({required bool allowPdf}) => _pick(
    type: FileType.custom,
    extensions: [...imageExtensions, if (allowPdf) 'pdf'],
  );

  Future<CaptureResult> _pick({
    required FileType type,
    List<String>? extensions,
    int compressionQuality = 0,
  }) async {
    try {
      final pick = _pickFiles ?? _filePicker;
      final result = await pick(
        type: type,
        allowedExtensions: extensions,
        compressionQuality: compressionQuality,
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
