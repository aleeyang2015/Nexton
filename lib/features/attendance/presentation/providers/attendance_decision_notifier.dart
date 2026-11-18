import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../data/datasources/approval_decision_code.dart';
import '../../domain/entities/attendance_approval_request.dart';
import 'attendance_approvals_lists.dart';

/// Where a decision on one attendance request stands (#46, #47).
class AttendanceDecisionState {
  const AttendanceDecisionState({
    this.deciding = false,
    this.rejectOnly = false,
    this.notMine = false,
  });

  /// A decision is on its way: the buttons are off.
  final bool deciding;

  /// The request can only be rejected now (an off-site check-out whose
  /// check-in was turned down).
  final bool rejectOnly;

  /// `NOT_APPROVER`: the step is not this approver's after all; no buttons.
  final bool notMine;

  AttendanceDecisionState copyWith({
    bool? deciding,
    bool? rejectOnly,
    bool? notMine,
  }) => AttendanceDecisionState(
    deciding: deciding ?? this.deciding,
    rejectOnly: rejectOnly ?? this.rejectOnly,
    notMine: notMine ?? this.notMine,
  );
}

/// Approve or reject one attendance request, by its id, from its row or
/// its own page: one decision at a time for the request, wherever it was
/// tapped. Each kind of request says how it is decided and where its lists
/// and page are.
///
/// A decision, or a refusal that means the request moved on (decided by
/// someone else, the step changed, gone), takes it out of the waiting list
/// at once and reads the lists again (not waited on). After a refusal the
/// request's page is read again; after a decision too when the page stays
/// ([staysAfterDecision]). `NOT_APPROVER` leaves no buttons; the kind's
/// [rejectOnlyToken] leaves Reject only. Both marks are kept on the list
/// too, so the row and the page agree.
abstract class AttendanceDecisionNotifier<T extends AttendanceApprovalRequest>
    extends AutoDisposeFamilyNotifier<AttendanceDecisionState, String> {
  bool _disposed = false;

  /// The approve and reject calls.
  FutureResult<Unit> approveCall(T request, String? note);
  FutureResult<Unit> rejectCall(T request, String reason);

  /// The tab's lists.
  AutoDisposeNotifierProvider<
    AttendanceApprovalsNotifier<T>,
    AttendanceApprovalsState<T>
  >
  get listsProvider;

  /// Reads the request's page again, when it is open.
  Future<void> reloadPage();

  /// The refusals that mean the request moved on: the shared ones and this
  /// kind's "gone".
  Set<String> get staleTokens;

  /// A refusal after which only Reject is left; none by default.
  String? get rejectOnlyToken => null;

  /// Whether the request's page stays after a decision (and is read again)
  /// rather than going back to the list.
  bool get staysAfterDecision => false;

  @override
  AttendanceDecisionState build(String arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // What a refusal from the row left, for the request's page opened from
    // it. Read, not watched: the page never loads the list itself.
    if (!ref.exists(listsProvider)) return const AttendanceDecisionState();
    final lists = ref.read(listsProvider);
    return AttendanceDecisionState(
      rejectOnly: lists.rejectOnlyIds.contains(arg),
      notMine: lists.notMineIds.contains(arg),
    );
  }

  /// Approves the waiting step, with [note] when one was typed. Null when a
  /// decision is already on its way: that one's answer is the one to tell.
  Future<Result<Unit>?> approve(T request, {String? note}) {
    final trimmed = note?.trim();
    return _decide(
      request,
      () => approveCall(
        request,
        trimmed == null || trimmed.isEmpty ? null : trimmed,
      ),
    );
  }

  /// Rejects the waiting step with [reason], what the employee is told.
  Future<Result<Unit>?> reject(T request, String reason) =>
      _decide(request, () => rejectCall(request, reason));

  Future<Result<Unit>?> _decide(
    T request,
    Future<Result<Unit>> Function() action,
  ) async {
    if (state.deciding) return null;
    state = state.copyWith(deciding: true);
    // Kept until the answer is handled: the approver may go back while it
    // is on its way, and the list underneath must still be read again.
    final keep = ref.keepAlive();
    try {
      final result = await action();
      final failure = result.failureOrNull;
      if (failure == null) {
        _leaveWaiting();
        if (staysAfterDecision) await _reloadPage();
        return result;
      }
      final token = _tokenOf(failure);
      if (token != null && token == rejectOnlyToken) {
        _mark(rejectOnly: true);
      } else if (token == ApprovalDecisionCode.tokenAnotherApprover) {
        _mark(notMine: true);
      } else if (staleTokens.contains(token)) {
        _leaveWaiting();
        await _reloadPage();
      }
      return Result.failure(_said(failure, token, request));
    } finally {
      if (!_disposed) state = state.copyWith(deciding: false);
      keep.close();
    }
  }

  /// `NOT_APPROVER` on the approver's own request says "your own".
  Failure _said(Failure failure, String? token, T request) {
    if (token != ApprovalDecisionCode.tokenAnotherApprover) return failure;
    final user = ref.read(authSessionProvider).valueOrNull?.user;
    if (!ApproverAccess.isOwnAttendance(request, user?.employeeId)) {
      return failure;
    }
    return Failure.validation(
      message: ApprovalDecisionCode.tokenCannotDecideOwn,
      code: ApprovalDecisionCode.notApprover,
    );
  }

  static String? _tokenOf(Failure failure) => switch (failure) {
    ValidationFailure(:final message) => message,
    _ => null,
  };

  /// Out of the waiting list at once, then both lists read again (not
  /// waited on: a slow or failed reload never holds the answer back).
  void _leaveWaiting() {
    if (_disposed || !ref.exists(listsProvider)) return;
    final lists = ref.read(listsProvider.notifier);
    lists.dropWaiting(arg);
    unawaited(lists.refresh());
  }

  Future<void> _reloadPage() async {
    if (_disposed) return;
    await reloadPage();
  }

  void _mark({bool rejectOnly = false, bool notMine = false}) {
    if (!_disposed) {
      state = state.copyWith(
        rejectOnly: rejectOnly || state.rejectOnly,
        notMine: notMine || state.notMine,
      );
    }
    if (ref.exists(listsProvider)) {
      ref
          .read(listsProvider.notifier)
          .mark(arg, rejectOnly: rejectOnly, notMine: notMine);
    }
  }
}
