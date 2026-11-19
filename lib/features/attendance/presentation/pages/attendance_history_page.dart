import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../features/profile/domain/entities/shift_detail.dart';
import '../../../../features/profile/presentation/providers/profile_notifier.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_summary.dart';
import '../providers/attendance_history_notifier.dart';
import '../widgets/attendance_copy.dart';
import '../widgets/attendance_history_copy.dart';
import '../../domain/correction_rules.dart';
import '../../../../app/router/app_router.dart';

/// "ປະຫວັດການເຂົ້າວຽກ" — the destination behind the home screen's "view all".
///
/// A month switcher, that month's present/late/hours stat cards, and its
/// daily records, each expandable into the sessions it was punched from.
/// Everything comes from [attendanceHistoryNotifierProvider]; the page
/// holds no fetching logic of its own.
class AttendanceHistoryPage extends ConsumerWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(attendanceHistoryNotifierProvider);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: popBack(),
                    ),
                    widthBx(w: 4),
                    Expanded(
                      child: customText(
                        l10n.attendanceHistoryTitle,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const _MonthSwitcher(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
                  children: [
                    // A login with no employee record fails both loads the
                    // same way; the state decides to say it once, below.
                    if (state.showsSummary) ...[
                      _SummaryRow(summary: state.summary),
                      heightBx(h: 20),
                    ],
                    _RecordsList(records: state.records),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(attendanceHistoryNotifierProvider);
    final notifier = ref.read(attendanceHistoryNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: notifier.previousMonth,
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          widthBx(w: 4),
          customText(
            AttendanceHistoryCopy.monthYear(l10n, state.month),
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          widthBx(w: 4),
          InkWell(
            onTap: state.canGoNext ? notifier.nextMonth : null,
            child: Icon(
              Icons.chevron_right,
              color: state.canGoNext ? AppColors.primary : AppColors.gray400,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  final AsyncValue<AttendanceSummary> summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loading = summary.isLoading && !summary.hasValue;

    if (loading) {
      return Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) heightBx(h: 10),
            const Row(
              children: [
                Expanded(child: ShimmerBox(width: double.infinity, height: 96)),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 96)),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 96)),
              ],
            ),
          ],
        ],
      );
    }

    // A failed summary used to fall through to "0 / 0 / 0.0", which read as
    // real data. Surface the failure instead, with the same retry the records
    // list offers (both reload together) — unless a retry cannot help.
    final data = summary.valueOrNull;
    if (summary.hasError || data == null) {
      return _SummaryError(
        failure: AttendanceCopy.monthLoadFailure(l10n, summary.error),
        onRetry: () =>
            ref.read(attendanceHistoryNotifierProvider.notifier).retry(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customText(
          l10n.attWorkingDaysBase(data.totalWorkingDays),
          color: AppColors.subTitle,
          fontSize: 13,
        ),
        heightBx(h: 10),
        _SummaryCardRow(
          cards: [
            _SummaryCard(
              color: AppColors.attendancePresent,
              icon: Icons.check,
              value: '${data.presentDays}',
              label: l10n.daysPresent,
            ),
            _SummaryCard(
              color: AppColors.attendanceLate,
              icon: Icons.access_time,
              value: '${data.lateDays}',
              label: l10n.daysLate,
            ),
            _SummaryCard(
              color: AppColors.gray600,
              icon: Icons.timelapse,
              value: '${data.halfDays}',
              label: l10n.attendanceHalfDayStatus,
            ),
          ],
        ),
        heightBx(h: 10),
        _SummaryCardRow(
          cards: [
            _SummaryCard(
              color: AppColors.attendanceLate,
              icon: Icons.more_horiz,
              value: '${data.incompleteDays}',
              label: l10n.attendanceIncompleteStatus,
            ),
            _SummaryCard(
              color: AppColors.attendanceAbsent,
              icon: Icons.close,
              value: '${data.absentDays}',
              label: l10n.daysAbsent,
            ),
            _SummaryCard(
              color: AppColors.secondary,
              icon: Icons.event_available_outlined,
              value: '${data.leaveDays}',
              label: l10n.leaveDays,
            ),
          ],
        ),
        heightBx(h: 10),
        _HoursRow(
          icon: Icons.trending_up,
          label: l10n.workHours,
          value: '${data.totalWorkHours.toStringAsFixed(1)} ${l10n.hoursUnit}',
        ),
        heightBx(h: 10),
        // Approved OT only, as the server totals it: never summed here.
        _HoursRow(
          icon: Icons.more_time,
          label: l10n.salaryOvertimeLabel,
          value:
              '${AttendanceHistoryCopy.hours(data.totalOvertimeHours)} '
              '${l10n.hoursUnit}',
        ),
      ],
    );
  }
}

