import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/leave_request.dart';
import '../../../time_off/presentation/providers/leave_approvals_state.dart';
import '../../../time_off/presentation/widgets/leave_copy.dart';
import '../../../time_off/presentation/widgets/leave_reject_reason_dialog.dart';
import '../providers/leave_approval_decision_notifier.dart';
import 'approve_note_dialog.dart';

/// Approve and Reject on the approver's page of one leave request.
///
/// Approve asks first, with an optional note. After a decision the page
/// says so and goes back to the list; after a refusal it says why and shows
/// the request as it now is (the notifier has reloaded it).
class LeaveApprovalActions extends ConsumerWidget {
  const LeaveApprovalActions({super.key, required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final deciding = ref.watch(
      leaveApprovalDecisionNotifierProvider(request.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: deciding ? null : () => _approve(context, ref),
          icon: const Icon(Icons.check),
          label: customText(
            LeaveCopy.approveActionLabel(l10n, request),
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        heightBx(h: 10),
        OutlinedButton.icon(
          onPressed: deciding ? null : () => _reject(context, ref),
          icon: const Icon(Icons.close, color: AppColors.danger),
          label: customText(
            l10n.leaveApprovalRejectAction,
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.danger),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(
      leaveApprovalDecisionNotifierProvider(request.id).notifier,
    );
    final note = await ApproveNoteDialog.show(
      context,
      lastStep: request.isFinalApprovalStep,
      approveLabel: LeaveCopy.approveActionLabel(l10n, request),
    );
    if (note == null || !context.mounted) return;

    final outcome = await notifier.approve(request, note: note);
    // Said whether or not the page is still open: the toast needs no
    // page, and going back mid-way must not lose the answer.
    _report(l10n, outcome, l10n.apprApprovedToast);
    if (outcome.isDone && context.mounted) _leave(context);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(
      leaveApprovalDecisionNotifierProvider(request.id).notifier,
    );
    final reason = await LeaveRejectReasonDialog.show(context);
    if (reason == null || !context.mounted) return;

    final outcome = await notifier.reject(request, reason);
    // Said whether or not the page is still open: the toast needs no
    // page, and going back mid-way must not lose the answer.
    _report(l10n, outcome, l10n.apprRejectedToast);
    if (outcome.isDone && context.mounted) _leave(context);
  }

  /// Says how it went. A refusal stays on the page, which now shows the
  /// request as it is.
  static void _report(
    AppLocalizations l10n,
    LeaveDecisionOutcome outcome,
    String done,
  ) {
    if (outcome.abandoned) return;
    switch (outcome.kind) {
      case LeaveDecisionKind.success:
        AppToast.success(done);
      case LeaveDecisionKind.reloaded:
        AppToast.info(LeaveCopy.decisionRefusal(l10n, outcome)!);
      case LeaveDecisionKind.failed:
        AppToast.error(LeaveCopy.decisionRefusal(l10n, outcome)!);
    }
  }

  /// After a decision: back to the list, or to the Approvals place when
  /// opened by a link with nothing underneath (not a page still showing
  /// the request as waiting).
  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.approvals);
    }
  }
}

extension on LeaveDecisionOutcome {
  bool get isDone => kind == LeaveDecisionKind.success && !abandoned;
}
