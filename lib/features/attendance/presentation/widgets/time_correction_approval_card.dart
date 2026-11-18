import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'approval_card_parts.dart';
import 'time_correction_approval_copy.dart';
import 'time_correction_copy.dart';

/// One request on the approvals page: who filed it and its status, the day,
/// shift and correction type, the requested time(s), the reason, the
/// evidence file, and — when the waiting step is the approver's (#47) — the
/// approve / reject buttons. On the approver's own request a line says
/// someone else decides it.
class TimeCorrectionApprovalCard extends StatelessWidget {
  final TimeCorrectionDetail request;

  /// Whether a decision on this request is in flight; disables the buttons.
  final bool deciding;

  /// Whether the waiting step is the approver's (`canDecideAttendance`).
  final bool canDecide;

  /// The approver's own request: a line instead of buttons.
  final bool own;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final ValueChanged<String> onViewImage;

  const TimeCorrectionApprovalCard({
    super.key,
    required this.request,
    required this.onViewImage,
    this.deciding = false,
    this.canDecide = false,
    this.own = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attachment = request.attachmentUrl;
    final employee = request.employee;
    final status = TimeCorrectionApprovalCopy.status(l10n, request.status);

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
        _ScheduleBox(request: request),
        heightBx(h: 12),
        _TimeTiles(request: request),
        if (request.reason.isNotEmpty) ...[
          heightBx(h: 12),
          ApprovalReasonLine(reason: request.reason),
        ],
        heightBx(h: 8),
        if (attachment == null)
          const ApprovalNoAttachment()
        else
          ApprovalAttachmentRow(
            url: attachment,
            onView: () => onViewImage(attachment),
          ),
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
            onApprove: onApprove!,
            onReject: onReject!,
          ),
        ],
      ],
    );
  }
}

/// The corrected day and its shift segment, over the correction-type chip
/// and the shift group.
class _ScheduleBox extends StatelessWidget {
  final TimeCorrectionDetail request;

  const _ScheduleBox({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segment = TimeCorrectionApprovalCopy.shiftSegment(
      l10n,
      request.shift,
    );
    final group = TimeCorrectionApprovalCopy.shiftGroup(l10n, request.shift);
    final type = TimeCorrectionApprovalCopy.type(l10n, request.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.primaryVariant,
              ),
              widthBx(w: 8),
              Expanded(
                child: customText(
                  TimeCorrectionApprovalCopy.date(request.requestDate),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (segment != null) ...[
                widthBx(w: 8),
                Flexible(child: ApprovalOutlinedChip(label: segment)),
              ],
            ],
          ),
          heightBx(h: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ApprovalTintedChip(
                icon: type.icon,
                label: type.label,
                color: type.color,
              ),
              if (group != null)
                ApprovalTintedChip(
                  label: group,
                  color: AppColors.primaryVariant,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The in / out tiles side by side. A side the request corrects shows the
/// requested time on a tint; the other side stays white with "-- : --".
class _TimeTiles extends StatelessWidget {
  final TimeCorrectionDetail request;

  const _TimeTiles({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = request.type;

    return Row(
      children: [
        Expanded(
          child: _TimeTile(
            requested: type.needsClockIn,
            label: type.needsClockIn
                ? l10n.timeCorrectionApprovalNewIn
                : l10n.timeCorrectionApprovalClockIn,
            icon: Icons.login,
            time: type.needsClockIn ? request.clockIn : null,
          ),
        ),
        widthBx(w: 10),
        Expanded(
          child: _TimeTile(
            requested: type.needsClockOut,
            label: type.needsClockOut
                ? l10n.timeCorrectionApprovalNewOut
                : l10n.timeCorrectionApprovalClockOut,
            icon: Icons.logout,
            time: type.needsClockOut ? request.clockOut : null,
          ),
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final bool requested;
  final String label;
  final IconData icon;
  final Duration? time;

  const _TimeTile({
    required this.requested,
    required this.label,
    required this.icon,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    final color = requested ? AppColors.primaryDark : AppColors.gray500;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: requested ? const Color(0xFFF6F7FE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: requested ? Colors.transparent : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: requested ? AppColors.primaryVariant : AppColors.gray600,
          ),
          heightBx(h: 4),
          Row(
            children: [
              if (requested) ...[
                Icon(icon, size: 18, color: color),
                widthBx(w: 6),
              ],
              customText(
                time == null
                    ? '-- : --'
                    : TimeCorrectionCopy.hourMinuteOf(time),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
