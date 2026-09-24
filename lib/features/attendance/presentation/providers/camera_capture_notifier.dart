import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../time_off/domain/entities/local_file.dart';

/// Why the camera screen can't show a preview.
enum CameraCaptureError { unavailable, permissionDenied, failed }

/// The error [CameraCaptureNotifier] fails with, so the screen can pick its
/// message without reading plugin error codes itself.
class CameraCaptureFailure implements Exception {
  final CameraCaptureError reason;

  const CameraCaptureFailure(this.reason);
}

/// Owns the device camera for the capture screen: opens the back camera
/// (falling back to whichever there is), and releases it when the screen
/// goes away.
///
/// Photos only — audio is off, so no microphone permission is ever asked.
class CameraCaptureNotifier extends AutoDisposeAsyncNotifier<CameraController> {
  @override
  Future<CameraController> build() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (error) {
      throw CameraCaptureFailure(_reasonOf(error));
    }
    if (cameras.isEmpty) {
      throw const CameraCaptureFailure(CameraCaptureError.unavailable);
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    // `high` (720p) keeps a photo well under the form's 5 MB limit while
    // staying legible as evidence.
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    ref.onDispose(controller.dispose);

    try {
      await controller.initialize();
    } on CameraException catch (error) {
      throw CameraCaptureFailure(_reasonOf(error));
    }
    return controller;
  }

  /// Takes a photo, or returns null when the camera isn't ready or the
  /// capture failed.
  Future<LocalFile?> takePicture() async {
    final controller = state.valueOrNull;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }

    try {
      final shot = await controller.takePicture();
      // The plugin's temp name is opaque; this one is what the file row and
      // the upload's `original_name` show.
      final stamp = DateTime.now().millisecondsSinceEpoch;
      return LocalFile(path: shot.path, name: 'photo_$stamp.jpg');
    } on CameraException {
      return null;
    }
  }

  static CameraCaptureError _reasonOf(CameraException error) =>
      switch (error.code) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' => CameraCaptureError.permissionDenied,
        _ => CameraCaptureError.failed,
      };
}

final cameraCaptureNotifierProvider =
    AsyncNotifierProvider.autoDispose<CameraCaptureNotifier, CameraController>(
      CameraCaptureNotifier.new,
    );
