import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../data/datasources/correction_error_code.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../services/attachment_file_saver.dart';
import '../widgets/time_correction_detail_copy.dart';
import 'time_correction_detail_state.dart';
import 'time_correction_history_notifier.dart';

/// How saving the evidence file ended.
enum AttachmentSaveOutcome { saved, dismissed, failed }

/// One time-correction request's detail page, keyed by the request id
/// (`GET correction-requests/:id`, #45): loads it, withdraws it, and saves
/// its evidence file to the device.
class TimeCorrectionDetailNotifier
    extends AutoDisposeFamilyNotifier<TimeCorrectionDetailState, String> {
  bool _disposed = false;

  /// Counts the loads started, so a late answer can tell it has been
  /// overtaken by a newer one.
  int _turn = 0;

  @override
  TimeCorrectionDetailState build(String id) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return const TimeCorrectionDetailState();
  }

  /// Loads it again: the first load, a pull to refresh, a Retry, after a
  /// withdrawal. The request on screen stays while it loads. A failure is
  /// returned for the page to say, and replaces the request only when there
  /// is none yet or it is gone.
  Future<Failure?> refresh() async {
    final turn = ++_turn;
    state = state.copyWith(
      detail: const AsyncLoading<TimeCorrectionDetail>().copyWithPrevious(
        state.detail,
      ),
    );

    final result = await ref.read(getTimeCorrectionDetailUseCaseProvider)(arg);
    if (_disposed || turn != _turn) return null;

    return result.fold(
      (failure) {
        final error = AsyncValue<TimeCorrectionDetail>.error(
          failure,
          StackTrace.current,
        );
        state = state.copyWith(
          detail: isGone(failure) ? error : error.copyWithPrevious(state.detail),
        );
        return failure;
      },
      (detail) {
        state = state.copyWith(detail: AsyncValue.data(detail));
        return null;
      },
    );
  }

  /// Withdraws it (`PUT correction-requests/:id/cancel`). Either way it is
  /// loaded again: on success to show it cancelled, on `CANNOT_CANCEL`
  /// because it was decided meanwhile. The list behind it is read again
  /// too. One at a time.
  ///
  /// Null when a withdrawal is already on its way: that one's answer is the
  /// one to tell (never a "cancelled" the server did not give).
  Future<Result<Unit>?> cancel() async {
    if (state.cancelling) return null;
    state = state.copyWith(cancelling: true);
    try {
      final result = await ref.read(cancelTimeCorrectionUseCaseProvider)(arg);
      if (_disposed) return result;
      await refresh();
      if (ref.exists(timeCorrectionHistoryNotifierProvider)) {
        ref.read(timeCorrectionHistoryNotifierProvider.notifier).refresh();
      }
      return result;
    } finally {
      if (!_disposed) state = state.copyWith(cancelling: false);
    }
  }

  /// The answer that means it is gone, or not the caller's to see.
  static bool isGone(Object? error) =>
      error is ValidationFailure &&
      error.message == CorrectionErrorCode.tokenRequestGone;

  /// Downloads the evidence file and offers it for saving.
  Future<AttachmentSaveOutcome> saveAttachment() async {
    final url = state.detail.valueOrNull?.attachmentUrl;
    if (url == null || state.downloading) return AttachmentSaveOutcome.failed;
    state = state.copyWith(downloading: true);

    final result = await ref.read(
      downloadTimeCorrectionAttachmentUseCaseProvider,
    )(url);
    if (_disposed) return AttachmentSaveOutcome.dismissed;

    final bytes = result.dataOrNull;
    if (bytes == null || bytes.isEmpty) {
      state = state.copyWith(downloading: false);
      return AttachmentSaveOutcome.failed;
    }

    try {
      final path = await ref
          .read(attachmentFileSaverProvider)
          .save(bytes, fileName: TimeCorrectionDetailCopy.fileName(url));
      return path == null
          ? AttachmentSaveOutcome.dismissed
          : AttachmentSaveOutcome.saved;
    } catch (_) {
      return AttachmentSaveOutcome.failed;
    } finally {
      if (!_disposed) state = state.copyWith(downloading: false);
    }
  }
}

final timeCorrectionDetailNotifierProvider = NotifierProvider.autoDispose
    .family<TimeCorrectionDetailNotifier, TimeCorrectionDetailState, String>(
      TimeCorrectionDetailNotifier.new,
    );