/// Three stat cards side by side, all the same height.
class _SummaryCardRow extends StatelessWidget {
  final List<Widget> cards;

  const _SummaryCardRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) widthBx(w: 10),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }
}

/// One of the month's hour totals (worked, approved OT), on a row of its
/// own under the day counts.
class _HoursRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HoursRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          widthBx(w: 10),
          Expanded(
            child: customText(label, fontSize: 13, color: AppColors.subTitle),
          ),
          customText(
            value,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          heightBx(h: 8),
          customText(value, fontSize: 20, fontWeight: FontWeight.w700, color: color),
          heightBx(h: 2),
          customText(
            label,
            fontSize: 11,
            color: AppColors.subTitle,
            alight: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecordsList extends ConsumerWidget {
  final AsyncValue<List<AttendanceDay>> records;

  const _RecordsList({required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loading = records.isLoading && !records.hasValue;

    if (loading) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerBox(width: double.infinity, height: 88),
          ),
        ),
      );
    }

    if (records.hasError) {
      return _ErrorBlock(
        failure: AttendanceCopy.monthLoadFailure(l10n, records.error),
        onRetry: () =>
            ref.read(attendanceHistoryNotifierProvider.notifier).retry(),
      );
    }

    final days = records.valueOrNull ?? const [];
    if (days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: customText(
            l10n.attendanceHistoryEmpty,
            color: AppColors.subTitle,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < days.length; i++) _DayCard(index: i, day: days[i]),
      ],
    );
  }
}

/// The compact failure state for the stat cards — a single bordered strip that
/// keeps the daily records list below it visible and usable. Retry is offered
/// only when it can help.
class _SummaryError extends StatelessWidget {
  final ({String message, bool canRetry}) failure;
  final VoidCallback onRetry;

