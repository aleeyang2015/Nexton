import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/upload/domain/capture_policy.dart';
import 'package:next_on/core/upload/presentation/file_capture.dart';

/// What the picker was asked for, and what it answers.
class _Picker {
  _Picker([this.answer]);

  final FilePickerResult? answer;
  FileType? type;
  List<String>? extensions;
  int? quality;

  Future<FilePickerResult?> call({
    required FileType type,
    List<String>? allowedExtensions,
    required int compressionQuality,
  }) async {
    this.type = type;
    extensions = allowedExtensions;
    quality = compressionQuality;
    return answer;
  }
}

FilePickerCapture _capture(_Picker picker, {required bool isIOS}) =>
    FilePickerCapture(
      openCamera: (_) async => null,
      pickFiles: picker.call,
      isIOS: isIOS,
    );

/// The gallery and the file chooser (#59: an iPhone gallery photo is a
/// HEIC, which the photo uploads refuse).
void main() {
  test('iPhone gallery: asks iOS for the compatible version (a JPEG, not '
      'the HEIC original)', () async {
    final picker = _Picker();

    await _capture(picker, isIOS: true).pickPhoto();

    expect(picker.type, FileType.image);
    expect(picker.quality, greaterThan(0));
  });

  test('Android gallery: the original file, never re-encoded (that would '
      'drop its rotation)', () async {
    final picker = _Picker();

    await _capture(picker, isIOS: false).pickPhoto();

    expect(picker.type, FileType.image);
    expect(picker.quality, 0);
  });

  test('a file, on either: the original, with the same extensions as '
      'before', () async {
    for (final isIOS in [true, false]) {
      final picker = _Picker();

      await _capture(picker, isIOS: isIOS).pickFile(allowPdf: true);

      expect(picker.type, FileType.custom);
      expect(picker.quality, 0);
      expect(picker.extensions, ['jpg', 'jpeg', 'png', 'pdf']);
    }
  });

  test('a cancelled pick is cancelled; a picked one comes back with its '
      'path and name', () async {
    expect(
      await _capture(_Picker(), isIOS: true).pickPhoto(),
      isA<CaptureCancelled>(),
    );

    final picked = _Picker(
      FilePickerResult([
        PlatformFile(
          path: '/tmp/IMG_0001.jpeg',
          name: 'IMG_0001.jpeg',
          size: 1,
        ),
      ]),
    );
    final result = await _capture(picked, isIOS: true).pickPhoto();

    expect(result, isA<Captured>());
    final file = (result as Captured).file;
    expect(file.path, '/tmp/IMG_0001.jpeg');
    expect(file.name, 'IMG_0001.jpeg');
  });
}
