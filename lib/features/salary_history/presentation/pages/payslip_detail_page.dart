import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/payslip.dart';
import '../providers/payslip_detail_notifier.dart';
import '../providers/payslip_pdf_notifier.dart';
import '../widgets/salary_error_block.dart';
import '../widgets/salary_history_copy.dart';

/// "ໃບເງິນເດືອນ" — the full breakdown behind a month's card on
/// [SalaryHistoryPage].
///
/// The list row rides along as the route's `extra` and is rendered at once —
/// its header, identity and totals are the same backend figures the detail
/// call returns — while [payslipDetailNotifierProvider] fetches the line
/// items for that payslip's id and fills in the sections below.
class PayslipDetailPage extends ConsumerWidget {
  final Payslip payslip;

  const PayslipDetailPage({super.key, required this.payslip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(payslipDetailNotifierProvider(payslip.id));
    final shown = detail.valueOrNull ?? payslip;

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              _DetailAppBar(payslip: shown),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 20),
                  children: [
                    _EmployeeCard(payslip: shown),
                    heightBx(h: 12),
                    _SummaryStrip(payslip: shown),
                    heightBx(h: 20),
                    if (detail.isLoading && !detail.hasValue)
                      const _SectionsPlaceholder()
                    else if (detail.hasError && !detail.hasValue)
                      SalaryErrorBlock(
                        message: l10n.payslipDetailLoadFailed,
                        onRetry: () => ref
                            .read(
                              payslipDetailNotifierProvider(
                                payslip.id,
                              ).notifier,
                            )
                            .refresh(),
                      )
                    else ...[
                      _Section(
                        title: l10n.salaryIncomeSection,
                        titleColor: AppColors.primary,
                        lines: shown.earnings,
                      ),
                      _Section(
                        title: l10n.salaryAllowancesSection,
                        titleColor: AppColors.primary,
                        lines: shown.allowances,
                        bulleted: true,
                      ),
                      _Section(
                        title: l10n.salaryAttendanceDeductionsSection,
                        titleColor: AppColors.danger,
                        lines: shown.attendanceDeductions,
                      ),
                      _Section(
                        title: l10n.salaryStatutoryDeductionsSection,
                        titleColor: AppColors.danger,
                        lines: shown.statutoryDeductions,
                      ),
                    ],
                  ],
                ),
              ),
              // Pinned under the scrolling breakdown so the headline net is
              // always in view.
              _FooterCard(payslip: shown),
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

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(onTap: () => context.pop(), child: popBack()),
              _SaveButton(payslip: payslip),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                customText(
                  title,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  alight: TextAlign.center,
                ),
                heightBx(h: 2),
                customText(
                  paidLine,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SalaryHistoryCopy.statusColor(payslip.status),
                  alight: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the four line-item sections while the detail call is in
/// flight — the same shimmer the history list uses.
class _SectionsPlaceholder extends StatelessWidget {
  const _SectionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: ShimmerBox(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
    );
  }
}

/// The app bar's save icon — fetches this payslip's PDF and hands it to the
/// system save dialog, spinning while the download runs. Shares its state
/// with the history card's "Download Payslip (PDF)" button.
class _SaveButton extends ConsumerWidget {
  final Payslip payslip;

  const _SaveButton({required this.payslip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = payslipPdfNotifierProvider(payslip.id);
    final downloading = ref.watch(provider).isLoading;

    ref.listen(provider, (previous, next) {
      next.whenOrNull(
        data: (path) {
          if (path != null) AppToast.success(l10n.salaryPdfSaved);
        },
        error: (error, _) => AppToast.error(
          error is Failure ? error.localize(l10n) : error.toString(),
        ),
      );
    });

    return GestureDetector(
      onTap: () => ref.read(provider.notifier).download(payslip),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: downloading
            ? const Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.save_alt, color: AppColors.primary, size: 22),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: customText(
              _initials(payslip.employeeName),
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
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
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
                heightBx(h: 4),
                _Identity(payslip: payslip),
              ],
            ),
          ),
          widthBx(w: 8),
          _StatusPill(
            label: SalaryHistoryCopy.statusLabel(l10n, payslip.status),
            status: payslip.status,
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

/// Employee code in a grey chip, then the position and — in the brand blue —
/// the department, dot-separated.
class _Identity extends StatelessWidget {
  final Payslip payslip;

  const _Identity({required this.payslip});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: customText(
            payslip.employeeCode,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTxt,
          ),
        ),
        if (payslip.position.isNotEmpty)
          customText(
            '•  ${payslip.position}',
            fontSize: 12,
            color: AppColors.subTitle,
          ),
        if (payslip.department.isNotEmpty)
          customText(
            '•  ${payslip.department}',
            fontSize: 12,
            color: AppColors.primary,
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final PayslipStatus status;

  const _StatusPill({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = SalaryHistoryCopy.statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == PayslipStatus.paid
                ? Icons.check_circle
                : Icons.access_time_filled,
            size: 14,
            color: color,
          ),
          widthBx(w: 5),
          customText(
            label,
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ],
      ),
    );
  }
}

/// Gross / deductions / net as three white cards on a soft blue tray — the
/// totals strip below the employee card. The net card carries a blue outline.
class _SummaryStrip extends StatelessWidget {
  final Payslip payslip;

