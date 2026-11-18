import 'package:flutter/material.dart';

import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/presentation/widgets/approve_note_dialog.dart';
import '../../../approvals/presentation/widgets/reject_reason_dialog.dart';
import '../../domain/entities/ot_request.dart';
import '../providers/ot_decision_notifier.dart';
import '../providers/ot_detail_notifier.dart';

/// How a head's action on an OT request ended, for its page.
enum OtDecisionEnd { done, refused, gone, dismissed }

/// A head's Approve, Reject and Cancel on an OT request (#49), from its row
/// or its page: ask first (a comment for Approve, optional; a reason for
/// Reject, required; a confirm for Cancel), act through [notifier], then
/// say how it went.
class OtDecisionFlow {
  const OtDecisionFlow._();

  static Future<OtDecisionEnd> approve(
    BuildContext context,
    OtDecisionNotifier notifier,
    OtRequest request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final comment = await ApproveNoteDialog.show(
      context,
      approveLabel: l10n.leaveApprovalApproveAction,
    );
    if (comment == null) return OtDecisionEnd.dismissed;
    return _told(
      await notifier.approve(request, comment: comment),
      l10n,
      l10n.otApprovedToast,
    );
  }

  static Future<OtDecisionEnd> reject(
    BuildContext context,
    OtDecisionNotifier notifier,
    OtRequest request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await RejectReasonDialog.show(context);
    if (reason == null) return OtDecisionEnd.dismissed;
    return _told(
      await notifier.reject(request, reason),
      l10n,
      l10n.otRejectedToast,
    );
  }

  static Future<OtDecisionEnd> cancelApproved(
    BuildContext context,
    OtDecisionNotifier notifier,
    OtRequest request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final sure = await AppDialog.ask(
      context,
      message: l10n.otCancelApprovedConfirm,
      confirmLabel: l10n.otCancelApprovedAction,
      cancelLabel: l10n.back,
    );
    if (!sure) return OtDecisionEnd.dismissed;
    return _told(
      await notifier.cancelApproved(request),
      l10n,
      l10n.otCancelledToast,
    );
  }

  /// Null: an action already on its way says how it went.
  static OtDecisionEnd _told(
    Result<OtRequest>? result,
    AppLocalizations l10n,
    String done,
  ) {
    if (result == null) return OtDecisionEnd.dismissed;
    return result.fold(
      (failure) {
        if (OtDetailNotifier.isGone(failure)) {
          AppToast.error(l10n.apprRequestNotFound);
          return OtDecisionEnd.gone;
        }
        AppToast.error(failure.localize(l10n));
        return OtDecisionEnd.refused;
      },
      (_) {
        AppToast.success(done);
        return OtDecisionEnd.done;
      },
    );
  }
}
