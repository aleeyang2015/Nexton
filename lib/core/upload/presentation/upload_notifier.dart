import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/failure.dart';
import '../domain/upload_error_code.dart';
import '../domain/capture_policy.dart';
import '../domain/local_file.dart';
import '../domain/uploaded_attachment.dart';
import '../upload_providers.dart';

/// One upload slot: nothing yet, uploading, done (the file the server
/// kept), or failed (why). A screen shows a thumbnail, a spinner or the
/// error from it.
class UploadState extends Equatable {
  const UploadState({this.uploading = false, this.file, this.failure});

  final bool uploading;

  /// The file the server accepted; kept through a later failed try.
  final UploadedAttachment? file;

  /// Why the last try failed; cleared by the next one.
  final Failure? failure;

  @override
  List<Object?> get props => [uploading, file, failure];
}

/// Uploads what was taken or picked into the folder this slot is for (the
/// family's argument, `UploadFolder`). A second upload while one is on its
/// way does nothing.
///
/// AutoDispose: leaving the screen drops the slot.
class UploadNotifier extends AutoDisposeFamilyNotifier<UploadState, String> {
  bool _disposed = false;

  @override
  UploadState build(String arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const UploadState();
  }

  /// What came back from the sheet: a file is uploaded, a refused
  /// permission is kept as the failure to show, a back-out changes nothing.
  Future<void> accept(CaptureResult result) async {
    switch (result) {
      case Captured(:final file):
        await upload(file);
      case CaptureDenied():
        if (state.uploading) return;
        state = UploadState(
          file: state.file,
          failure: const Failure.validation(
            message: UploadErrorCode.tokenPermissionDenied,
          ),
        );
      case CaptureFailed():
        if (state.uploading) return;
        state = UploadState(
          file: state.file,
          failure: const Failure.validation(
            message: UploadErrorCode.tokenInvalidFile,
          ),
        );
      case CaptureCancelled():
        break;
    }
  }

  Future<void> upload(LocalFile file) async {
    if (state.uploading) return;
    final kept = state.file;
    state = UploadState(uploading: true, file: kept);

    final result = await ref.read(uploadAttachmentUseCaseProvider)((
      file: file,
      folder: arg,
    ));
    if (_disposed) return;

    state = result.fold(
      (failure) => UploadState(file: kept, failure: failure),
      (uploaded) => UploadState(file: uploaded),
    );
  }

  /// Drops the file from the slot (the server keeps it).
  void clear() {
    if (state.uploading) return;
    state = const UploadState();
  }
}

final uploadNotifierProvider = NotifierProvider.autoDispose
    .family<UploadNotifier, UploadState, String>(UploadNotifier.new);
