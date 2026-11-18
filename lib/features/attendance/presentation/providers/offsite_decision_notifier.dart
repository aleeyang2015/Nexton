import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../attendance_providers.dart';
import '../../data/datasources/offsite_error_code.dart';
import '../../domain/entities/offsite_detail.dart';
import 'offsite_approvals_notifier.dart';
import 'offsite_detail_notifier.dart';

/// Approve or reject one off-site scan, by its id (#46), from its row in the
/// approvals tab or from its own page: one decision at a time for the
/// request, wherever it was tapped. The state is true while one is on its
/// way, so the buttons switch off and a second tap sends nothing.
///
/// After a decision, and after a refusal that means the request moved on
/// (decided by someone else, the step changed, gone), the tab's lists and
/// the request's page are read again when open. `CHECKIN_NOT_APPROVED`
/// leaves the request with Reject only.
class OffsiteDecisionNotifier extends AutoDisposeFamilyNotifier<bool, String> {
  bool _disposed = false;

  @override
  bool build(String arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return false;
  }

  /// Approves the waiting step, with [note] when one was typed. Null when a
  /// decision is already on its way: that one's answer is the one to tell.
  Future<Result<Unit>?> approve(OffsiteRequestDetail request, {String? note}) {
    final trimmed = note?.trim();
    return _decide(
      request,
      () => ref.read(approveOffsiteRequestUseCaseProvider)((
        id: request.id,
        stepId: request.currentStep?.id,
        note: trimmed == null || trimmed.isEmpty ? null : trimmed,
      )),
    );
  }

  /// Rejects the waiting step with [reason], what the employee is told.
  Future<Result<Unit>?> reject(OffsiteRequestDetail request, String reason) =>
      _decide(
        request,
        () => ref.read(rejectOffsiteRequestUseCaseProvider)((
          id: request.id,
          note: reason,
          stepId: request.currentStep?.id,
        )),
      );

  Future<Result<Unit>?> _decide(
    OffsiteRequestDetail request,
    Future<Result<Unit>> Function() action,
  ) async {
    if (state) return null;
    state = true;
    // Kept until the answer is handled: the approver may go back while it
    // is on its way, and the list underneath must still be read again.
    final keep = ref.keepAlive();
    try {
      final result = await action();
      final failure = result.failureOrNull;
      if (failure == null) {
        await _reload();
        return result;
      }
      final token = _tokenOf(failure);
      if (token == OffsiteErrorCode.tokenCheckinNotApproved) {
        _markRejectOnly();
      } else if (OffsiteErrorCode.staleTokens.contains(token)) {
        await _reload();
      }
      return Result.failure(_said(failure, token, request));
    } finally {
      if (!_disposed) state = false;
      keep.close();
    }
  }

  /// `NOT_APPROVER` on the approver's own request says "your own".
  Failure _said(Failure failure, String? token, OffsiteRequestDetail request) {
    if (token != OffsiteErrorCode.tokenAnotherApprover) return failure;
    final user = ref.read(authSessionProvider).valueOrNull?.user;
    if (!ApproverAccess.isOwnOffsite(request, user?.employeeId)) return failure;
    return Failure.validation(
      message: OffsiteErrorCode.tokenCannotDecideOwn,
      code: OffsiteErrorCode.notApprover,
    );
  }

  static String? _tokenOf(Failure failure) => switch (failure) {
    ValidationFailure(:final message) => message,
    _ => null,
  };

  /// The tab's lists and the request's page, when open.
  Future<void> _reload() async {
    if (_disposed) return;
    final pending = <Future<void>>[];
    if (ref.exists(offsiteApprovalsNotifierProvider)) {
      pending.add(
        ref.read(offsiteApprovalsNotifierProvider.notifier).refresh(),
      );
    }
    final detail = offsiteDetailNotifierProvider(arg);
    if (ref.exists(detail)) {
      pending.add(ref.read(detail.notifier).refresh());
    }
    await Future.wait(pending);
  }

  void _markRejectOnly() {
    ref.read(offsiteRejectOnlyProvider(arg).notifier).state = true;
    if (ref.exists(offsiteApprovalsNotifierProvider)) {
      ref.read(offsiteApprovalsNotifierProvider.notifier).markRejectOnly(arg);
    }
  }
}

final offsiteDecisionNotifierProvider = NotifierProvider.autoDispose
    .family<OffsiteDecisionNotifier, bool, String>(OffsiteDecisionNotifier.new);

/// True once the request [String] can only be rejected
/// (`CHECKIN_NOT_APPROVED`), for its own page.
final offsiteRejectOnlyProvider = StateProvider.autoDispose
    .family<bool, String>((ref, id) => false);
