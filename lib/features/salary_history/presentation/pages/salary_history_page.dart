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
import '../../domain/entities/payslip.dart';
import '../providers/payslip_pdf_notifier.dart';
import '../providers/salary_history_notifier.dart';
import '../providers/salary_history_state.dart';
import '../widgets/salary_error_block.dart';
import '../widgets/salary_history_copy.dart';

/// "ປະຫວັດເງິນເດືອນ" — the destination behind the list page's menu tile.
///
/// A year switcher, an All/Paid/Pending filter, the latest payslip
/// highlighted up top, and the year's payslips below, each expandable into
/// its earnings/deductions breakdown. Everything comes from
/// [salaryHistoryNotifierProvider]; the page holds no fetching logic of its
/// own.
class SalaryHistoryPage extends ConsumerWidget {
  const SalaryHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(salaryHistoryNotifierProvider);

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
                    GestureDetector(onTap: () => context.pop(), child: popBack()),
                    widthBx(w: 4),
                    Expanded(
                      child: customText(
                        l10n.salaryHistoryTitle,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    const _YearSwitcher(),
                    widthBx(w: 10),
                    const Expanded(child: _FilterChips()),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
                  children: [
                    _LatestSummaryCard(payslips: state.payslips, all: state.all),
                    heightBx(h: 20),
                    _RecordsList(payslips: state.payslips, records: state.filtered),
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

class _YearSwitcher extends ConsumerWidget {
  const _YearSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salaryHistoryNotifierProvider);
    final notifier = ref.read(salaryHistoryNotifierProvider.notifier);

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
            onTap: notifier.previousYear,
            child: const Icon(Icons.chevron_left, color: AppColors.primary, size: 20),
          ),
          widthBx(w: 4),
          const Icon(Icons.calendar_today, color: AppColors.primary, size: 13),
          widthBx(w: 4),
          customText(
            '${state.year}',
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          widthBx(w: 4),
          InkWell(
            onTap: state.canGoNext ? notifier.nextYear : null,
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

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(
      salaryHistoryNotifierProvider.select((s) => s.filter),
    );
    final notifier = ref.read(salaryHistoryNotifierProvider.notifier);

    final chips = {
      SalaryHistoryFilter.all: l10n.salaryFilterAll,
      SalaryHistoryFilter.paid: l10n.salaryFilterPaid,
      SalaryHistoryFilter.pending: l10n.salaryFilterPending,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final entry in chips.entries) ...[
          _FilterChip(
            label: entry.value,
            selected: active == entry.key,
            onTap: () => notifier.setFilter(entry.key),
          ),
          if (entry.key != SalaryHistoryFilter.pending) widthBx(w: 8),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: customText(
          label,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _LatestSummaryCard extends StatelessWidget {
  final AsyncValue<List<Payslip>> payslips;
  final List<Payslip> all;

  const _LatestSummaryCard({required this.payslips, required this.all});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loading = payslips.isLoading && !payslips.hasValue;

    if (loading) {
      return const ShimmerBox(width: double.infinity, height: 120, borderRadius: BorderRadius.all(Radius.circular(20)));
    }

    if (payslips.hasError || all.isEmpty) return const SizedBox.shrink();

    final latest = all.first;
    final status = SalaryHistoryCopy.statusColor(latest.status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  '${l10n.salaryNetSalaryLabel} • ${SalaryHistoryCopy.monthYear(l10n, latest.month, latest.year)}',
                  color: AppColors.subTitle,
                  fontSize: 12,
                ),
                heightBx(h: 6),
                customText(
                  SalaryHistoryCopy.currency(latest.netSalary),
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                heightBx(h: 6),
                customText(
                  '${latest.employeeName} • ${latest.employeeCode} • ${latest.position}',
                  color: AppColors.subTitle,
                  fontSize: 12,
                ),
                heightBx(h: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(
                    label: SalaryHistoryCopy.statusLabel(l10n, latest.status),
                    color: status,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.access_time_filled,
              size: 96,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 13, color: color),
          widthBx(w: 4),
          customText(label, color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ],
      ),
    );
  }
}

class _RecordsList extends ConsumerWidget {
  final AsyncValue<List<Payslip>> payslips;
  final List<Payslip> records;

  const _RecordsList({required this.payslips, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loading = payslips.isLoading && !payslips.hasValue;

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

    if (payslips.hasError) {
      return SalaryErrorBlock(
        message: l10n.salaryHistoryLoadFailed,
        onRetry: () => ref.read(salaryHistoryNotifierProvider.notifier).retry(),
      );
    }

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: customText(l10n.salaryHistoryEmpty, color: AppColors.subTitle),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < records.length; i++)
          _PayslipCard(index: i, payslip: records[i]),
      ],
    );
  }
}

class _PayslipCard extends ConsumerWidget {
  final int index;
  final Payslip payslip;

  const _PayslipCard({required this.index, required this.payslip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expanded = ref.watch(
      salaryHistoryNotifierProvider.select((s) => s.expandedIndexes.contains(index)),
    );
    final status = SalaryHistoryCopy.statusColor(payslip.status);

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
            // Tapping the card body opens the full payslip; the expand
            // chevron below keeps its own tap for the inline breakdown.
            onTap: () =>
                context.push(AppRoutes.payslipDetail, extra: payslip),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MonthBadge(month: payslip.month, year: payslip.year, color: status),
                widthBx(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        SalaryHistoryCopy.monthYear(l10n, payslip.month, payslip.year),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      heightBx(h: 2),
                      customText(
                        payslip.paidDate == null
                            ? SalaryHistoryCopy.statusLabel(l10n, payslip.status)
                            : '${l10n.salaryPaidOnLabel} ${SalaryHistoryCopy.date(payslip.paidDate!)}',
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
                    customText(
                      SalaryHistoryCopy.currency(payslip.netSalary),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                    heightBx(h: 4),
                    Row(
                      children: [
                        _StatusPillOutline(
                          label: SalaryHistoryCopy.statusLabel(l10n, payslip.status),
                          color: status,
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => ref
                              .read(salaryHistoryNotifierProvider.notifier)
                              .toggleExpanded(index),
                          child: Icon(
                            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (expanded) ...[
            heightBx(h: 12),
            const Divider(height: 1, color: AppColors.border),
            heightBx(h: 12),
            _SectionHeader(label: l10n.salaryIncomeSection, color: AppColors.primary),
            heightBx(h: 8),
            _AmountRow(label: l10n.salaryBaseSalary, amount: payslip.baseSalary),
            _AmountRow(label: l10n.salaryAllowance, amount: payslip.allowance),
            heightBx(h: 12),
            _SectionHeader(label: l10n.salaryDeductionsSection, color: AppColors.danger),
            heightBx(h: 8),
            _AmountRow(
              label: payslip.socialSecurityRate > 0
                  ? '${l10n.salarySocialSecurity} (${(payslip.socialSecurityRate * 100).toStringAsFixed(1)}%)'
                  : l10n.salarySocialSecurity,
              amount: -payslip.socialSecurity,
            ),
            _AmountRow(label: l10n.salaryIncomeTax, amount: -payslip.incomeTax),
            _AmountRow(label: l10n.salaryOtherDeductions, amount: -payslip.otherDeductions),
            heightBx(h: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  customText(l10n.salaryNetSalaryLabel, fontWeight: FontWeight.w700),
                  customText(
                    SalaryHistoryCopy.currency(payslip.netSalary),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
            heightBx(h: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    value: SalaryHistoryCopy.count(payslip.workingDays),
                    label: l10n.salaryWorkingDaysLabel,
                  ),
                ),
                widthBx(w: 10),
                Expanded(
                  child: _StatBox(
                    value: SalaryHistoryCopy.count(payslip.overtimeHours),
                    label: l10n.salaryOvertimeLabel,
                  ),
                ),
                widthBx(w: 10),
                Expanded(
                  child: _StatBox(
                    value: SalaryHistoryCopy.count(payslip.unpaidLeaveDays),
                    label: l10n.salaryUnpaidLeaveLabel,
                  ),
                ),
              ],
            ),
            heightBx(h: 12),
            _DownloadButton(payslip: payslip),
          ],
        ],
      ),
    );
  }
}

class _MonthBadge extends StatelessWidget {
  final int month;
  final int year;
  final Color color;

  const _MonthBadge({required this.month, required this.year, required this.color});

  @override
  Widget build(BuildContext context) {
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
            month.toString().padLeft(2, '0'),
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            alight: TextAlign.center,
          ),
          customText('$year', color: color, fontSize: 11, alight: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatusPillOutline extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPillOutline({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 11, color: color),
            widthBx(w: 2),
            customText(label, color: color, fontWeight: FontWeight.w700, fontSize: 11),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return customText(label, color: color, fontWeight: FontWeight.w700, fontSize: 13);
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;

  const _AmountRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final negative = amount < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: customText(label, color: AppColors.subTitle, fontSize: 13),
          ),
          customText(
            negative
                ? '- ${SalaryHistoryCopy.currency(-amount).replaceFirst('₭ ', '')}'
                : SalaryHistoryCopy.currency(amount).replaceFirst('₭ ', ''),
            color: negative ? AppColors.danger : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          customText(value, fontWeight: FontWeight.w700, fontSize: 16),
          heightBx(h: 2),
          customText(
            label,
            fontSize: 10,
            color: AppColors.subTitle,
            alight: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// "Download Payslip (PDF)" — fetches the payslip's PDF and hands it to the
/// system save dialog. The icon becomes a spinner while the download runs;
/// the outcome is toasted.
class _DownloadButton extends ConsumerWidget {
  final Payslip payslip;

  const _DownloadButton({required this.payslip});

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

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        // Stays enabled so the border keeps its colour; the notifier ignores
        // a tap while a download is already running.
        onPressed: () => ref.read(provider.notifier).download(payslip),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: downloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 18),
        label: customText(
          l10n.salaryDownloadPdf,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
