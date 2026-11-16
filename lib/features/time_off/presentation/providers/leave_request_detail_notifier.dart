import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_request.dart';
import '../../time_off_providers.dart';

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
    final result = await ref.read(getLeaveRequestDetailUseCaseProvider)(arg);
    // The page may have been closed meanwhile.
    if (_disposed) return null;

    return result.fold(
      (failure) {
        if (!state.hasValue || LeaveErrorCode.isRequestGone(failure)) {
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

  Future<LeaveRequest> _load() async {
    final result = await ref.read(getLeaveRequestDetailUseCaseProvider)(arg);
    return result.fold((failure) => throw failure, (request) => request);
  }
}

final leaveRequestDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<LeaveRequestDetailNotifier, LeaveRequest, String>(
      LeaveRequestDetailNotifier.new,
    );
