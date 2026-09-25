import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance_providers.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../services/attachment_file_saver.dart';
import '../widgets/time_correction_detail_copy.dart';
import 'time_correction_detail_state.dart';

/// How saving the evidence file ended.
enum AttachmentSaveOutcome { saved, dismissed, failed }

/// One time-correction request's detail page, keyed by the request id:
/// loads it, cancels it, and saves its evidence file to the device.
class TimeCorrectionDetailNotifier
    extends AutoDisposeFamilyNotifier<TimeCorrectionDetailState, String> {
  bool _disposed = false;

  @override
  TimeCorrectionDetailState build(String id) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return const TimeCorrectionDetailState();
  }

  /// Refetches the request. What is already shown stays while it loads.
  Future<void> refresh() async {
    state = state.copyWith(
      detail: const AsyncLoading<TimeCorrectionDetail>().copyWithPrevious(
        state.detail,
      ),
    );

    final result = await ref.read(getTimeCorrectionDetailUseCaseProvider)(arg);
    if (_disposed) return;

    state = state.copyWith(
      detail: result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        AsyncValue.data,
      ),
    );
  }

  /// Withdraws the request. Returns whether it went through.
  Future<bool> cancel() async {
    if (state.cancelling) return false;
    state = state.copyWith(cancelling: true);

    final result = await ref.read(cancelTimeCorrectionUseCaseProvider)(arg);
    if (_disposed) return result.isSuccess;

    state = state.copyWith(cancelling: false);
    return result.isSuccess;
  }

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
