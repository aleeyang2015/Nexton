import 'package:flutter/widgets.dart';
import 'package:next_on/core/upload/domain/capture_policy.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/presentation/file_capture.dart';

/// Records which source was used and answers with [answer].
class FakeFileCapture implements FileCapture {
  CaptureResult answer = const Captured(
    LocalFile(path: '/phone/IMG_0001.jpg', name: 'IMG_0001.jpg'),
  );

  /// `camera`, `gallery` or `file(pdf)` / `file`, in the order asked.
  final List<String> asked = [];

  @override
  Future<CaptureResult> takePhoto(BuildContext context) async {
    asked.add('camera');
    return answer;
  }

  @override
  Future<CaptureResult> pickPhoto() async {
    asked.add('gallery');
    return answer;
  }

  @override
  Future<CaptureResult> pickFile({required bool allowPdf}) async {
    asked.add(allowPdf ? 'file(pdf)' : 'file');
    return answer;
  }
}
