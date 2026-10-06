import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import 'approval_card_parts.dart';
import 'offsite_copy.dart';
import 'time_correction_approval_copy.dart';

/// The facts that make a request an off-site one, shared by the approver's card
/// and the employee's own history card so the two read the same.
///
/// They take the request itself rather than plain values — unlike
/// [ApprovalCardShell]'s parts, which serve two different workflows. Here there
/// is only one shape, and threading six fields through twice would buy nothing.

/// The day of the scan and its shift segment, over the direction chip and the
/// shift group.
class OffsiteScanBox extends StatelessWidget {
  final OffsiteRequestDetail request;

  const OffsiteScanBox({super.key, required this.request});

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

/// When the server stamped the scan, and the coordinates it was taken at.
class OffsitePositionRow extends StatelessWidget {
  final OffsiteRequestDetail request;

  const OffsitePositionRow({super.key, required this.request});

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
