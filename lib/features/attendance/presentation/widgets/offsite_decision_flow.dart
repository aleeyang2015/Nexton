import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/presentation/widgets/approve_note_dialog.dart';
import '../../../approvals/presentation/widgets/reject_reason_dialog.dart';
import '../../domain/entities/offsite_detail.dart';
import '../providers/offsite_decision_notifier.dart';

/// Approve and Reject on an off-site scan (#46), from its row or its page:
/// ask first (a note for Approve, optional; a reason for Reject, required),
/// decide through [offsiteDecisionNotifierProvider], then say how it went.
class OffsiteDecisionFlow {
  const OffsiteDecisionFlow._();

  /// True when the request was approved.
  static Future<bool> approve(
    BuildContext context,
    WidgetRef ref,
    OffsiteRequestDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(
      offsiteDecisionNotifierProvider(request.id).notifier,
    );
    final note = await ApproveNoteDialog.show(
      context,
      approveLabel: l10n.timeCorrectionApprovalApprove,
    );
    if (note == null) return false;
    return _told(await notifier.approve(request, note: note), l10n, true);
  }

  /// True when the request was rejected.
  static Future<bool> reject(
    BuildContext context,
    WidgetRef ref,
    OffsiteRequestDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(
      offsiteDecisionNotifierProvider(request.id).notifier,
    );
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
          approved
              ? l10n.offsiteApprovalApproved
              : l10n.offsiteApprovalRejected,
        );
        return true;
      },
    );
  }
}
