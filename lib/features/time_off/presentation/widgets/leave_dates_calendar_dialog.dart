import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/company_days_off.dart';
import '../providers/leave_request_form_state.dart';
import 'leave_copy.dart';

/// What the calendar hands back: the separate days picked, or the two ends
/// of a range, depending on the mode it was opened in.
typedef LeaveCalendarResult = ({
  List<DateTime> dates,
  DateTime? rangeStart,
  DateTime? rangeEnd,
});

/// A month calendar for choosing leave days, in one of two ways.
///
/// * **Separate days** — tap several individual days, next to each other or
///   not, and confirm them all at once. A company day off is grey, struck
///   through and cannot be picked: every day sent this way is charged. A day
///   picked before it became a day off (an old request being edited) stays
///   shown with the same mark, and can be removed.
/// * **A date range** — the first tap is the first day, the second the last.
///   Days off inside the range show grey, since the server leaves them out,
///   and the footer shows how many days that leaves.
///
/// Returns the pick (sorted, normalized to midnight), or null if the user
/// backed out. Selection is capped to a single day when [halfDay] is set,
/// mirroring the form's rule that a half-day request is exactly one date. The
/// pickable span is one year back to one year ahead.
///
/// [daysOff] is null while the company's days off are not known. Nothing is
/// greyed out then, and a range's count is left to the server.
class LeaveDatesCalendarDialog extends StatefulWidget {
  const LeaveDatesCalendarDialog({
    super.key,
    required this.mode,
    required this.initialDates,
    required this.halfDay,
    this.initialRangeStart,
    this.initialRangeEnd,
    this.daysOff,
  });

  final LeaveDaysMode mode;
  final List<DateTime> initialDates;
  final DateTime? initialRangeStart;
  final DateTime? initialRangeEnd;
  final bool halfDay;
  final CompanyDaysOff? daysOff;

