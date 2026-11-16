import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../time_off/domain/entities/local_file.dart';
import '../../../time_off/domain/entities/uploaded_attachment.dart';
import '../../../time_off/presentation/services/attachment_picker.dart';
import '../../../time_off/time_off_providers.dart';

/// Why a picked attachment was turned away before upload.
enum TimeCorrectionAttachmentError { tooLarge }

/// An evidence file the backend has accepted: the [uploaded] record submit
/// sends, and the [local] copy on the device the form previews from — the
/// upload's `url` may point at a host the phone can't reach.
class TimeCorrectionEvidence extends Equatable {
  final LocalFile local;
  final UploadedAttachment uploaded;

  const TimeCorrectionEvidence({required this.local, required this.uploaded});

  @override
  List<Object?> get props => [local, uploaded];
}

/// Holds the evidence file of the time-correction form — same workflow as the
/// leave form's [LeaveAttachmentNotifier]: the file is uploaded
/// (`POST /uploads`) the moment it is picked, and the accepted attachment is
/// what [TimeCorrectionFormNotifier.submit] sends as `attachment_url`.
///
/// The value is the file the backend has accepted, or null. A failed
/// upload surfaces as [AsyncError] while the previous value is kept.
class TimeCorrectionAttachmentNotifier
    extends AutoDisposeAsyncNotifier<TimeCorrectionEvidence?> {
  /// File types the correction form accepts, per the design: images and PDF.
  static const extensions = ['jpg', 'jpeg', 'png', 'pdf'];

  /// Largest file the form accepts, in bytes (5 MB).
  static const int maxBytes = 5 * 1024 * 1024;

  @override
  FutureOr<TimeCorrectionEvidence?> build() => null;

  /// Opens the file chooser, then [upload]s the pick. A back-out changes
  /// nothing and returns null.
  Future<TimeCorrectionAttachmentError?> pickAndUpload() async {
    if (state.isLoading) return null;

    final picked = await ref
        .read(attachmentPickerProvider)
        .pickAttachment(extensions: extensions);
    if (picked == null) return null;

    return upload(picked);
  }

  /// Uploads [picked] — from the file chooser or the camera — and keeps it
  /// (replacing any previous one). Returns
  /// [TimeCorrectionAttachmentError.tooLarge] for a file over [maxBytes],
  /// which is never uploaded; null otherwise.
  Future<TimeCorrectionAttachmentError?> upload(LocalFile picked) async {
    if (state.isLoading) return null;

    if (await File(picked.path).length() > maxBytes) {
      return TimeCorrectionAttachmentError.tooLarge;
    }

    final previous = state.valueOrNull;
    state = const AsyncValue<TimeCorrectionEvidence?>.loading()
        .copyWithPrevious(state);

    final result = await ref.read(uploadAttachmentUseCaseProvider)(picked);

    state = result.fold(
      (failure) => AsyncValue<TimeCorrectionEvidence?>.error(
        failure,
        StackTrace.current,
      ).copyWithPrevious(AsyncValue.data(previous)),
      (uploaded) => AsyncValue.data(
        TimeCorrectionEvidence(local: picked, uploaded: uploaded),
      ),
    );
    return null;
  }

  /// Drops the attachment locally. Does not delete it server-side — that
  /// endpoint is out of scope here.
  void clear() => state = const AsyncValue.data(null);
}

final timeCorrectionAttachmentNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      TimeCorrectionAttachmentNotifier,
      TimeCorrectionEvidence?
    >(TimeCorrectionAttachmentNotifier.new);
