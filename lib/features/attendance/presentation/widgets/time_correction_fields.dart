import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_type.dart';
import 'attendance_history_copy.dart';
import 'time_correction_copy.dart';

BoxDecoration _tintBox() => BoxDecoration(
  color: AppColors.primaryTint,
  borderRadius: BorderRadius.circular(12),
);

/// The picked date ("18 ກັນຍາ 2026" over "ວັນສຸກ · 18/09/2026"); tapping it
/// opens the date picker.
class TimeCorrectionDateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const TimeCorrectionDateField({
    super.key,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: _tintBox(),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primaryVariant,
                ),
              ),
              widthBx(w: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText(
                      AttendanceHistoryCopy.dayMonthYear(l10n, date),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    customText(
                      TimeCorrectionCopy.dateSubtitle(l10n, date),
                      fontSize: 14,
                      color: AppColors.secondaryTxt,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.gray600),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four correction types as a 2×2 grid of toggle buttons.
class TimeCorrectionTypeSelector extends StatelessWidget {
  final TimeCorrectionType selected;
  final ValueChanged<TimeCorrectionType> onSelect;

  const TimeCorrectionTypeSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const types = TimeCorrectionType.values;

    return Column(
      children: [
        for (var row = 0; row < types.length; row += 2) ...[
          if (row > 0) heightBx(h: 8),
          Row(
            children: [
              for (var i = row; i < row + 2; i++) ...[
                if (i > row) widthBx(w: 8),
                Expanded(
                  child: _TypeButton(
                    type: types[i],
                    selected: types[i] == selected,
                    onTap: () => onSelect(types[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final TimeCorrectionType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = selected ? Colors.white : AppColors.textPrimary;

    return Material(
      color: selected ? AppColors.primaryVariant : AppColors.primaryTint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(TimeCorrectionCopy.typeIcon(type), size: 18, color: color),
              widthBx(w: 6),
              Flexible(
                child: customText(
                  TimeCorrectionCopy.typeLabel(l10n, type),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shift the correction is filed against: its name, the picked
/// segment's hours, and a swap button when there is another segment to pick.
class TimeCorrectionShiftCard extends StatelessWidget {
  final String name;
  final String hours;
  final VoidCallback? onChange;

  const TimeCorrectionShiftCard({
    super.key,
    required this.name,
    required this.hours,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _tintBox(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule, color: AppColors.primaryVariant),
          ),
          widthBx(w: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  name,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                heightBx(h: 2),
                customText(hours, fontSize: 14, color: AppColors.secondaryTxt),
              ],
            ),
          ),
          if (onChange != null) ...[
            widthBx(w: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onChange,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.swap_horiz, color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One corrected time: the "08:00" box and its "08:00 AM (ຕອນເຊົ້າ)" caption.
/// Tapping the box opens the time picker.
class TimeCorrectionTimeField extends StatelessWidget {
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const TimeCorrectionTimeField({
    super.key,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: _tintBox(),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primaryVariant, size: 22),
                  widthBx(w: 8),
                  customText(
                    TimeCorrectionCopy.hourMinute(time),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
        heightBx(h: 8),
        customText(
          TimeCorrectionCopy.caption(l10n, time),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTxt,
        ),
      ],
    );
  }
}