  /// Opens the dialog and resolves to what was confirmed, or null on cancel.
  static Future<LeaveCalendarResult?> show(
    BuildContext context, {
    required LeaveDaysMode mode,
    required List<DateTime> initialDates,
    required bool halfDay,
    DateTime? initialRangeStart,
    DateTime? initialRangeEnd,
    CompanyDaysOff? daysOff,
  }) {
    return showDialog<LeaveCalendarResult>(
      context: context,
      builder: (_) => LeaveDatesCalendarDialog(
        mode: mode,
        initialDates: initialDates,
        halfDay: halfDay,
        initialRangeStart: initialRangeStart,
        initialRangeEnd: initialRangeEnd,
        daysOff: daysOff,
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
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  bool get _isRange => widget.mode == LeaveDaysMode.range;

  @override
  void initState() {
    super.initState();
    final now = DateUtils.dateOnly(DateTime.now());
    _firstDate = now.subtract(const Duration(days: 365));
    _lastDate = now.add(const Duration(days: 365));
    _selected.addAll(widget.initialDates.map(DateUtils.dateOnly));
    _rangeStart = _dateOnly(widget.initialRangeStart);
    _rangeEnd = _dateOnly(widget.initialRangeEnd);

    final anchor = _isRange
        ? _rangeStart ?? now
        : _selected.isEmpty
        ? now
        : _selected.reduce((a, b) => a.isBefore(b) ? a : b);
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  static DateTime? _dateOnly(DateTime? date) =>
      date == null ? null : DateUtils.dateOnly(date);

  bool get _canGoPrev =>
      _visibleMonth.isAfter(DateTime(_firstDate.year, _firstDate.month));

  bool get _canGoNext =>
      _visibleMonth.isBefore(DateTime(_lastDate.year, _lastDate.month));

  void _shiftMonth(int delta) => setState(() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
  });

  bool _isDayOff(DateTime day) => widget.daysOff?.isDayOff(day) ?? false;

  /// The range as it stands: null until a first day is tapped; one day long
  /// until the second tap.
  ({DateTime start, DateTime end})? get _range {
    final start = _rangeStart;
    if (start == null) return null;
    return (start: start, end: _rangeEnd ?? start);
  }

  bool _inPickedRange(DateTime day) {
    final range = _range;
    return range != null &&
        !day.isBefore(range.start) &&
        !day.isAfter(range.end);
  }

  void _onTapDay(DateTime day) => _isRange ? _tapRange(day) : _toggle(day);

  void _toggle(DateTime day) {
    setState(() {
      if (_selected.contains(day)) {
        _selected.remove(day);
      } else if (_isDayOff(day)) {
        // A day off cannot be added; one already there can only come out.
        return;
      } else if (widget.halfDay) {
        _selected
          ..clear()
          ..add(day);
      } else {
        _selected.add(day);
      }
    });
  }

  /// First tap: the first day. Second tap: the last day (put in order if it
  /// is earlier). A third tap starts again.
  void _tapRange(DateTime day) {
    setState(() {
      final start = _rangeStart;
      if (start == null || _rangeEnd != null) {
        _rangeStart = day;
        _rangeEnd = null;
      } else if (day.isBefore(start)) {
        _rangeEnd = start;
        _rangeStart = day;
      } else {
        _rangeEnd = day;
      }
    });
  }

  /// The days the pick is charged for, or null when that is not known: a
  /// range, with the company's days off not loaded.
  int? get _chargedCount {
    if (!_isRange) return _selected.length;

    final range = _range;
    if (range == null) return 0;
    return widget.daysOff?.workingDaysBetween(range.start, range.end).length;
  }

  void _confirm() {
    final range = _range;
    Navigator.of(context).pop<LeaveCalendarResult>((
      dates: _isRange ? const <DateTime>[] : (_selected.toList()..sort()),
      rangeStart: _isRange ? range?.start : null,
      rangeEnd: _isRange ? range?.end : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = _chargedCount;
    final total = count == null
        ? null
        // A half day is one day picked, charged half (#14).
        : LeaveCopy.daysLabel(l10n, count * (widget.halfDay ? 0.5 : 1.0));
    // In range mode the title says which tap is next.
    final title = !_isRange
        ? l10n.leaveSelectDatesLabel
        : (_rangeStart == null || _rangeEnd != null)
        ? l10n.leavePickRangeStart
        : l10n.leavePickRangeEnd;

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
                      title,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.subTitle,
                      ),
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
                isSelected: (day) =>
                    _isRange ? _inPickedRange(day) : _selected.contains(day),
                isDayOff: _isDayOff,
                // A range may start, end or run across a day off; the server
                // leaves it out. Separate days may not include one.
                dayOffIsPickable: _isRange,
                onTapDay: _onTapDay,
              ),
              if (widget.daysOff != null) ...[
                heightBx(h: 8),
                const _DayOffLegend(),
              ],
              heightBx(h: 12),
              Center(
                child: total == null
                    ? customText(
                        l10n.leaveRangeCountByServer,
                        fontSize: 13,
                        color: AppColors.subTitle,
                        maxLine: 2,
                        alight: TextAlign.center,
                      )
                    : Row(
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

/// A grey dot and "Company day off", under the grid.
class _DayOffLegend extends StatelessWidget {
  const _DayOffLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.gray400,
            shape: BoxShape.circle,
          ),
        ),
        widthBx(w: 6),
        Flexible(
          child: customText(
            l10n.leaveDayOffLegend,
            fontSize: 12,
            color: AppColors.subTitle,
          ),
        ),
      ],
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

  const _Arrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

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
/// shown disabled, and company days off are marked.
class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool Function(DateTime day) isSelected;
  final bool Function(DateTime day) isDayOff;

  /// Whether a day off can be tapped at all: yes in a range, no among
  /// separate days (except to remove one already picked).
  final bool dayOffIsPickable;
  final ValueChanged<DateTime> onTapDay;

  const _MonthGrid({
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.isSelected,
    required this.isDayOff,
    required this.dayOffIsPickable,
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
          _cell(DateTime(month.year, month.month, day), today),
      ],
    );
  }

  Widget _cell(DateTime date, DateTime today) {
    final selected = isSelected(date);
    final dayOff = isDayOff(date);
    final inSpan = !date.isBefore(firstDate) && !date.isAfter(lastDate);

    return _DayCell(
      date: date,
      selected: selected,
      isToday: today == date,
      dayOff: dayOff,
      // Inside the pickable span, and not a day off that separate days must
      // leave alone. One already picked can still be tapped, to remove it.
      tappable: inSpan && (!dayOff || dayOffIsPickable || selected),
      inRange: inSpan,
      onTap: onTapDay,
    );
  }
}

/// One day of the grid.
///
/// A company day off is grey and struck through. Picked among separate days
/// (an old request being edited) it keeps a grey fill, so it reads as
/// "selected, but a day off". Inside a range it stays grey with no fill: the
/// range covers it, the server does not charge it.
class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool isToday;
  final bool dayOff;
  final bool tappable;
  final bool inRange;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.dayOff,
    required this.tappable,
    required this.inRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = selected && !dayOff;
    final color = !inRange
        ? AppColors.gray300
        : dayOff
        ? AppColors.gray400
        : selected
        ? Colors.white
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: tappable ? () => onTap(date) : null,
      child: Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.primary
              : (selected && dayOff)
              ? AppColors.gray100
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !filled
              ? Border.all(color: AppColors.primary)
              : null,
        ),
        child: Text(
          '${date.day}',
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
            fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
            color: color,
            decoration: dayOff ? TextDecoration.lineThrough : null,
            decorationColor: color,
          ),
        ),
      ),
    );
  }
}
