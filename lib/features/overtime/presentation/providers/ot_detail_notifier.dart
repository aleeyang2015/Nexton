import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';

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
    final result = await ref.read(getOtRequestUseCaseProvider)(arg);
    return result.fold((failure) => throw failure, (request) => request);
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
        return failure;
      },
      (request) {
        state = AsyncValue.data(request);
        return null;
      },
    );
  }

  /// Shows [request], an answer an action already gave (#32, #49), with no
  /// second request. A copy of another request is ignored.
  void replace(OtRequest request) {
    if (request.id != arg) return;
    _turn++;
    state = AsyncValue.data(request);
  }

  /// The request is gone, or no longer the caller's to see: the server
  /// answers `404` for both.
  static bool isGone(Object? error) =>
      error is NetworkFailure && error.statusCode == 404;
}

final otDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<OtDetailNotifier, OtRequest, String>(OtDetailNotifier.new);
