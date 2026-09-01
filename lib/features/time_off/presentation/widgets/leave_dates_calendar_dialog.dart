import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'leave_copy.dart';

/// A month calendar that lets the user tap several individual days — contiguous
/// or not — and confirm them all at once, instead of adding one date per
/// dialog. Returns the picked dates (sorted, normalized to midnight), or null
/// if the user backed out.
///
/// Selection is capped to a single day when [halfDay] is set, mirroring the
/// form's rule that a half-day request is exactly one date. The pickable range
/// matches the old per-date picker: one year back to one year ahead.
class LeaveDatesCalendarDialog extends StatefulWidget {
  const LeaveDatesCalendarDialog({
    super.key,
    required this.initialDates,
    required this.halfDay,
  });

  final List<DateTime> initialDates;
  final bool halfDay;

  /// Opens the dialog and resolves to the confirmed dates, or null on cancel.
  static Future<List<DateTime>?> show(
    BuildContext context, {
    required List<DateTime> initialDates,
    required bool halfDay,
  }) {
    return showDialog<List<DateTime>>(
      context: context,
      builder: (_) => LeaveDatesCalendarDialog(
        initialDates: initialDates,
        halfDay: halfDay,
      ),
    );
  }

  @override
  State<LeaveDatesCalendarDialog> createState() =>
      _LeaveDatesCalendarDialogState();
}

class _LeaveDatesCalendarDialogState extends State<LeaveDatesCalendarDialog> {
  late final DateTime _firstDate;
  late final DateTime _lastDate;
  late DateTime _visibleMonth;
  final Set<DateTime> _selected = {};

  @override
  void initState() {
    super.initState();
    final now = DateUtils.dateOnly(DateTime.now());
    _firstDate = now.subtract(const Duration(days: 365));
    _lastDate = now.add(const Duration(days: 365));
    _selected.addAll(widget.initialDates.map(DateUtils.dateOnly));
    final anchor = _selected.isEmpty
        ? now
        : _selected.reduce((a, b) => a.isBefore(b) ? a : b);
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  bool get _canGoPrev =>
      _visibleMonth.isAfter(DateTime(_firstDate.year, _firstDate.month));

  bool get _canGoNext =>
      _visibleMonth.isBefore(DateTime(_lastDate.year, _lastDate.month));

  void _shiftMonth(int delta) => setState(() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
  });

  void _toggle(DateTime day) {
    setState(() {
      if (_selected.contains(day)) {
        _selected.remove(day);
      } else if (widget.halfDay) {
        _selected
          ..clear()
          ..add(day);
      } else {
        _selected.add(day);
      }
    });
  }

  void _confirm() => Navigator.of(context).pop(_selected.toList()..sort());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = LeaveCopy.daysLabel(l10n, _selected.length.toDouble());

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: customText(
                      l10n.leaveSelectDatesLabel,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 20, color: AppColors.subTitle),
                    ),
                  ),
                ],
              ),
              heightBx(h: 8),
              _MonthNav(
                label: LeaveCopy.monthYearShort(l10n, _visibleMonth),
                canGoPrev: _canGoPrev,
                canGoNext: _canGoNext,
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
              heightBx(h: 8),
              const _WeekdayHeader(),
              heightBx(h: 4),
              _MonthGrid(
                month: _visibleMonth,
                firstDate: _firstDate,
                lastDate: _lastDate,
                selected: _selected,
                onTapDay: _toggle,
              ),
              heightBx(h: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    customText(
                      l10n.leaveDatesTotalPrefix,
                      fontSize: 13,
                      color: AppColors.subTitle,
                    ),
                    widthBx(w: 4),
                    customText(
                      total,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              heightBx(h: 12),
              button(_confirm, l10n.leaveSelectButtonLabel, height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "‹ Sep 2026 ›" month switcher. Arrows grey out at the range ends.
class _MonthNav extends StatelessWidget {
  final String label;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNav({
    required this.label,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Arrow(icon: Icons.chevron_left, enabled: canGoPrev, onTap: onPrev),
        Expanded(
          child: Center(
            child: customText(label, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        _Arrow(icon: Icons.chevron_right, enabled: canGoNext, onTap: onNext),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _Arrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 24,
          color: enabled ? AppColors.primary : AppColors.gray300,
        ),
      ),
    );
  }
}

/// The Sunday-first weekday-initials row above the day grid.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        for (final label in LeaveCopy.weekdayInitials(l10n))
          Expanded(
            child: Center(
              child: customText(
                label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.subTitle,
              ),
            ),
          ),
      ],
    );
  }
}

/// The tappable day grid for one month. Leading blanks pad the first row to the
/// weekday of the 1st (Sunday-first); days outside [firstDate]/[lastDate] are
/// shown disabled.
class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> selected;
  final ValueChanged<DateTime> onTapDay;

  const _MonthGrid({
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.selected,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final leadingBlanks = DateTime(month.year, month.month).weekday % 7;
    final dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateUtils.dateOnly(DateTime.now());

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
        for (var day = 1; day <= dayCount; day++)
          _DayCell(
            date: DateTime(month.year, month.month, day),
            selected: selected.contains(
              DateTime(month.year, month.month, day),
            ),
            isToday: today == DateTime(month.year, month.month, day),
            inRange:
                !DateTime(month.year, month.month, day).isBefore(firstDate) &&
                !DateTime(month.year, month.month, day).isAfter(lastDate),
            onTap: onTapDay,
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool isToday;
  final bool inRange;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.inRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !inRange
        ? AppColors.gray300
        : selected
        ? Colors.white
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: inRange ? () => onTap(date) : null,
      child: Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !selected
              ? Border.all(color: AppColors.primary)
              : null,
        ),
        child: customText(
          '${date.day}',
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
