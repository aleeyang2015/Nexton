import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/ot_error_code.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';
import 'ot_approvals_notifier.dart';
import 'ot_detail_notifier.dart';

/// Where a head's action on one OT request stands (#49).
class OtDecisionState {
  const OtDecisionState({
    this.deciding = false,
    this.cancelHidden = false,
    this.notMine = false,
  });

  /// An approve, reject or cancel is on its way: the buttons are off.
  final bool deciding;

  /// A cancel the server will keep refusing: the OT has begun
  /// (`OT_STARTED`, only HR can now), or it is paid (`OT_ALREADY_PAID`,
  /// `OT_PAID_BY_HAND`). Cancel goes.
  final bool cancelHidden;

  /// `NOT_APPROVER`: the step is not this head's after all. Approve and
  /// Reject go, even when a reload shows the same request again.
  final bool notMine;

  OtDecisionState copyWith({
    bool? deciding,
    bool? cancelHidden,
    bool? notMine,
  }) => OtDecisionState(
    deciding: deciding ?? this.deciding,
    cancelHidden: cancelHidden ?? this.cancelHidden,
    notMine: notMine ?? this.notMine,
  );
}

/// A head's approve, reject or cancel on one OT request, by its id (#49),
/// from its row on the approvals tab or from its page: one at a time,
/// wherever it was tapped.
///
/// A success shows the request the server sent back on its page, takes it
/// out of the waiting list at once and reads both lists again (not waited
/// on). A failure keeps the row: a refusal that means the request moved on
/// (the step changed, already decided, not my step) reads the lists and
/// the page again; `OT_STARTED` takes Cancel away; a `404` reads the lists
/// again (the page says "not available").
class OtDecisionNotifier
    extends AutoDisposeFamilyNotifier<OtDecisionState, String> {
  bool _disposed = false;

  @override
  OtDecisionState build(String arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const OtDecisionState();
  }

  /// Approves the waiting step with [comment] when one was typed. Null when
  /// an action is already on its way: that one's answer is the one to tell.
  Future<Result<OtRequest>?> approve(OtRequest request, {String? comment}) {
    final step = request.pendingStep;
    if (step == null) return Future.value(null);
    final trimmed = comment?.trim();
    return _run(
      () => ref
          .read(decideOtUseCaseProvider)
          .approve(
            request.id,
            stepId: step.id,
            comment: trimmed == null || trimmed.isEmpty ? null : trimmed,
          ),
    );
  }

  /// Rejects the waiting step with [reason], what the employee is told.
  Future<Result<OtRequest>?> reject(OtRequest request, String reason) {
    final step = request.pendingStep;
    if (step == null) return Future.value(null);
    return _run(
      () => ref
          .read(decideOtUseCaseProvider)
          .reject(request.id, stepId: step.id, comment: reason),
    );
  }

  /// Cancels the approved OT before it starts (`PUT .../cancel`, the same
  /// call the employee's own cancel uses).
  Future<Result<OtRequest>?> cancelApproved(OtRequest request) =>
      _run(() => ref.read(cancelOtUseCaseProvider)(request.id));

  Future<Result<OtRequest>?> _run(
    Future<Result<OtRequest>> Function() action,
  ) async {
    if (state.deciding) return null;
    state = state.copyWith(deciding: true);
    // Kept until the answer is handled: the head may go back while it is
    // on its way, and the list underneath must still be read again.
    final keep = ref.keepAlive();
    try {
      final result = await action();
      await result.fold(
        (failure) async {
          final token = _tokenOf(failure);
          if (_cancelRefused.contains(token)) {
            if (!_disposed) state = state.copyWith(cancelHidden: true);
          } else if (_stale.contains(token)) {
            if (token == OtErrorCode.tokenNotApprover && !_disposed) {
              state = state.copyWith(notMine: true);
            }
            _reloadLists();
            await _reloadPage();
          } else if (OtDetailNotifier.isGone(failure)) {
            _reloadLists();
          }
        },
        (request) async {
          final page = otDetailNotifierProvider(arg);
          if (!_disposed && ref.exists(page)) {
            ref.read(page.notifier).replace(request);
          }
          _leaveWaiting();
        },
      );
      return result;
    } finally {
      if (!_disposed) state = state.copyWith(deciding: false);
      keep.close();
    }
  }

  /// The cancels the server will keep refusing.
  static const Set<String> _cancelRefused = {
    OtErrorCode.tokenStarted,
    OtErrorCode.tokenAlreadyPaid,
    OtErrorCode.tokenPaidByHand,
  };

  /// The refusals that mean the request moved on without this head.
  static const Set<String> _stale = {
    OtErrorCode.tokenStepChanged,
    OtErrorCode.tokenAlreadyDecided,
    OtErrorCode.tokenNotApprover,
  };

  static String? _tokenOf(Failure failure) => switch (failure) {
    ValidationFailure(:final message) => message,
    _ => null,
  };

  void _leaveWaiting() {
    if (_disposed || !ref.exists(otApprovalsNotifierProvider)) return;
    final lists = ref.read(otApprovalsNotifierProvider.notifier);
    lists.dropWaiting(arg);
    unawaited(lists.refresh());
  }

  void _reloadLists() {
    if (_disposed || !ref.exists(otApprovalsNotifierProvider)) return;
    unawaited(ref.read(otApprovalsNotifierProvider.notifier).refresh());
  }

  Future<void> _reloadPage() async {
    final page = otDetailNotifierProvider(arg);
    if (_disposed || !ref.exists(page)) return;
    await ref.read(page.notifier).refresh();
  }
}

final otDecisionNotifierProvider = NotifierProvider.autoDispose
    .family<OtDecisionNotifier, OtDecisionState, String>(
      OtDecisionNotifier.new,
    );
