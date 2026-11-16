import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_request.dart';
import '../../time_off_providers.dart';
import 'leave_balances_notifier.dart';
import 'leave_history_notifier.dart';
import 'leave_pending_request_notifier.dart';

/// One leave request, loaded by its id (`GET /leave/requests/:id`).
///
/// The request page reads it from here and not from the list it was opened
/// from, so the page can be refreshed, and can be opened from a link or a
/// push that carries only the id. A failure is kept as the state's error,
/// for the page to say what it is ("no longer exists", no signal).
class LeaveRequestDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<LeaveRequest, String> {
  bool _disposed = false;

  @override
  Future<LeaveRequest> build(String arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return _load();
  }

  /// Loads the request again: a pull to refresh, a retry, or after an edit,
  /// a cancel or a refusal that said the page was out of date.
  ///
  /// The request on screen stays there while the new one is on its way.
  /// Returns the failure when the reload failed, for the page to say so.
  ///
  /// A reload that fails for want of signal leaves the request already
  /// shown in place: an old copy is better than none. One that says the
  /// request is gone replaces it, as there is nothing to show any more.
  Future<Failure?> refresh() async {
    final turn = ++_turn;
    final result = await ref.read(getLeaveRequestDetailUseCaseProvider)(arg);
    // The page may have been closed meanwhile, or something newer (a later
    // refresh, a cancel) has already been shown: an older answer arriving
    // late must not put the old request back.
    if (_disposed || turn != _turn) return null;

    return result.fold(
      (failure) {
        if (!state.hasValue || LeaveErrorCode.isRequestGone(failure)) {
          state = AsyncValue.error(failure, StackTrace.current);
        }
        return failure;
      },
      (request) {
        _show(request);
        return null;
      },
    );
  }

  /// Counts what has been put on screen, so a late answer can tell it has
  /// been overtaken.
  int _turn = 0;

  /// Cancels the request (`PUT /leave/requests/:id/cancel`) and returns the
  /// server's answer, for the page to say what happened.
  ///
  /// On success the page shows the cancelled request the server sent back,
  /// at once: it does not wait on a reload that could fail and leave
  /// "pending" on screen under a "cancelled" message. A refusal that means
  /// the page is out of date (the request changed, was decided, has started,
  /// or is gone) reloads it.
  Future<Result<LeaveRequest>> cancel() async {
    final result = await ref.read(cancelLeaveRequestUseCaseProvider)(arg);
    if (_disposed) return result;

    await result.fold(
      (failure) async {
        if (LeaveErrorCode.isStaleForOwner(failure)) await refresh();
      },
      (request) async {
        _turn++;
        _show(request);
      },
    );
    return result;
  }

  /// Puts [request] on screen. When its status is not the one shown before,
  /// what the other leave screens hold is out of date too: the history, the
  /// balances, and whether a request is still waiting.
  void _show(LeaveRequest request) {
    final before = state.valueOrNull?.status;
    state = AsyncValue.data(request);

    if (before != null && before != request.status) {
      // Only the ones a screen is showing: a page opened from a push has no
      // history list behind it to reload.
      if (ref.exists(leaveHistoryNotifierProvider)) {
        ref.invalidate(leaveHistoryNotifierProvider);
      }
      ref.invalidate(leaveBalancesNotifierProvider);
      if (ref.exists(leavePendingRequestNotifierProvider)) {
        ref.invalidate(leavePendingRequestNotifierProvider);
      }
    }
  }

  Future<LeaveRequest> _load() async {
    final result = await ref.read(getLeaveRequestDetailUseCaseProvider)(arg);
    return result.fold((failure) => throw failure, (request) => request);
  }
}

final leaveRequestDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<LeaveRequestDetailNotifier, LeaveRequest, String>(
      LeaveRequestDetailNotifier.new,
    );
