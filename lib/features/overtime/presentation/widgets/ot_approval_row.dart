import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ot_request.dart';
import 'ot_copy.dart';

/// One OT request on the head's approvals tab (#48): who asked (name,
/// number, department), the day and window ("(ມື້ຖັດໄປ)" past midnight),
/// the reason in two lines, and — waiting — how long it has waited, or —
/// decided — where the request stands now. A tap opens its page ([onTap]).
class OtApprovalRow extends StatelessWidget {
  const OtApprovalRow({
    super.key,
    required this.request,
    required this.waiting,
    required this.now,
    this.onTap,
  });

  final OtRequest request;

  /// On the waiting list: "waiting {n} h" in place of the status pill.
  final bool waiting;

  /// The phone's clock, for how long it has waited.
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workDate = request.workDate;
    final window = OtCopy.window(l10n, request);
    final reason = request.reason;
    final who = OtCopy.employeeLine(l10n, request);
    final side = waiting
        ? OtCopy.waitingHours(l10n, request, now)
        : OtCopy.decidedPill(l10n, request);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: customText(
                        request.employeeName ?? request.employeeNumber ?? '',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (side != null) ...[
                      widthBx(w: 8),
                      _Pill(label: side.label, color: side.color),
                    ],
                  ],
                ),
                if (who.isNotEmpty) ...[
                  heightBx(h: 2),
                  customText(who, fontSize: 12, color: AppColors.subTitle),
                ],
                heightBx(h: 8),
                customText(
                  [
                    if (workDate != null) OtCopy.date(workDate),
                    if (window.isNotEmpty) window,
                  ].join(' · '),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                if (reason != null) ...[
                  heightBx(h: 6),
                  customText(
                    reason,
                    fontSize: 13,
                    color: AppColors.subTitle,
                    maxLine: 2,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: customText(
      label,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}