  const _SummaryError({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          widthBx(w: 10),
          Expanded(
            child: customText(
              failure.message,
              color: AppColors.subTitle,
              fontSize: 13,
              maxLine: 3,
            ),
          ),
          if (failure.canRetry) ...[
            widthBx(w: 10),
            InkWell(
              onTap: onRetry,
              child: customText(
                l10n.retry,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final ({String message, bool canRetry}) failure;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
            heightBx(h: 8),
            customText(
              failure.message,
              color: AppColors.subTitle,
              alight: TextAlign.center,
              maxLine: 3,
            ),
            if (failure.canRetry) ...[
              heightBx(h: 12),
              InkWell(
                onTap: onRetry,
                child: customText(
                  l10n.retry,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  final int index;
  final AttendanceDay day;

  const _DayCard({required this.index, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final expanded = ref.watch(
      attendanceHistoryNotifierProvider.select(
        (s) => s.expandedIndexes.contains(index),
      ),
    );
    final date = day.date;
    final status = AttendanceHistoryCopy.status(l10n, day);
    final overtimeLine = AttendanceHistoryCopy.overtimeLine(l10n, day);
    // Only read for its shift, so a slow or failing profile lookup just
    // means the generic "Morning"/"Afternoon" fallback shows instead.
    final shiftDetails =
        ref.watch(profileNotifierProvider).valueOrNull?.shiftDetails ??
        const [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => ref
                .read(attendanceHistoryNotifierProvider.notifier)
                .toggleExpanded(index),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DateBadge(date: date, color: status.color),
                widthBx(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        date == null
                            ? ''
                            : AttendanceHistoryCopy.dayTitle(l10n, date),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      heightBx(h: 2),
                      customText(
                        _summaryLine(l10n, day),
                        color: AppColors.subTitle,
                        fontSize: 12,
                      ),
                      if (overtimeLine != null) ...[
                        heightBx(h: 2),
                        customText(
                          overtimeLine,
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ],
                  ),
                ),
                widthBx(w: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusPill(label: status.label, color: status.color),
                    heightBx(h: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.gray500,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (expanded && day.sessions.isNotEmpty) ...[
            heightBx(h: 12),
            const Divider(height: 1, color: AppColors.border),
            heightBx(h: 8),
            for (var i = 0; i < day.sessions.length; i++) ...[
              _SessionRow(
                index: i,
                session: day.sessions[i],
                locale: locale,
                shiftDetails: shiftDetails,
              ),
              // "Forgot to scan" for this session's part (#44).
              if (date != null && _canCorrect(date))
                _CorrectionButton(
                  date: date,
                  session: day.sessions[i],
                ),
            ],
          ],
          // A day with nothing on it: "forgot to scan" with the date only.
          if (expanded &&
              day.sessions.isEmpty &&
              date != null &&
              _canCorrect(date)) ...[
            heightBx(h: 8),
            _CorrectionButton(date: date),
          ],
        ],
      ),
    );
  }

  String _summaryLine(AppLocalizations l10n, AttendanceDay day) {
    final inAt = day.firstClockIn;
    final outAt = day.lastClockOut;
    final hours = day.totalWorkHours;

    final parts = <String>[
      if (inAt != null) '${l10n.timeIn} ${AttendanceCopy.hourMinute(inAt)}',
      if (outAt != null) '${l10n.timeOut} ${AttendanceCopy.hourMinute(outAt)}',
      if (hours != null) '${hours.toStringAsFixed(1)} ${l10n.hoursUnit}',
    ];
    return parts.join(' · ');
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime? date;
  final Color color;

  const _DateBadge({required this.date, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          customText(
            date == null ? '--' : '${date!.day}',
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            alight: TextAlign.center,
          ),
          if (date != null)
            customText(
              AttendanceHistoryCopy.weekdayShort(l10n, date!),
              color: color,
              fontSize: 11,
              alight: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: customText(
        label,
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

/// One punched block of a split day — the sun/moon icon marks whether it's
/// the first (morning) or a later (afternoon) session.
class _SessionRow extends StatelessWidget {
  final int index;
  final AttendanceSession session;
  final Locale locale;
  final List<ShiftDetail> shiftDetails;

  const _SessionRow({
    required this.index,
    required this.session,
    required this.locale,
    required this.shiftDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMorning = index == 0;
    final label =
        AttendanceCopy.sessionPartName(locale, session) ??
        _fallbackLabel(l10n, isMorning);

    final inAt = session.clockIn;
    final outAt = session.clockOut;
    final range = [
      if (inAt != null) AttendanceCopy.hourMinute(inAt),
      if (outAt != null) AttendanceCopy.hourMinute(outAt),
    ].join(' – ');

    final method = session.method;
    final chip = method == null
        ? null
        : [
            AttendanceCopy.methodLabel(l10n, method),
            if (session.locationLabel != null) session.locationLabel!,
          ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            size: 16,
            color: AppColors.gray500,
          ),
          widthBx(w: 8),
          SizedBox(
            width: 64,
            child: customText(label, fontSize: 12, color: AppColors.subTitle),
          ),
          Expanded(
            child: customText(
              range.isEmpty ? '—' : range,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (chip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: customText(
                chip,
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// The employee's real shift-segment name (`shift.shift_details[index]`)
  /// when there is one at that position, else the generic "Morning"/
  /// "Afternoon" copy — for a session `records/my` sent with no
  /// `shift_detail` of its own.
  String _fallbackLabel(AppLocalizations l10n, bool isMorning) {
    if (index < shiftDetails.length) {
      final name = AttendanceCopy.shiftDetailName(locale, shiftDetails[index]);
      if (name.isNotEmpty) return name;
    }
    return isMorning ? l10n.shiftMorningLabel : l10n.shiftAfternoonLabel;
  }
}

/// A day inside "forgot to scan"'s look-back (#43: 30 days, not the future).
bool _canCorrect(DateTime date) =>
    CorrectionRules.inLookBack(date, DateTime.now());

/// "ລືມລົງເວລາ" under a history session (or a day with none): opens the
/// form filled with that day and the session's part (#44).
class _CorrectionButton extends StatelessWidget {
  const _CorrectionButton({required this.date, this.session});

  final DateTime date;
  final AttendanceSession? session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final part = session?.part;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => context.push(
          AppRoutes.timeCorrectionRequestFor(date, partId: part?.id),
          extra: part,
        ),
        icon: const Icon(Icons.more_time, size: 16, color: AppColors.primary),
        label: customText(
          l10n.forgotClockInMenu,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
