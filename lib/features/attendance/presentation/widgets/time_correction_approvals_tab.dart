import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../providers/time_correction_approvals_notifier.dart';
import '../providers/time_correction_decision_notifier.dart';
import 'attendance_approvals_view.dart';
import 'time_correction_approval_card.dart';

/// The approvals page's "forgot to scan" tab (#47): the requests waiting at
/// the approver's step, then "decided by me". A row shows the asked time
/// beside the part's own; a tap opens the request's approver page
/// (`/approvals/correction/:id`).
class TimeCorrectionApprovalsTab extends StatelessWidget {
  const TimeCorrectionApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AttendanceApprovalsView<TimeCorrectionDetail>(
      lists: timeCorrectionApprovalsNotifierProvider,
      decisionOf: timeCorrectionDecisionNotifierProvider.call,
      routeOf: AppRoutes.approvalCorrection,
      loadFailedText: (l10n) => l10n.timeCorrectionHistoryLoadFailed,
      cardOf: (context, request, actions) => TimeCorrectionApprovalCard(
        request: request,
        deciding: actions.deciding,
        canDecide: actions.canDecide,
        own: actions.own,
        onApprove: actions.onApprove,
        onReject: actions.onReject,
        onViewImage: (url) => showImageViewer(
          context,
          url,
          errorText: AppLocalizations.of(context)!.leaveFileOpenFailed,
        ),
      ),
    );
  }
}
