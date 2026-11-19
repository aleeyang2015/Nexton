import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/presentation/providers/attendance_month_summary_notifier.dart';
import '../../../attendance/presentation/widgets/attendance_copy.dart';
import '../../../attendance/presentation/widgets/attendance_history_copy.dart';

/// Attendance stats under the home screen's clock card: this month's days as
/// the server counted them — present, late, half day, incomplete, absent and
/// leave — the hours worked and the approved OT hours, out of the month's
/// working days. All from
/// [attendanceMonthSummaryNotifierProvider]. "View all" opens
/// [AttendanceHistoryPage], which covers the same data with a month picker.
///
/// The stats are small white tiles straight on the home background, four to
/// a row, rather than inside a card of their own — the card wrapper was what
/// made this block tower over the clock card above it.
///
/// A load that failed says so in one line. It never shows zeros: they would
/// read as real numbers.
class AttendanceHistorySummary extends ConsumerWidget {
  const AttendanceHistorySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(attendanceMonthSummaryNotifierProvider);
    final loading = summary.isLoading && !summary.hasValue;
    final failed = summary.hasError;
    final data = summary.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SummaryHeader(),
        heightBx(h: 10),
        if (loading)
          const _SummaryLoading()
        else if (failed || data == null)
          _SummaryFailed(
            failure: AttendanceCopy.monthLoadFailure(l10n, summary.error),
            onRetry: () => ref
                .read(attendanceMonthSummaryNotifierProvider.notifier)
                .refresh(),
          )
        else ...[
          customText(
            l10n.attWorkingDaysBase(data.totalWorkingDays),
            color: AppColors.subTitle,
            fontSize: 12,
          ),
          heightBx(h: 8),
          _SummaryRow(
            tiles: [
              _SummaryTile(
                color: AppColors.attendancePresent,
                label: l10n.daysPresent,
                value: '${data.presentDays}',
                unit: l10n.salaryUnitDays,
                icon: Icons.check,
              ),
              _SummaryTile(
                color: AppColors.attendanceLate,
                label: l10n.daysLate,
                value: '${data.lateDays}',
                unit: l10n.salaryUnitTimes,
                icon: Icons.watch_later_outlined,
              ),
              _SummaryTile(
                color: AppColors.gray600,
                label: l10n.attendanceHalfDayStatus,
                value: '${data.halfDays}',
                unit: l10n.salaryUnitDays,
                icon: Icons.timelapse,
              ),
              _SummaryTile(
                color: AppColors.attendanceLate,
                label: l10n.attendanceIncompleteStatus,
                value: '${data.incompleteDays}',
                unit: l10n.salaryUnitDays,
                icon: Icons.more_horiz,
              ),
            ],
          ),
          heightBx(h: 8),
          _SummaryRow(
            tiles: [
              _SummaryTile(
                color: AppColors.attendanceAbsent,
                label: l10n.daysAbsent,
                value: '${data.absentDays}',
                unit: l10n.salaryUnitDays,
                icon: Icons.close,
              ),
              _SummaryTile(
                color: AppColors.secondary,
                label: l10n.leaveDays,
                value: '${data.leaveDays}',
                unit: l10n.salaryUnitDays,
                icon: Icons.event_available_outlined,
              ),
              _SummaryTile(
                color: AppColors.primary,
                label: l10n.workHours,
                value: data.totalWorkHours.toStringAsFixed(1),
                unit: l10n.hoursUnit,
                icon: Icons.work_outline,
              ),
              // Approved OT only, as the server totals it.
              _SummaryTile(
                color: AppColors.primary,
                label: l10n.salaryOvertimeLabel,
                value: AttendanceHistoryCopy.hours(data.totalOvertimeHours),
                unit: l10n.hoursUnit,
                icon: Icons.more_time,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The month's numbers could not be loaded: one line saying why, and a Retry
/// only when trying again can help.
class _SummaryFailed extends StatelessWidget {
  final ({String message, bool canRetry}) failure;
  final VoidCallback onRetry;

  const _SummaryFailed({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: customText(
            failure.message,
            color: AppColors.subTitle,
            fontSize: 12,
            maxLine: 3,
          ),
        ),
        if (failure.canRetry) ...[
          widthBx(w: 8),
          InkWell(
            onTap: onRetry,
            child: customText(
              l10n.retry,
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

/// Haloed blue-dot title on the left, a plain "view all" link on the right.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        widthBx(w: 8),
        Expanded(
          child: customText(
            l10n.homeMonthStatsTitle,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        widthBx(w: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push(AppRoutes.attendanceHistory),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                customText(
                  l10n.viewDetails,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                widthBx(w: 2),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Lays [tiles] out side by side in one row, all the same height.
class _SummaryRow extends StatelessWidget {
  final List<Widget> tiles;

  const _SummaryRow({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) widthBx(w: 8),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

/// Sweeping placeholder for the two rows of stat tiles while the month
/// summary loads — wrapped in [Shimmer] so it animates like the rest of the
/// home screen's loading state instead of sitting as flat grey bars.
class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) heightBx(h: 8),
            _SummaryRow(
              tiles: [
                for (var i = 0; i < 4; i++)
                  const ShimmerBox(width: double.infinity, height: 78),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One stat on a white tile: label and a [color]-tinted round icon badge on
/// top, value with its unit below. The value row scales itself down rather
/// than overflowing, since four tiles to a row leaves each one narrow.
class _SummaryTile extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _SummaryTile({
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: customText(
                    label,
                    fontSize: 11,
                    maxLine: 2,
                    color: AppColors.secondaryTxt,
                  ),
                ),
              ),
              widthBx(w: 4),
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          heightBx(h: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                customText(
                  value,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
                widthBx(w: 4),
                customText(unit, fontSize: 11, color: AppColors.gray500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
