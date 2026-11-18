import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import '../providers/offsite_approvals_notifier.dart';
import '../providers/offsite_decision_notifier.dart';
import 'attendance_approvals_view.dart';
import 'offsite_approval_card.dart';

/// The approvals page's off-site tab (#46): the scans waiting at the
/// approver's step, then "decided by me". A row opens the scan's approver
/// page (`/approvals/offsite/:id`).
class OffsiteApprovalsTab extends StatelessWidget {
  const OffsiteApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AttendanceApprovalsView<OffsiteRequestDetail>(
      lists: offsiteApprovalsNotifierProvider,
      decisionOf: offsiteDecisionNotifierProvider.call,
      routeOf: AppRoutes.approvalOffsite,
      loadFailedText: (l10n) => l10n.offsiteApprovalsLoadFailed,
      cardOf: (context, request, actions) => OffsiteApprovalCard(
        request: request,
        deciding: actions.deciding,
        canDecide: actions.canDecide,
        own: actions.own,
        rejectOnly: actions.rejectOnly,
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
