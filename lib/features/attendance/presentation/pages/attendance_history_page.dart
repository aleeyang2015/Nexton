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
                    _SummaryRow(summary: state.summary),
                    heightBx(h: 20),
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
      return const Row(
        children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: 96)),
          SizedBox(width: 10),
          Expanded(child: ShimmerBox(width: double.infinity, height: 96)),
          SizedBox(width: 10),
          Expanded(child: ShimmerBox(width: double.infinity, height: 96)),
        ],
      );
    }

    // A failed summary used to fall through to "0 / 0 / 0.0", which read as
    // real data. Surface the failure instead, with the same retry the records
    // list offers (both reload together).
    if (summary.hasError) {
      return _SummaryError(
        onRetry: () =>
            ref.read(attendanceHistoryNotifierProvider.notifier).retry(),
      );
    }

    final data = summary.valueOrNull;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            color: AppColors.attendancePresent,
            icon: Icons.check,
            value: '${data?.presentDays ?? 0}',
            label: l10n.daysPresent,
          ),
        ),
        widthBx(w: 10),
        Expanded(
          child: _SummaryCard(
            color: AppColors.attendanceLate,
            icon: Icons.access_time,
            value: '${data?.lateDays ?? 0}',
            label: l10n.daysLate,
          ),
        ),
        widthBx(w: 10),
        Expanded(
          child: _SummaryCard(
            color: AppColors.primary,
            icon: Icons.trending_up,
            value: (data?.totalWorkHours ?? 0).toStringAsFixed(1),
            label: l10n.workHours,
          ),
        ),
      ],
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
        message: l10n.attendanceLoadFailed,
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
/// keeps the daily records list below it visible and usable.
class _SummaryError extends StatelessWidget {
  final VoidCallback onRetry;

  const _SummaryError({required this.onRetry});

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
              l10n.attendanceLoadFailed,
              color: AppColors.subTitle,
              fontSize: 13,
              maxLine: 2,
            ),
          ),
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
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.message, required this.onRetry});

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
            customText(message, color: AppColors.subTitle, alight: TextAlign.center),
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
            for (var i = 0; i < day.sessions.length; i++)
              _SessionRow(
                index: i,
                session: day.sessions[i],
                locale: locale,
                shiftDetails: shiftDetails,
              ),
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
    final label = session.label ?? _fallbackLabel(l10n, isMorning);

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
  /// `session_label` of its own.
  String _fallbackLabel(AppLocalizations l10n, bool isMorning) {
    if (index < shiftDetails.length) {
      final name = AttendanceCopy.shiftDetailName(locale, shiftDetails[index]);
      if (name.isNotEmpty) return name;
    }
    return isMorning ? l10n.shiftMorningLabel : l10n.shiftAfternoonLabel;
  }
}
