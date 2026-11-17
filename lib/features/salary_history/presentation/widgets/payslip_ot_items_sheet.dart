import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/ot_pay.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/payslip_record.dart';
import 'payslip_line_copy.dart';
import 'salary_history_copy.dart';

/// Opens the sheet of OT pieces behind a payslip's OT line.
///
/// [total] is the OT line's own amount: the pieces add up to it on the
/// server, and the App does not add them again.
Future<void> showPayslipOtItemsSheet(
  BuildContext context, {
  required List<PayslipOvertimeItem> items,
  required int total,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (_) => PayslipOtItemsSheet(items: items, total: total),
);

/// "ລາຍລະອຽດໂອທີ": one row per OT piece the payslip paid, in the server's
/// order (by piece start), and the OT line's amount as the total.
///
/// A piece is shown with its own date, which may be in an earlier month
/// than the payslip's. A piece that paid nothing is shown too, as 0 minutes
/// and 0, with a note saying why; never as the approved window paid.
class PayslipOtItemsSheet extends StatelessWidget {
  final List<PayslipOvertimeItem> items;
  final int total;

  const PayslipOtItemsSheet({
    super.key,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            heightBx(h: 14),
            customText(
              l10n.payslipOtDetailsTitle,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
            heightBx(h: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.gray200),
                itemBuilder: (_, i) => _PieceRow(
                  key: ValueKey('ot-piece-${items[i].pieceId}'),
                  item: items[i],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.gray200),
            heightBx(h: 12),
            Row(
              children: [
                Expanded(
                  child: customText(
                    l10n.payslipOtTotal,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                widthBx(w: 8),
                customText(
                  SalaryHistoryCopy.amount(total),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One OT piece: date and window on the first line with the amount; the
/// pay and the paid time under them; the note when nothing was paid.
class _PieceRow extends StatelessWidget {
  final PayslipOvertimeItem item;

  const _PieceRow({super.key, required this.item});

  static final _time = DateFormat('HH:mm');

  /// "18:00–20:00", or null when either end is missing.
  static String? _window(PayslipOvertimeItem item) {
    final start = item.startsAt;
    final end = item.endsAt;
    if (start == null || end == null) return null;
    return '${_time.format(start.toLocal())}–${_time.format(end.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workDate = item.workDate;
    final window = _window(item);
    // Nothing paid: no time counted and no money. A piece with money but no
    // minutes (not something the server sends) shows its figures without
    // the note, so the sheet never says "not paid" beside an amount.
    final unpaid = item.paidMinutes == 0 && item.amount == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  children: [
                    if (workDate != null)
                      customText(
                        SalaryHistoryCopy.date(workDate),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    if (window != null)
                      customText(
                        window,
                        fontSize: 14,
                        color: AppColors.secondaryTxt,
                      ),
                  ],
                ),
              ),
              widthBx(w: 8),
              customText(
                SalaryHistoryCopy.amount(item.amount),
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: item.amount == 0
                    ? AppColors.subTitle
                    : AppColors.textPrimary,
              ),
            ],
          ),
          heightBx(h: 4),
          Wrap(
            spacing: 10,
            children: [
              customText(
                otPayLabel(l10n, item.payType, item.payValue),
                fontSize: 12,
                color: AppColors.subTitle,
              ),
              customText(
                PayslipLineCopy.minutes(l10n, item.paidMinutes),
                fontSize: 12,
                color: AppColors.subTitle,
              ),
            ],
          ),
          if (unpaid) ...[
            heightBx(h: 4),
            customText(
              l10n.payslipOtNotPaidNote,
              fontSize: 11,
              color: AppColors.subTitle,
              maxLine: 3,
            ),
          ],
        ],
      ),
    );
  }
}