  const _SummaryStrip({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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
          widthBx(w: 8),
          Expanded(
            child: _SummaryColumn(
              label: l10n.salaryTotalDeductionsLabel,
              value: '-${SalaryHistoryCopy.amount(payslip.totalDeductions)}',
              color: AppColors.danger,
            ),
          ),
          widthBx(w: 8),
          Expanded(
            child: _SummaryColumn(
              label: l10n.salaryNetSalaryLabel,
              value: SalaryHistoryCopy.amount(payslip.netSalary),
              color: AppColors.primary,
              highlighted: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlighted;

  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: _cardDecoration(
        radius: 16,
        border: highlighted
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.2,
              )
            : null,
      ),
      child: Column(
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
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled group of [PayslipLine]s in one white card. Renders nothing when
/// [lines] is empty, so a payslip that only feeds the history list doesn't
/// leave a stray header behind.
///
/// [bulleted] puts a green dot in front of each row — for lines that carry no
/// icon and no caption, like the allowances.
class _Section extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<PayslipLine> lines;
  final bool bulleted;

  const _Section({
    required this.title,
    required this.titleColor,
    required this.lines,
    this.bulleted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: titleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              widthBx(w: 8),
              Expanded(
                child: customText(
                  title,
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          heightBx(h: 10),
          Container(
            decoration: _cardDecoration(radius: 20),
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.gray200,
                    ),
                  _LineRow(line: lines[i], bulleted: bulleted),
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
  final bool bulleted;

  const _LineRow({required this.line, required this.bulleted});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final glyph = _iconFor(line.icon);
    final caption = SalaryHistoryCopy.lineCaption(l10n, line);
    // Late / early-out captions pick up the icon's amber; the rest stay grey.
    final captionColor = glyph?.color == AppColors.attendanceLate
        ? AppColors.attendanceLate
        : AppColors.subTitle;
    final amountColor = line.amount == 0
        ? AppColors.subTitle
        : line.amount < 0
        ? AppColors.danger
        : AppColors.success;
    final sign = line.amount < 0 ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (glyph != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: glyph.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(glyph.icon, size: 20, color: glyph.color),
            ),
            widthBx(w: 12),
          ] else if (bulleted) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            widthBx(w: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  SalaryHistoryCopy.lineTitle(l10n, line),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                if (caption.isNotEmpty) ...[
                  heightBx(h: 2),
                  customText(caption, color: captionColor, fontSize: 11),
                ],
              ],
            ),
          ),
          widthBx(w: 8),
          customText(
            '$sign ${SalaryHistoryCopy.amount(line.amount.abs())}',
            color: amountColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}

/// Icon + tint for a deduction line; `null` for [PayslipLineIcon.none], which
/// the earnings sections use.
({IconData icon, Color color})? _iconFor(
  PayslipLineIcon kind,
) => switch (kind) {
  PayslipLineIcon.none => null,
  PayslipLineIcon.lateArrival => (
    icon: Icons.history,
    color: AppColors.attendanceLate,
  ),
  PayslipLineIcon.absentLate => (
    icon: Icons.schedule,
    color: AppColors.gray600,
  ),
  PayslipLineIcon.earlyOut => (
    icon: Icons.logout,
    color: AppColors.attendanceLate,
  ),
  PayslipLineIcon.absence => (icon: Icons.event_busy, color: AppColors.danger),
  PayslipLineIcon.socialSecurity => (
    icon: Icons.shield,
    color: AppColors.primary,
  ),
  PayslipLineIcon.incomeTax => (icon: Icons.account_balance, color: _indigo),
  PayslipLineIcon.otherDeduction => (icon: Icons.favorite, color: _purple),
};

// Tints for the tax and "other deduction" glyphs that the shared palette has
// no name for.
const Color _indigo = Color(0xFF5B5BD6);
const Color _purple = Color(0xFF9B5CF6);

/// White card with the soft blue shadow every block on this page shares.
BoxDecoration _cardDecoration({required double radius, BoxBorder? border}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

/// Taxable-income / SS-base figures and the headline net, in the white bar
/// pinned to the bottom of the payslip.
class _FooterCard extends StatelessWidget {
  final Payslip payslip;

  const _FooterCard({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          _FooterRow(
            label: l10n.salaryTaxableIncomeLabel,
            value: SalaryHistoryCopy.amount(payslip.taxableIncome),
          ),
          // The backend doesn't report the SS base yet; the row waits for it.
          if (payslip.socialSecurityBase > 0) ...[
            heightBx(h: 8),
            _FooterRow(
              label: l10n.salarySocialSecurityBaseLabel,
              value: SalaryHistoryCopy.amount(payslip.socialSecurityBase),
            ),
          ],
          heightBx(h: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: customText(
                  l10n.salaryNetSalaryLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
              widthBx(w: 8),
              customText(
                '₭${SalaryHistoryCopy.amount(payslip.netSalary)}',
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 24,
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
          child: customText(label, color: AppColors.secondaryTxt, fontSize: 13),
        ),
        widthBx(w: 8),
        customText(
          value,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ],
    );
  }
}
