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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: customText(
                  l10n.attendanceHistoryTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.attendanceHistory),
                child: Row(
                  children: [
                    customText(
                      l10n.viewAll,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    widthBx(w: 5),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
          heightBx(h: 20),
          if (loading) ...[
            const ShimmerBox(width: double.infinity, height: 25),
            heightBx(),
            generalLine(),
            heightBx(),
            const ShimmerBox(width: double.infinity, height: 25),
            heightBx(),
            const ShimmerBox(width: double.infinity, height: 25),
            heightBx(),
            const ShimmerBox(width: double.infinity, height: 25),
          ] else if (failed) ...[
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
            ),
          ] else ...[
            _SummaryRow(
              color: AppColors.attendancePresent,
              label: l10n.daysPresent,
              value: '${data?.presentDays ?? 0}',
              icon: Icons.check,
            ),
            heightBx(),
            generalLine(),
            heightBx(),
            _SummaryRow(
              color: AppColors.attendanceLate,
              label: l10n.daysLate,
              value: '${data?.lateDays ?? 0}',
              icon: Icons.watch_later_outlined,
            ),
            heightBx(),
            _SummaryRow(
              color: AppColors.attendanceAbsent,
              label: l10n.daysAbsent,
              value: '${data?.absentDays ?? 0}',
              icon: Icons.close,
            ),
            heightBx(),
            _SummaryRow(
              color: AppColors.primary,
              label: l10n.workHours,
              value: (data?.totalWorkHours ?? 0).toStringAsFixed(1),
              icon: Icons.work_outline,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final IconData icon;

  const _SummaryRow({
    required this.color,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 25,
          width: 25,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        widthBx(),
        Expanded(child: customText(label)),
        widthBx(),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: customText(
            value,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
