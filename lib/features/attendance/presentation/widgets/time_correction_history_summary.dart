import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_copy.dart';

/// The three count cards at the top of the history page: total, awaiting
/// review and approved.
class TimeCorrectionSummaryRow extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;

  const TimeCorrectionSummaryRow({
    super.key,
    required this.total,
    required this.pending,
    required this.approved,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              label: l10n.timeCorrectionSummaryTotal,
              count: total,
              unit: l10n.timeCorrectionSummaryTotalUnit,
              countColor: AppColors.textPrimary,
              badge: const _IconBadge(
                icon: Icons.calendar_month,
                color: AppColors.primaryVariant,
                background: AppColors.primaryTint,
              ),
            ),
          ),
          widthBx(w: 10),
          Expanded(
            child: _SummaryCard(
              label: l10n.timeCorrectionSummaryPending,
              labelColor: AppColors.primaryVariant,
              count: pending,
              unit: l10n.timeCorrectionSummaryPendingUnit,
              countColor: AppColors.primary,
              badge: const _PendingDot(),
            ),
          ),
          widthBx(w: 10),
          Expanded(
            child: _SummaryCard(
              label: l10n.timeCorrectionSummaryApproved,
              count: approved,
              unit: l10n.timeCorrectionSummaryApprovedUnit,
              countColor: AppColors.gray600,
              badge: _IconBadge(
                icon: Icons.check_circle_outline,
                color: AppColors.attendancePresent,
                background: AppColors.attendancePresent.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final Color labelColor;
  final int count;
  final String unit;
  final Color countColor;
  final Widget badge;

  const _SummaryCard({
    required this.label,
    this.labelColor = AppColors.secondaryTxt,
    required this.count,
    required this.unit,
    required this.countColor,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: customText(
                  label,
                  fontSize: 13,
                  color: labelColor,
                  maxLine: 2,
                ),
              ),
              widthBx(w: 4),
              badge,
            ],
          ),
          heightBx(h: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              customText(
                '$count',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: countColor,
              ),
              widthBx(w: 4),
              Flexible(
                child: customText(
                  unit,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTxt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}

/// The ringed blue dot on the "awaiting review" card.
class _PendingDot extends StatelessWidget {
  const _PendingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.2),
      ),
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// The status filter: a dropdown of "ທັງໝົດ / ລໍຖ້າ / ອະນຸມັດ / ປະຕິເສດ /
/// ຍົກເລີກແລ້ວ", each with its count. A null status is "all".
class TimeCorrectionFilterDropdown extends StatelessWidget {
  final TimeCorrectionStatus? selected;
  final int Function(TimeCorrectionStatus? status) countOf;
  final ValueChanged<TimeCorrectionStatus?> onSelect;

  const TimeCorrectionFilterDropdown({
    super.key,
    required this.selected,
    required this.countOf,
    required this.onSelect,
  });

  static const List<TimeCorrectionStatus?> _options = [
    null,
    ...TimeCorrectionStatus.values,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTint, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeCorrectionStatus?>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primaryVariant,
          ),
          onChanged: onSelect,
          selectedItemBuilder: (context) => [
            for (final status in _options)
              Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 20,
                    color: AppColors.primaryVariant,
                  ),
                  widthBx(w: 10),
                  Expanded(
                    child: customText(
                      TimeCorrectionCopy.filterLabel(
                        l10n,
                        status,
                        countOf(status),
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryVariant,
                    ),
                  ),
                ],
              ),
          ],
          items: [
            for (final status in _options)
              DropdownMenuItem(
                value: status,
                child: customText(
                  TimeCorrectionCopy.filterLabel(l10n, status, countOf(status)),
                  fontSize: 15,
                  fontWeight: status == selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: status == selected
                      ? AppColors.primaryVariant
                      : AppColors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
