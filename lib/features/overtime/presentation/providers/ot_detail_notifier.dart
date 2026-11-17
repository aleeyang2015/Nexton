import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/ot_error_code.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';
import 'ot_list_notifier.dart';

/// One OT request, loaded by its id (`GET /ot-requests/:id`).
///
/// The request page reads it from here and not from the list it was opened
/// from, so it can be refreshed, and opened from a push that carries only
/// the id. A failure is the state's error, for the page to say what it is.
///
/// AutoDispose, so a sign-out drops it.
class OtDetailNotifier extends AutoDisposeFamilyAsyncNotifier<OtRequest, String> {
  bool _disposed = false;

  /// Counts what has been put on screen, so a late answer can tell it has
  /// been overtaken.
  int _turn = 0;

  @override
  Future<OtRequest> build(String arg) async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final turn = _turn;
    final result = await ref.read(getOtRequestUseCaseProvider)(arg);
    // A replace() or refresh() that ran while this first load was on its way
    // has already put something newer on screen: keep it.
    final shown = state.valueOrNull;
    if (turn != _turn && shown != null) return shown;
    return result.fold(
      (failure) {
        _syncList(gone: isGone(failure));
        throw failure;
      },
      (request) {
        _syncList(request: request);
        return request;
      },
    );
  }

  /// Keeps the OT list's row as this page last saw the request, when the
  /// list is open underneath: changed in place, or taken out when gone. The
  /// list then needs no reload when the user goes back, and keeps the pages
  /// already loaded.
  void _syncList({OtRequest? request, bool gone = false}) {
    if (_disposed || !ref.exists(otListNotifierProvider)) return;
    final list = ref.read(otListNotifierProvider.notifier);
    if (request != null) list.showRow(request);
    if (gone) list.dropRow(arg);
  }

  /// Loads the request again: a pull to refresh or a retry. Returns the
  /// failure when it failed, for the page to say so.
  ///
  /// The request on screen stays while the new one is on its way, and stays
  /// when the reload fails for want of signal: an old copy is better than
  /// none. A `404` (gone, or no longer the caller's to see) replaces it.
  Future<Failure?> refresh() async {
    final turn = ++_turn;
    final result = await ref.read(getOtRequestUseCaseProvider)(arg);
    if (_disposed || turn != _turn) return null;

    return result.fold(
      (failure) {
        if (!state.hasValue || isGone(failure)) {
          state = AsyncValue.error(failure, StackTrace.current);
        }
        _syncList(gone: isGone(failure));
        return failure;
      },
      (request) {
        state = AsyncValue.data(request);
        _syncList(request: request);
        return null;
      },
    );
  }

  bool _cancelling = false;

  /// Cancels the request (`PUT /ot-requests/:id/cancel`) and returns the
  /// server's answer, for the page to say what happened; null when a cancel
  /// was already on its way (a double tap sends one).
  ///
  /// On success the cancelled request the server sent back is shown at
  /// once. A refusal that means the page is out of date (already decided)
  /// or the request is gone (`404`) reloads it, so the buttons go, or the
  /// page learns it is gone.
  Future<Result<OtRequest>?> cancel() async {
    if (_cancelling) return null;
    _cancelling = true;
    try {
      final result = await ref.read(cancelOtUseCaseProvider)(arg);
      if (_disposed) return result;
      await result.fold(
        (failure) async {
          if (isGone(failure) || _isAlreadyDecided(failure)) await refresh();
        },
        (request) async => replace(request),
      );
      return result;
    } finally {
      _cancelling = false;
    }
  }

  static bool _isAlreadyDecided(Failure failure) =>
      failure is ValidationFailure &&
      failure.message == OtErrorCode.tokenAlreadyDecided;

  /// Shows [request], an answer an action already gave (#32, #49), with no
  /// second request. A copy of another request is ignored.
  void replace(OtRequest request) {
    if (request.id != arg) return;
    _turn++;
    state = AsyncValue.data(request);
    _syncList(request: request);
  }

  /// The request is gone, or no longer the caller's to see: the server
  /// answers `404` for both.
  static bool isGone(Object? error) =>
      error is NetworkFailure && error.statusCode == 404;
}

final otDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<OtDetailNotifier, OtRequest, String>(OtDetailNotifier.new);
