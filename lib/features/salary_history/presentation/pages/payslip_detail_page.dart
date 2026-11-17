import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/payslip_record.dart';
import '../../domain/payslip_lines.dart';
import '../providers/payslip_detail_notifier.dart';
import '../providers/payslip_pdf_notifier.dart';
import '../widgets/payslip_line_copy.dart';
import '../widgets/payslip_ot_items_sheet.dart';
import '../widgets/salary_error_block.dart';
import '../widgets/salary_history_copy.dart';

/// "ໃບເງິນເດືອນ" — one payslip in full, opened by its id from the salary
/// list, a link or a push.
///
/// [payslipDetailNotifierProvider] loads the payslip. [listRow] is the
/// list's row for it, when the list opened the page: its header and totals
/// are shown at once while the lines load.
///
/// Every figure is the server's. The page adds nothing up, shows every line
/// the server sends (those of zero too), and takes the month from the pay
/// period, never from the day the payslip was made. Which group a line is
/// in, its title and its caption come from `domain/payslip_lines.dart`.
class PayslipDetailPage extends ConsumerWidget {
  final String payslipId;
  final PayslipRecord? listRow;

  const PayslipDetailPage({super.key, required this.payslipId, this.listRow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(payslipDetailNotifierProvider(payslipId));
    final loaded = detail.valueOrNull;
    final error = detail.hasError ? detail.error : null;

    void retry() =>
        ref.read(payslipDetailNotifierProvider(payslipId).notifier).retry();

    // An answer that asking again cannot change takes the whole page: the
    // payslip is not there, or the company has no payroll. The list's row is
    // not shown under it; it would pass for a payslip that can be opened.
    if (loaded == null && error != null && !detail.isLoading) {
      if (SalaryErrorBlock.isNotFound(error)) {
        return _PageFrame(
          child: _NotAvailable(
            message: l10n.payslipNotAvailable,
            backLabel: l10n.back,
          ),
        );
      }
      if (SalaryErrorBlock.isModuleOff(error)) {
        return _PageFrame(
          child: SalaryErrorBlock.forFailure(
            l10n: l10n,
            error: error,
            fallbackMessage: l10n.payslipDetailLoadFailed,
            onRetry: retry,
          ),
        );
      }
    }

    // The list's row is only used when it is this payslip: another one's
    // month and totals must never stand in for it.
    final row = listRow?.id == payslipId ? listRow : null;
    final shown = loaded ?? row;

    // Opened by id alone, and nothing has arrived yet.
    if (shown == null) {
      return _PageFrame(
        child: error != null && !detail.isLoading
            ? SalaryErrorBlock.forFailure(
                l10n: l10n,
                error: error,
                fallbackMessage: l10n.payslipDetailLoadFailed,
                onRetry: retry,
              )
            : error != null
            // A retry is on its way: say so, without the first-load
            // placeholder flashing back.
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : const Padding(
                padding: EdgeInsets.fromLTRB(15, 14, 15, 20),
                child: _SectionsPlaceholder(),
              ),
      );
    }

    final sections = loaded == null ? null : groupLines(loaded);

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
                    if (SalaryHistoryCopy.isPaymentFailed(shown)) ...[
                      heightBx(h: 12),
                      _PaymentFailedNotice(
                        message: l10n.salaryPaymentFailedContactHr,
                      ),
                    ],
                    heightBx(h: 12),
                    _SummaryStrip(payslip: shown),
                    heightBx(h: 20),
                    if (loaded != null && sections != null)
                      _Sections(sections: sections, payslip: loaded)
                    else if (error != null && !detail.isLoading)
                      // The header above is the list's row; the lines could
                      // not be loaded.
                      SalaryErrorBlock.forFailure(
                        l10n: l10n,
                        error: error,
                        fallbackMessage: l10n.payslipDetailLoadFailed,
                        onRetry: retry,
                      )
                    else if (error != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      const _SectionsPlaceholder(),
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

/// Back to the page underneath; opened from a link there may be none, and
/// the salary list is where to go.
void _goBack(BuildContext context) => context.canPop()
    ? context.pop()
    : context.go(AppRoutes.salaryHistory);

/// The page when there is no payslip to show: the title bar with its back
/// arrow, and [child] under it.
class _PageFrame extends StatelessWidget {
  final Widget child;

  const _PageFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _goBack(context),
                      child: popBack(),
                    ),
                    widthBx(w: 4),
                    Expanded(
                      child: customText(
                        l10n.payslipDetailTitle,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// "This payslip is not available", with a Back button and no Retry.
class _NotAvailable extends StatelessWidget {
  final String message;
  final String backLabel;

  const _NotAvailable({required this.message, required this.backLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.gray500,
              size: 40,
            ),
            heightBx(h: 12),
            customText(
              message,
              color: AppColors.subTitle,
              alight: TextAlign.center,
              maxLine: 3,
            ),
            heightBx(h: 16),
            OutlinedButton(
              onPressed: () => _goBack(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: customText(
                backLabel,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final PayslipRecord payslip;

  const _DetailAppBar({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final header = SalaryHistoryCopy.detailHeader(l10n, payslip);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(onTap: () => _goBack(context), child: popBack()),
              _SaveButton(
                payslipId: payslip.id,
                fileName: header.pdfFileName,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                customText(
                  header.title,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  alight: TextAlign.center,
                ),
                if (header.subtitle.isNotEmpty) ...[
                  heightBx(h: 2),
                  customText(
                    header.subtitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: header.color,
                    alight: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two soft blocks standing in for the sections while the lines load.
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
/// with the history card's download button for the same payslip.
class _SaveButton extends ConsumerWidget {
  final String payslipId;

  /// The name the saved PDF gets when the server sends none.
  final String fileName;

  const _SaveButton({required this.payslipId, required this.fileName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = payslipPdfNotifierProvider(payslipId);
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
      onTap: () =>
          ref.read(provider.notifier).download(defaultFileName: fileName),
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
            : const Icon(Icons.save_alt, color: AppColors.primary, size: 20),
      ),
    );
  }
}

/// Who the payslip is for, and where it stands.
class _EmployeeCard extends StatelessWidget {
  final PayslipRecord payslip;

  const _EmployeeCard({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final header = SalaryHistoryCopy.detailHeader(l10n, payslip);
    final pill = header.pill;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
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
                  payslip.employeeName.trim(),
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
                heightBx(h: 4),
                _Identity(payslip: payslip),
              ],
            ),
          ),
          if (pill != null) ...[
            widthBx(w: 8),
            _StatusPill(
              label: pill,
              color: header.color,
              icon: header.failed ? Icons.error : Icons.check_circle,
            ),
          ],
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    // By character, not by code unit: a name can start with a letter (or an
    // emoji) that takes two.
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }
}

/// Employee number in a grey chip, then the position and — in the brand
/// blue — the department, dot-separated. A part the server did not send is
/// left out.
class _Identity extends StatelessWidget {
  final PayslipRecord payslip;

  const _Identity({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final number = payslip.employeeNumber.trim();
    final position = payslip.positionTitle?.trim() ?? '';
    final department = payslip.departmentName?.trim() ?? '';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        if (number.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: customText(
              number,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTxt,
            ),
          ),
        if (position.isNotEmpty)
          customText('•  $position', fontSize: 12, color: AppColors.subTitle),
        if (department.isNotEmpty)
          customText('•  $department', fontSize: 12, color: AppColors.primary),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 14, color: color),
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

/// "The payment failed. Please contact HR."
class _PaymentFailedNotice extends StatelessWidget {
  final String message;

  const _PaymentFailedNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          widthBx(w: 8),
          Expanded(
            child: customText(
              message,
              color: AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              maxLine: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gross / deductions / net as three white cards on a soft blue tray — the
/// totals strip below the employee card. Each is the server's own total;
/// none is worked out from the lines.
class _SummaryStrip extends StatelessWidget {
  final PayslipRecord payslip;

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
              value: SalaryHistoryCopy.amount(payslip.totalEarnings),
              color: AppColors.success,
            ),
          ),
          widthBx(w: 8),
          Expanded(
            child: _SummaryColumn(
              label: l10n.salaryTotalDeductionsLabel,
              value: payslip.totalDeductions > 0
                  ? '-${SalaryHistoryCopy.amount(payslip.totalDeductions)}'
                  : SalaryHistoryCopy.amount(payslip.totalDeductions),
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

/// The payslip's lines in the four groups of `groupLines`, then any line the
/// App could not place. A group with no rows is left out.
class _Sections extends StatelessWidget {
  final PayslipSections sections;

  /// The loaded payslip the rows came from: the OT line opens its pieces.
  final PayslipRecord payslip;

  const _Sections({required this.sections, required this.payslip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _Section(
          title: PayslipLineCopy.earningsSection(l10n),
          titleColor: AppColors.primary,
          rows: sections.earnings,
          payslip: payslip,
        ),
        _Section(
          title: PayslipLineCopy.attendanceSection(l10n),
          titleColor: AppColors.danger,
          rows: sections.attendance,
          payslip: payslip,
        ),
        _Section(
          title: PayslipLineCopy.statutorySection(l10n),
          titleColor: AppColors.danger,
          rows: sections.statutory,
          payslip: payslip,
        ),
        _Section(
          title: PayslipLineCopy.otherDeductionsSection(l10n),
          titleColor: AppColors.danger,
          rows: sections.otherDeductions,
          payslip: payslip,
        ),
        // Lines whose kind the App does not know: shown under the server's
        // own names, in a block with no heading, so no figure goes missing.
        _Section(
          title: null,
          titleColor: AppColors.subTitle,
          rows: sections.unplaced,
          payslip: payslip,
          unplaced: true,
        ),
      ],
    );
  }
}

/// A titled group of rows in one white card. Renders nothing when [rows] is
/// empty.
class _Section extends StatelessWidget {
  final String? title;
  final Color titleColor;
  final List<PayslipRow> rows;
  final PayslipRecord payslip;

  /// Rows the App could not place: shown with no sign and no colour, as it
  /// cannot say whether they add to the pay or take from it.
  final bool unplaced;

  const _Section({
    required this.title,
    required this.titleColor,
    required this.rows,
    required this.payslip,
    this.unplaced = false,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final title = this.title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
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
          ],
          Container(
            decoration: _cardDecoration(radius: 20),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.gray200,
                    ),
                  _LineRow(
                    row: rows[i],
                    unplaced: unplaced,
                    onTap: opensOvertimeItems(rows[i], payslip)
                        ? () => showPayslipOtItemsSheet(
                            context,
                            items: payslip.overtimeItems,
                            total: rows[i].amount,
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the payslip: its glyph (deductions only), title, caption and
/// amount.
///
/// The amount is the row's own; how it is written (sign or none) is
/// `PayslipLineCopy.amount`'s. A deduction is red, an earning green, a line
/// of zero grey: it is shown, not hidden.
class _LineRow extends StatelessWidget {
  final PayslipRow row;
  final bool unplaced;

  /// Set for the OT line with pieces to show: the row then has a chevron and
  /// opens them.
  final VoidCallback? onTap;

  const _LineRow({required this.row, this.unplaced = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final glyph = unplaced ? null : _glyphFor(row);
    final caption = PayslipLineCopy.caption(l10n, row);
    // Late / early-out captions pick up the icon's amber; the rest stay grey.
    final captionColor = glyph?.color == AppColors.attendanceLate
        ? AppColors.attendanceLate
        : AppColors.subTitle;

    final shown = PayslipLineCopy.amount(row, unplaced: unplaced);
    final amount = shown.text;
    final amountColor = switch (shown.kind) {
      PayslipAmountKind.zero => AppColors.subTitle,
      PayslipAmountKind.earning => AppColors.success,
      PayslipAmountKind.deduction => AppColors.danger,
      PayslipAmountKind.plain => AppColors.textPrimary,
    };

    final tap = onTap;
    final content = Padding(
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
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  PayslipLineCopy.title(l10n, row),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  maxLine: 2,
                ),
                if (caption != null) ...[
                  heightBx(h: 2),
                  customText(
                    caption,
                    color: captionColor,
                    fontSize: 11,
                    maxLine: 2,
                  ),
                ],
              ],
            ),
          ),
          widthBx(w: 8),
          customText(
            amount,
            color: amountColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          if (tap != null) ...[
            widthBx(w: 4),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.subTitle,
            ),
          ],
        ],
      ),
    );

    if (tap == null) return content;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: tap, child: content),
    );
  }
}

/// Icon + tint for a deduction row, by its code; null for an earning, which
/// has none.
({IconData icon, Color color})? _glyphFor(PayslipRow row) {
  if (!row.isDeduction) return null;

  return switch (row.title) {
    PayslipLineTitle.late => (
      icon: Icons.history,
      color: AppColors.attendanceLate,
    ),
    PayslipLineTitle.absentLate || PayslipLineTitle.missedPart => (
      icon: Icons.schedule,
      color: AppColors.gray600,
    ),
    PayslipLineTitle.earlyOut => (
      icon: Icons.logout,
      color: AppColors.attendanceLate,
    ),
    PayslipLineTitle.absence || PayslipLineTitle.unpaidLeave => (
      icon: Icons.event_busy,
      color: AppColors.danger,
    ),
    PayslipLineTitle.socialSecurity => (
      icon: Icons.shield,
      color: AppColors.primary,
    ),
    PayslipLineTitle.incomeTax => (
      icon: Icons.account_balance,
      color: _indigo,
    ),
    // A loan, a settlement, the company's own deduction, a deduction item.
    _ => (icon: Icons.favorite, color: _purple),
  };
}

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

/// The taxable income and the headline net, in the white bar pinned to the
/// bottom of the payslip. Both are the server's figures.
class _FooterCard extends StatelessWidget {
  final PayslipRecord payslip;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: customText(
                  l10n.salaryTaxableIncomeLabel,
                  color: AppColors.secondaryTxt,
                  fontSize: 13,
                ),
              ),
              widthBx(w: 8),
              customText(
                SalaryHistoryCopy.amount(payslip.taxableIncome),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ],
          ),
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
