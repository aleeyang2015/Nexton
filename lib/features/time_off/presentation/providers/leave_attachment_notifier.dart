import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/uploaded_attachment.dart';
import '../../time_off_providers.dart';
import '../services/attachment_picker.dart';

/// Holds the file uploaded from the leave form's "attach file" slot for one
/// form instance (family key = the request id being edited, or `null` for a
/// new request — same keying as [leaveRequestFormNotifierProvider]).
///
/// The value is the single attachment the backend has accepted, or null. It is
/// read back by [LeaveRequestFormNotifier.submit] and folded into the request
/// body's `attachments` (leave-request-flutter.md §3.3).
class LeaveAttachmentNotifier
    extends FamilyAsyncNotifier<UploadedAttachment?, String?> {
  @override
  FutureOr<UploadedAttachment?> build(String? arg) => null;

  /// Opens the file chooser, uploads the pick (`POST /uploads`) and stores the
  /// accepted attachment (replacing any previous one). A back-out is a no-op; a
  /// failed upload surfaces as [AsyncError] while the previous value is kept.
  Future<void> pickAndUpload() async {
    if (state.isLoading) return;

    final picked = await ref.read(attachmentPickerProvider).pickAttachment();
    if (picked == null) return;

    final previous = state.valueOrNull;
    state = const AsyncValue<UploadedAttachment?>.loading().copyWithPrevious(
      state,
    );

    final result = await ref.read(uploadAttachmentUseCaseProvider)(picked);

    state = result.fold(
      (failure) => AsyncValue<UploadedAttachment?>.error(
        failure,
        StackTrace.current,
      ).copyWithPrevious(AsyncValue.data(previous)),
      (uploaded) => AsyncValue.data(uploaded),
    );
  }

  /// Drops the attachment locally. Does not delete it server-side — that
  /// endpoint is out of scope here.
  void clear() => state = const AsyncValue.data(null);
}

final leaveAttachmentNotifierProvider =
    AsyncNotifierProvider.family<
      LeaveAttachmentNotifier,
      UploadedAttachment?,
      String?
    >(LeaveAttachmentNotifier.new);
