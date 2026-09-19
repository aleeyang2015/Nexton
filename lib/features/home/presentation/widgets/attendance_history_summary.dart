import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/presentation/providers/attendance_month_summary_notifier.dart';

/// Card of attendance stats under the home screen's clock card: this
/// month's present/late/absent days and total hours worked, from
/// [attendanceMonthSummaryNotifierProvider]. "View all" opens
/// [AttendanceHistoryPage], which covers the same data with a month picker.
class AttendanceHistorySummary extends ConsumerWidget {
  const AttendanceHistorySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(attendanceMonthSummaryNotifierProvider);
    final loading = summary.isLoading && !summary.hasValue;
    final failed = summary.hasError;
    final data = summary.valueOrNull;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SummaryHeader(),
          heightBx(h: 12),
          if (loading)
            const _SummaryLoading()
          else if (failed)
            Row(
              children: [
                Expanded(
                  child: customText(
                    l10n.attendanceLoadFailed,
                    color: AppColors.subTitle,
                    fontSize: 13,
                  ),
                ),
                InkWell(
                  onTap: () => ref
                      .read(attendanceMonthSummaryNotifierProvider.notifier)
                      .refresh(),
                  child: customText(
                    l10n.retry,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            _SummaryGrid(
              tiles: [
                _SummaryTile(
                  color: AppColors.attendancePresent,
                  label: l10n.daysPresent,
                  value: '${data?.presentDays ?? 0}',
                  unit: l10n.salaryUnitDays,
                  icon: Icons.check,
                ),
                _SummaryTile(
                  color: AppColors.attendanceLate,
                  label: l10n.daysLate,
                  value: '${data?.lateDays ?? 0}',
                  unit: l10n.salaryUnitTimes,
                  icon: Icons.watch_later_outlined,
                ),
                _SummaryTile(
                  color: AppColors.attendanceAbsent,
                  label: l10n.daysAbsent,
                  value: '${data?.absentDays ?? 0}',
                  unit: l10n.salaryUnitDays,
                  icon: Icons.close,
                ),
                _SummaryTile(
                  color: AppColors.primary,
                  label: l10n.workHours,
                  value: (data?.totalWorkHours ?? 0).toStringAsFixed(1),
                  unit: l10n.hoursUnit,
                  icon: Icons.work_outline,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Blue-dot title on the left, tinted "view all" pill on the right.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        widthBx(w: 8),
        Expanded(
          child: customText(
            l10n.attendanceHistoryTitle,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        widthBx(w: 8),
        Material(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => context.push(AppRoutes.attendanceHistory),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  customText(
                    l10n.viewAll,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  widthBx(w: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 11,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lays [tiles] out two per row with equal-height tiles in each row.
class _SummaryGrid extends StatelessWidget {
  final List<Widget> tiles;

  const _SummaryGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) heightBx(h: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                widthBx(w: 8),
                Expanded(
                  child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Sweeping placeholder for the four stat tiles while the month summary
/// loads — wrapped in [Shimmer] so it animates like the rest of the home
/// screen's loading state instead of sitting as flat grey bars.
class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: _SummaryGrid(
        tiles: [
          for (var i = 0; i < 4; i++)
            const ShimmerBox(width: double.infinity, height: 76),
        ],
      ),
    );
  }
}

/// One stat: label and icon badge on top, big value with its unit below, on
/// a soft [color]-tinted background.
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
                  padding: const EdgeInsets.only(top: 4),
                  child: customText(
                    label,
                    fontSize: 12,
                    maxLine: 2,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
              ),
              widthBx(w: 6),
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
            ],
          ),
          heightBx(h: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              customText(
                value,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              widthBx(w: 4),
              Expanded(
                child: customText(unit, fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
