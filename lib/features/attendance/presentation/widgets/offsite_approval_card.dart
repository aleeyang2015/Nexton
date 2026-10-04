import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'approval_card_parts.dart';
import 'offsite_copy.dart';
import 'time_correction_approval_copy.dart';

/// One off-site scan request on the approvals tab: who filed it and its status,
/// the day and shift segment, which punch it stands in for, when and where it
/// was taken, the reason, the photo, and — while it is pending — the approve /
/// reject buttons.
///
/// Built from the same parts as [TimeCorrectionApprovalCard], so an approver
/// moving between the two tabs reads the same card twice over. What differs is
/// what sits in the middle: a position and a scan time rather than a pair of
/// corrected times.
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
        _ScanBox(request: request),
        heightBx(h: 12),
        _PositionRow(request: request),
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

/// The day of the scan and its shift segment, over the direction chip and the
/// shift group.
class _ScanBox extends StatelessWidget {
  final OffsiteRequestDetail request;

  const _ScanBox({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = OffsiteCopy.scanDate(request);
    final segment = TimeCorrectionApprovalCopy.shiftSegment(
      l10n,
      request.shift,
    );
    final group = TimeCorrectionApprovalCopy.shiftGroup(l10n, request.shift);
    final method = OffsiteCopy.methodChip(l10n, request.method);

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
                  date ?? l10n.offsiteApprovalNoScanDate,
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
                icon: method.icon,
                label: method.label,
                color: method.color,
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

/// The two things that make this request an off-site one: when the server
/// stamped the scan, and the coordinates it was taken at.
class _PositionRow extends StatelessWidget {
  final OffsiteRequestDetail request;

  const _PositionRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _Tile(
            label: l10n.offsiteApprovalScannedAt,
            icon: Icons.schedule,
            value: OffsiteCopy.scanTime(request) ?? '-- : --',
            emphasised: true,
          ),
        ),
        widthBx(w: 10),
        Expanded(
          flex: 2,
          child: _Tile(
            label: l10n.offsiteApprovalPosition,
            icon: Icons.my_location,
            value: OffsiteCopy.position(request) ?? l10n.offsiteApprovalNoFix,
            emphasised: request.hasCoordinates,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;

  /// A tile with something to show sits on a tint; one without stays white, as
  /// on the correction card's unused side.
  final bool emphasised;

  const _Tile({
    required this.label,
    required this.icon,
    required this.value,
    required this.emphasised,
  });

  @override
  Widget build(BuildContext context) {
    final color = emphasised ? AppColors.primaryDark : AppColors.gray500;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: emphasised ? const Color(0xFFF6F7FE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasised ? Colors.transparent : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: emphasised ? AppColors.primaryVariant : AppColors.gray600,
          ),
          heightBx(h: 4),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              widthBx(w: 6),
              Flexible(
                child: customText(
                  value,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
