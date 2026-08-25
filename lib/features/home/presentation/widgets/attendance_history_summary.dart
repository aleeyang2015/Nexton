import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Card of attendance stats under the home screen's clock card: days
/// present/late/absent and total hours worked this period.
///
/// Static for now, like `AttendanceStatusCard.methods`: the API has no
/// endpoint that reports these totals yet.
class AttendanceHistorySummary extends StatelessWidget {
  const AttendanceHistorySummary({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
                },
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
          _SummaryRow(
            color: AppColors.attendancePresent,
            label: l10n.daysPresent,
            value: "18",
            icon: Icons.check,
          ),
          heightBx(),
          generalLine(),
          heightBx(),
          _SummaryRow(
            color: AppColors.attendanceLate,
            label: l10n.daysLate,
            value: "3",
            icon: Icons.watch_later_outlined,
          ),
          heightBx(),
          _SummaryRow(
            color: AppColors.attendanceAbsent,
            label: l10n.daysAbsent,
            value: "1",
            icon: Icons.close,
          ),
          heightBx(),
          _SummaryRow(
            color: AppColors.primary,
            label: l10n.workHours,
            value: "140",
            icon: Icons.work_outline,
          ),
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
