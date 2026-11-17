import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../data/datasources/offsite_error_code.dart';
import '../../domain/entities/offsite_detail.dart';
import 'attendance_notifier.dart';
import 'offsite_history_notifier.dart';

/// One of the employee's off-site requests, loaded by its id
/// (`GET /offsite-requests/:id`, #42), and its withdrawal.
class OffsiteDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<OffsiteRequestDetail, String> {
  bool _disposed = false;

  /// Counts what has been put on screen, so a late answer can tell it has
  /// been overtaken.
  int _turn = 0;
  bool _cancelling = false;

  @override
  Future<OffsiteRequestDetail> build(String arg) async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final result = await ref.read(getOffsiteDetailUseCaseProvider)(arg);
    return result.fold((failure) => throw failure, (request) => request);
  }

  /// Loads it again: a pull to refresh, after a withdrawal. The request on
  /// screen stays while it loads; a failure is returned for the page to say,
  /// and replaces it only when the request is gone.
  Future<Failure?> refresh() async {
    final turn = ++_turn;
    final result = await ref.read(getOffsiteDetailUseCaseProvider)(arg);
    if (_disposed || turn != _turn) return null;
    return result.fold(
      (failure) {
        if (!state.hasValue || _isGone(failure)) {
          state = AsyncValue.error(failure, StackTrace.current);
        }
        return failure;
      },
      (request) {
        state = AsyncValue.data(request);
        return null;
      },
    );
  }

  /// Withdraws it (`PUT /offsite-requests/:id/cancel`). Either way it is
  /// loaded again: on success to show it cancelled, on `CANNOT_CANCEL`
  /// because it was decided meanwhile. The list behind it and today's card
  /// (#41: a waiting check-in) are read again too. One at a time.
  Future<Result<Unit>> cancel() async {
    if (_cancelling) return const Result.success(Unit.instance);
    _cancelling = true;
    try {
      final result = await ref.read(cancelOffsiteRequestUseCaseProvider)(arg);
      if (_disposed) return result;
      await refresh();
      if (ref.exists(offsiteHistoryNotifierProvider)) {
        ref.read(offsiteHistoryNotifierProvider.notifier).refresh();
      }
      if (ref.exists(attendanceNotifierProvider)) {
        ref.read(attendanceNotifierProvider.notifier).loadToday();
      }
      return result;
    } finally {
      _cancelling = false;
    }
  }

  /// The answer that means it is gone, or not the caller's to see.
  static bool _isGone(Failure failure) => failure.maybeWhen(
    validation: (message, _, _) => message == OffsiteErrorCode.tokenRequestGone,
    orElse: () => false,
  );

  static bool isGone(Object? error) => error is Failure && _isGone(error);
}

final offsiteDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<OffsiteDetailNotifier, OffsiteRequestDetail, String>(
      OffsiteDetailNotifier.new,
    );
