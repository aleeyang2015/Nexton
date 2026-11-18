import 'package:flutter/material.dart';

import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/presentation/widgets/approve_note_dialog.dart';
import '../../../approvals/presentation/widgets/reject_reason_dialog.dart';
import '../../domain/entities/attendance_approval_request.dart';
import '../providers/attendance_decision_notifier.dart';

/// Approve and Reject on an attendance request (#46, #47), from its row or
/// its page: ask first (a note for Approve, optional; a reason for Reject,
/// required), decide through [notifier], then say how it went.
class AttendanceDecisionFlow {
  const AttendanceDecisionFlow._();

  /// True when the request was approved.
  static Future<bool> approve<T extends AttendanceApprovalRequest>(
    BuildContext context,
    AttendanceDecisionNotifier<T> notifier,
    T request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final note = await ApproveNoteDialog.show(
      context,
      approveLabel: l10n.timeCorrectionApprovalApprove,
    );
    if (note == null) return false;
    return _told(await notifier.approve(request, note: note), l10n, true);
  }

  /// True when the request was rejected.
  static Future<bool> reject<T extends AttendanceApprovalRequest>(
    BuildContext context,
    AttendanceDecisionNotifier<T> notifier,
    T request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await RejectReasonDialog.show(context);
    if (reason == null) return false;
    return _told(await notifier.reject(request, reason), l10n, false);
  }

  /// Null: a decision already on its way says how it went.
  static bool _told(
    Result<Unit>? result,
    AppLocalizations l10n,
    bool approved,
  ) {
    if (result == null) return false;
    return result.fold(
      (failure) {
        AppToast.error(failure.localize(l10n));
        return false;
      },
      (_) {
        AppToast.success(
          approved ? l10n.apprApprovedToast : l10n.apprRejectedToast,
        );
        return true;
      },
    );
  }
}
