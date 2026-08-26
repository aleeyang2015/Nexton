import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_category.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../providers/leave_history_notifier.dart';
import 'leave_approval_timeline.dart';
import 'leave_copy.dart';
import 'leave_filter_chip.dart';

/// "ປະຫວັດການລາພັກ" — filter chips, a from/to date range and the fetched
/// list of leave requests, each with its approval-chain timeline. Everything
/// comes from [leaveHistoryNotifierProvider]; the tab holds no fetching
/// logic of its own.
class LeaveHistoryTab extends ConsumerWidget {
  const LeaveHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveHistoryNotifierProvider);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
        children: [
          _CategoryFilterRow(selected: state.category),
          heightBx(h: 16),
          _DateRangeRow(from: state.from, to: state.to),
          heightBx(h: 20),
          _RequestsList(requests: state.requests),
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends ConsumerWidget {
  final LeaveCategory? selected;

  const _CategoryFilterRow({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(leaveHistoryNotifierProvider.notifier);
    final chips = <(String, LeaveCategory?)>[
      (l10n.leaveFilterAll, null),
      for (final c in LeaveCategory.values) (LeaveCopy.categoryLabel(l10n, c), c),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => widthBx(w: 8),
        itemBuilder: (context, i) {
          final (label, category) = chips[i];
          return LeaveFilterChip(
            label: label,
            selected: category == selected,
            onTap: () => notifier.filterByCategory(category),
          );
        },
      ),
    );
  }
}

class _DateRangeRow extends ConsumerWidget {
  final DateTime from;
  final DateTime to;

  const _DateRangeRow({required this.from, required this.to});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(leaveHistoryNotifierProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: l10n.leaveDateFrom,
            date: from,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: from,
                firstDate: DateTime(from.year - 3),
                lastDate: DateTime(from.year + 3),
              );
              if (picked != null) notifier.setRange(picked, to);
            },
          ),
        ),
        widthBx(w: 12),
        Expanded(
          child: _DateField(
            label: l10n.leaveDateTo,
            date: to,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: to,
                firstDate: DateTime(to.year - 3),
                lastDate: DateTime(to.year + 3),
              );
              if (picked != null) notifier.setRange(from, picked);
            },
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customText(
          label,
          fontSize: 13,
          color: AppColors.subTitle,
          fontWeight: FontWeight.w600,
        ),
        heightBx(h: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: customText(
                    _format(date),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                widthBx(w: 4),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.gray500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _RequestsList extends ConsumerWidget {
  final AsyncValue<List<LeaveRequest>> requests;

  const _RequestsList({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loading = requests.isLoading && !requests.hasValue;

    if (loading) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerBox(width: double.infinity, height: 148),
          ),
        ),
      );
    }

    if (requests.hasError) {
      return _ErrorBlock(
        message: l10n.leaveHistoryLoadFailed,
        onRetry: () => ref.read(leaveHistoryNotifierProvider.notifier).retry(),
      );
    }

    final list = requests.valueOrNull ?? const [];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: customText(l10n.leaveHistoryEmpty, color: AppColors.subTitle),
        ),
      );
    }

    return Column(
      children: [for (final r in list) _LeaveCard(request: r)],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
            heightBx(h: 8),
            customText(message, color: AppColors.subTitle, alight: TextAlign.center),
            heightBx(h: 12),
            InkWell(
              onTap: onRetry,
              child: customText(
                l10n.retry,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest request;

  const _LeaveCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pill = LeaveCopy.statusPill(l10n, request.status);
    final comment = request.reviewerComment;
    final showComment =
        request.status == LeaveStatus.rejected && (comment ?? '').isNotEmpty;

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
          Row(
            children: [
              Expanded(
                child: customText(
                  LeaveCopy.categoryLabel(l10n, request.category),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              _StatusPill(label: pill.label, color: pill.color),
            ],
          ),
          heightBx(h: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.subTitle,
              ),
              widthBx(w: 6),
              Expanded(
                child: customText(
                  LeaveCopy.dateLine(
                    l10n,
                    startDate: request.startDate,
                    endDate: request.endDate,
                    totalDays: request.totalDays,
                  ),
                  fontSize: 12,
                  color: AppColors.subTitle,
                ),
              ),
            ],
          ),
          heightBx(h: 18),
          LeaveApprovalTimeline(status: request.status),
          if (showComment) ...[
            heightBx(h: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  widthBx(w: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: '${l10n.leaveReviewerCommentLabel}: ',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: comment),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: customText(
        label,
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}
