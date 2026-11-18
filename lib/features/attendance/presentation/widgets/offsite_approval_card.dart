import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'approval_card_parts.dart';
import 'offsite_request_facts.dart';
import 'time_correction_approval_copy.dart';

/// One off-site scan request on the approvals tab: who filed it and its status,
/// the day and shift segment, which punch it stands in for, when and where it
/// was taken, the reason, the photo, and — when the waiting step is the
/// approver's (#46) — the approve / reject buttons. On the approver's own
/// request a line says someone else decides it.
///
/// Built from the same parts as [TimeCorrectionApprovalCard], so an approver
/// moving between the two tabs reads the same card twice over. What differs is
/// what sits in the middle: a position and a scan time rather than a pair of
/// corrected times — and those two blocks are shared with
/// [OffsiteRecordCard], the employee's own view of the same request.
class OffsiteApprovalCard extends StatelessWidget {
  final OffsiteRequestDetail request;

  /// Whether a decision on this request is in flight; disables the buttons.
  final bool deciding;

  /// Whether the waiting step is the approver's (`canDecideOffsite`).
  final bool canDecide;

  /// The approver's own request: a line instead of buttons.
  final bool own;

  /// Reject only (`CHECKIN_NOT_APPROVED`).
  final bool rejectOnly;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final ValueChanged<String> onViewImage;

  const OffsiteApprovalCard({
    super.key,
    required this.request,
    required this.onViewImage,
    this.deciding = false,
    this.canDecide = false,
    this.own = false,
    this.rejectOnly = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employee = request.employee;
    final status = TimeCorrectionApprovalCopy.status(l10n, request.status);
    final photo = request.attachmentUrl;

    return ApprovalCardShell(
      children: [
        ApprovalEmployeeRow(
          name: employee.name,
          employeeNumber: employee.employeeNumber,
          department: TimeCorrectionApprovalCopy.department(l10n, employee),
          statusLabel: status.label,
          statusColor: status.color,
        ),
        heightBx(h: 14),
        OffsiteScanBox(request: request),
        heightBx(h: 12),
        OffsitePositionRow(request: request),
        if (request.reason.isNotEmpty) ...[
          heightBx(h: 12),
          ApprovalReasonLine(reason: request.reason),
        ],
        heightBx(h: 8),
        if (photo == null)
          const ApprovalNoAttachment()
        else
          ApprovalAttachmentRow(url: photo, onView: () => onViewImage(photo)),
        if (own && request.status == TimeCorrectionStatus.pending) ...[
          heightBx(h: 14),
          customText(
            l10n.leaveOwnRequestNoActions,
            fontSize: 13,
            color: AppColors.subTitle,
            maxLine: 3,
          ),
        ] else if (canDecide && onApprove != null && onReject != null) ...[
          heightBx(h: 14),
          ApprovalDecisionRow(
            enabled: !deciding,
            showApprove: !rejectOnly,
            onApprove: onApprove!,
            onReject: onReject!,
          ),
        ],
      ],
    );
  }
}
