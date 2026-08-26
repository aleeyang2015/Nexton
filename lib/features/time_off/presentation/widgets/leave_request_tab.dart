import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_category.dart';
import '../../domain/entities/leave_summary.dart';
import '../providers/leave_request_form_notifier.dart';
import '../providers/leave_request_form_state.dart';
import '../providers/leave_summary_notifier.dart';
import 'leave_copy.dart';
import 'leave_filter_chip.dart';

/// "ຂໍລາພັກ" — the leave-request form: a balance summary for the selected
/// category, the category picker, individually-picked leave dates, the
/// return-to-work date, an (optional) attachment and a reason field. State
/// and submission live in [leaveRequestFormNotifierProvider]; the tab only
/// renders it.
class LeaveRequestTab extends ConsumerStatefulWidget {
  const LeaveRequestTab({super.key});

  @override
  ConsumerState<LeaveRequestTab> createState() => _LeaveRequestTabState();
}

class _LeaveRequestTabState extends ConsumerState<LeaveRequestTab> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(leaveRequestFormNotifierProvider);
    final notifier = ref.read(leaveRequestFormNotifierProvider.notifier);

    ref.listen<LeaveRequestFormState>(leaveRequestFormNotifierProvider, (
      previous,
      next,
    ) {
      final wasSubmitting = previous?.submission.isLoading ?? false;
      if (!wasSubmitting) return;

      if (next.submission.hasValue) {
        _reasonController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.leaveRequestSubmitSuccess)));
      } else if (next.submission.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.genericError)));
      }
    });

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
        children: [
          _BalanceCard(category: state.category),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveRequestCategoryLabel,
            child: _CategoryChipsRow(
              selected: state.category,
              onSelect: notifier.setCategory,
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveSelectDatesLabel,
            titleTrailing: _AddDateButton(
              onPick: (date) => notifier.addDate(date),
              dates: state.dates,
            ),
            child: _DatesList(dates: state.dates, onRemove: notifier.removeDate),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveReturnToWorkLabel,
            child: _ReturnToWorkRow(
              date: state.returnToWorkDate,
              onPick: notifier.setReturnToWorkDate,
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveAttachFileLabel,
            titleBadge: l10n.leaveOptionalBadge,
            titleTrailing: _AttachFileButton(
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveRequestReasonLabel,
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              onChanged: notifier.setReason,
              decoration: inputDecoration(l10n.leaveRequestReasonHint),
            ),
          ),
          heightBx(h: 24),
          button(
            () => notifier.submit(),
            l10n.leaveRequestSubmit,
            enabled: state.canSubmit,
          ),
        ],
      ),
    );
  }
}

LeaveCategoryBalance? _balanceFor(
  List<LeaveCategoryBalance>? balances,
  LeaveCategory category,
) {
  if (balances == null) return null;
  for (final balance in balances) {
    if (balance.category == category) return balance;
  }
  return null;
}

/// The remaining/used/year rollup for whichever category is currently
/// selected, from [leaveSummaryNotifierProvider]. Renders blank numbers
/// while that loads rather than blocking the rest of the form.
class _BalanceCard extends ConsumerWidget {
  final LeaveCategory category;

  const _BalanceCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(leaveSummaryNotifierProvider).valueOrNull;
    final balance = _balanceFor(summary?.balances, category);
    final year = summary?.year ?? DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          widthBx(w: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  l10n.leaveBalanceRemainingLabel,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      customText(
                        '${balance?.remainingDays ?? '-'}',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      widthBx(w: 4),
                      customText(
                        l10n.daysCountUnit,
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          widthBx(w: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                customText(
                  l10n.leaveBalanceUsedLabel(balance?.usedDays ?? 0),
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  alight: TextAlign.right,
                ),
                heightBx(h: 4),
                customText(
                  l10n.leaveYearLabel(year),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  alight: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled white card — the visual grouping every form section below the
/// balance card uses. [titleTrailing] sits at the end of the header row
/// (the dates section's "+" button, the attachment section's file picker);
/// [child] is the section's body, omitted when the header row is enough.
class _SectionCard extends StatelessWidget {
  final String title;
  final String? titleBadge;
  final Widget? titleTrailing;
  final Widget? child;

  const _SectionCard({
    required this.title,
    this.titleBadge,
    this.titleTrailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: customText(
                        title,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (titleBadge != null) ...[
                      widthBx(w: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: customText(
                            titleBadge!,
                            fontSize: 10,
                            color: AppColors.subTitle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (titleTrailing != null) ...[widthBx(w: 8), titleTrailing!],
            ],
          ),
          if (child != null) ...[heightBx(h: 12), child!],
        ],
      ),
    );
  }
}

class _CategoryChipsRow extends StatelessWidget {
  final LeaveCategory selected;
  final ValueChanged<LeaveCategory> onSelect;

  const _CategoryChipsRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LeaveCategory.values.length,
        separatorBuilder: (_, _) => widthBx(w: 8),
        itemBuilder: (context, i) {
          final category = LeaveCategory.values[i];
          return LeaveFilterChip(
            label: LeaveCopy.categoryLabel(l10n, category),
            selected: category == selected,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

class _AddDateButton extends StatelessWidget {
  final ValueChanged<DateTime> onPick;
  final List<DateTime> dates;

  const _AddDateButton({required this.onPick, required this.dates});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: dates.isEmpty ? now : dates.last.add(const Duration(days: 1)),
          firstDate: now.subtract(const Duration(days: 365)),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}

class _DatesList extends StatelessWidget {
  final List<DateTime> dates;
  final ValueChanged<DateTime> onRemove;

  const _DatesList({required this.dates, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (dates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: customText(
          l10n.leaveNoDatesSelected,
          color: AppColors.subTitle,
          fontSize: 13,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < dates.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                widthBx(w: 10),
                Expanded(
                  child: customText(
                    _format(dates[i]),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: () => onRemove(dates[i]),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (dates.isNotEmpty) ...[
          const Divider(height: 1, color: AppColors.border),
          heightBx(h: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                customText(
                  l10n.leaveDatesTotalPrefix,
                  fontSize: 13,
                  color: AppColors.subTitle,
                ),
                widthBx(w: 4),
                customText(
                  l10n.leaveDaysSuffix(dates.length),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ReturnToWorkRow extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _ReturnToWorkRow({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = date;

    return Row(
      children: [
        Expanded(
          child: customText(
            value == null ? '—' : _format(value),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) onPick(picked);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
          label: customText(
            l10n.leaveSelectButtonLabel,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _AttachFileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AttachFileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.attach_file, size: 15, color: AppColors.primary),
      label: customText(
        l10n.leaveChooseFileButton,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}
