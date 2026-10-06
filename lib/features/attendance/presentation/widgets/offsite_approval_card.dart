import 'package:flutter/material.dart';

import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'approval_card_parts.dart';
import 'offsite_request_facts.dart';
import 'time_correction_approval_copy.dart';

/// One off-site scan request on the approvals tab: who filed it and its status,
/// the day and shift segment, which punch it stands in for, when and where it
/// was taken, the reason, the photo, and — while it is pending — the approve /
/// reject buttons.
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
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<String> onViewImage;

  const OffsiteApprovalCard({
    super.key,
    required this.request,
    required this.deciding,
    required this.onApprove,
    required this.onReject,
    required this.onViewImage,
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
        if (request.status == TimeCorrectionStatus.pending) ...[
          heightBx(h: 14),
          ApprovalDecisionRow(
            enabled: !deciding,
            onApprove: onApprove,
            onReject: onReject,
          ),
        ],
      ],
    );
  }
}
