import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/payslip.dart';
import '../widgets/salary_history_copy.dart';

/// "ໃບເງິນເດືອນ" — the full breakdown behind a month's card on
/// [SalaryHistoryPage]. Purely a renderer for the [Payslip] handed to it via
/// the route's `extra`; it fetches nothing and owns no state.
class PayslipDetailPage extends StatelessWidget {
  final Payslip payslip;

  const PayslipDetailPage({super.key, required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              heightBx(h: 4),
              _DetailAppBar(payslip: payslip),
              heightBx(h: 6),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 40),
                  children: [
                    _EmployeeCard(payslip: payslip),
                    heightBx(h: 14),
                    _SummaryStrip(payslip: payslip),
                    heightBx(h: 22),
                    _Section(
                      title: l10n.salaryIncomeSection,
                      titleColor: AppColors.primary,
                      lines: payslip.earnings,
                    ),
                    _Section(
                      title: l10n.salaryAllowancesSection,
                      titleColor: AppColors.primary,
                      lines: payslip.allowances,
                    ),
                    _Section(
                      title: l10n.salaryAttendanceDeductionsSection,
                      titleColor: AppColors.danger,
                      lines: payslip.attendanceDeductions,
                    ),
                    _Section(
                      title: l10n.salaryStatutoryDeductionsSection,
                      titleColor: AppColors.danger,
                      lines: payslip.statutoryDeductions,
                    ),
                    _FooterCard(payslip: payslip),
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

class _DetailAppBar extends StatelessWidget {
  final Payslip payslip;

  const _DetailAppBar({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title =
        '${l10n.payslipDetailTitle} – '
        '${SalaryHistoryCopy.monthYear(l10n, payslip.month, payslip.year)}';
    final paidLine = payslip.paidDate == null
        ? SalaryHistoryCopy.statusLabel(l10n, payslip.status)
        : '${l10n.salaryPaidOnLabel} ${SalaryHistoryCopy.date(payslip.paidDate!)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: popBack(),
                  ),
                  IconButton(
                    onPressed: () => _notifyDownloadComingSoon(context),
                    icon: const Icon(Icons.save_alt, color: AppColors.primary),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: customText(
                  title,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  alight: TextAlign.center,
                ),
              ),
            ],
          ),
          heightBx(h: 2),
          customText(
            paidLine,
            fontSize: 12,
            color: AppColors.subTitle,
            alight: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Payslip payslip;

  const _EmployeeCard({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final identity = [
      payslip.employeeCode,
      payslip.position,
      if (payslip.department.isNotEmpty) payslip.department,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: customText(
              _initials(payslip.employeeName),
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          widthBx(w: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  payslip.employeeName,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                heightBx(h: 3),
                customText(
                  identity,
                  color: AppColors.subTitle,
                  fontSize: 12,
                  maxLine: 2,
                ),
              ],
            ),
          ),
          widthBx(w: 8),
          _StatusPill(
            label: SalaryHistoryCopy.statusLabel(l10n, payslip.status),
            color: SalaryHistoryCopy.statusColor(payslip.status),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: color),
          widthBx(w: 4),
          customText(label, color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ],
      ),
    );
  }
}

/// Gross / deductions / net, three columns divided by hairlines — the totals
/// strip below the employee card.
class _SummaryStrip extends StatelessWidget {
  final Payslip payslip;

  const _SummaryStrip({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryColumn(
              label: l10n.salaryGrossLabel,
              value: SalaryHistoryCopy.amount(payslip.grossSalary),
              color: AppColors.success,
            ),
          ),
          _hairline(),
          Expanded(
            child: _SummaryColumn(
              label: l10n.salaryTotalDeductionsLabel,
              value: '-${SalaryHistoryCopy.amount(payslip.totalDeductions)}',
              color: AppColors.danger,
            ),
          ),
          _hairline(),
          Expanded(
            child: _SummaryColumn(
              label: l10n.salaryNetSalaryLabel,
              value: SalaryHistoryCopy.amount(payslip.netSalary),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hairline() => Container(
    width: 1,
    height: 34,
    color: AppColors.primary.withValues(alpha: 0.15),
  );
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        customText(
          label,
          color: AppColors.subTitle,
          fontSize: 12,
          alight: TextAlign.center,
        ),
        heightBx(h: 6),
        FittedBox(
          child: customText(
            value,
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

/// A titled group of [PayslipLine]s in one white card. Renders nothing when
/// [lines] is empty, so a payslip that only feeds the history list doesn't
/// leave a stray header behind.
class _Section extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<PayslipLine> lines;

  const _Section({
    required this.title,
    required this.titleColor,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            title,
            color: titleColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          heightBx(h: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.border),
                  _LineRow(line: lines[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final PayslipLine line;

  const _LineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final glyph = _iconFor(line.icon);
    final amountColor = line.amount == 0
        ? AppColors.subTitle
        : line.amount < 0
        ? AppColors.danger
        : AppColors.success;
    final sign = line.amount < 0 ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (glyph != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: glyph.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(glyph.icon, size: 18, color: glyph.color),
            ),
            widthBx(w: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  line.title,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                if (line.caption.isNotEmpty) ...[
                  heightBx(h: 2),
                  customText(
                    line.caption,
                    color: AppColors.subTitle,
                    fontSize: 11,
                  ),
                ],
              ],
            ),
          ),
          widthBx(w: 8),
          customText(
            '$sign ${SalaryHistoryCopy.amount(line.amount.abs())}',
            color: amountColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

/// Icon + tint for a deduction line; `null` for [PayslipLineIcon.none], which
/// the earnings sections use.
({IconData icon, Color color})? _iconFor(PayslipLineIcon kind) => switch (kind) {
  PayslipLineIcon.none => null,
  PayslipLineIcon.lateArrival => (
    icon: Icons.history,
    color: AppColors.attendanceLate,
  ),
  PayslipLineIcon.absentLate => (
    icon: Icons.schedule,
    color: AppColors.gray500,
  ),
  PayslipLineIcon.earlyOut => (icon: Icons.logout, color: AppColors.gray500),
  PayslipLineIcon.absence => (
    icon: Icons.event_busy,
    color: AppColors.danger,
  ),
  PayslipLineIcon.socialSecurity => (
    icon: Icons.shield,
    color: AppColors.primary,
  ),
  PayslipLineIcon.incomeTax => (
    icon: Icons.account_balance,
    color: AppColors.primary,
  ),
  PayslipLineIcon.otherDeduction => (
    icon: Icons.favorite,
    color: AppColors.primary,
  ),
};

/// Taxable-income / SS-base figures and the headline net, in the tinted card
/// that closes the payslip.
class _FooterCard extends StatelessWidget {
  final Payslip payslip;

  const _FooterCard({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _FooterRow(
            label: l10n.salaryTaxableIncomeLabel,
            value: SalaryHistoryCopy.amount(payslip.taxableIncome),
          ),
          heightBx(h: 10),
          _FooterRow(
            label: l10n.salarySocialSecurityBaseLabel,
            value: SalaryHistoryCopy.amount(payslip.socialSecurityBase),
          ),
          heightBx(h: 12),
          const _DottedLine(),
          heightBx(h: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: customText(
                  l10n.salaryNetSalaryLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              widthBx(w: 8),
              customText(
                'K ${SalaryHistoryCopy.amount(payslip.netSalary)}',
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  final String label;
  final String value;

  const _FooterRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: customText(
            label,
            color: AppColors.secondaryTxt,
            fontSize: 13,
          ),
        ),
        widthBx(w: 8),
        customText(
          value,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ],
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 3.0;
          const gap = 4.0;
          final count = (constraints.maxWidth / (dashWidth + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                width: dashWidth,
                height: 1,
                color: AppColors.gray400,
              ),
            ),
          );
        },
      ),
    );
  }
}

void _notifyDownloadComingSoon(BuildContext context) {
  AppToast.info(AppLocalizations.of(context)!.comingSoon);
}
