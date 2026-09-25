import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_status.dart';
import '../providers/time_correction_history_notifier.dart';
import '../widgets/time_correction_history_summary.dart';
import '../widgets/time_correction_record_card.dart';

/// "ປະຫວັດການຮ້ອງຂໍແກ້ໄຂເວລາ" — the requests the employee has filed from
/// [TimeCorrectionRequestPage], with a shortcut to file a new one, counts and
/// a status filter.
/// Records and the picked tab live in [timeCorrectionHistoryNotifierProvider].
class TimeCorrectionHistoryPage extends ConsumerWidget {
  const TimeCorrectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeCorrectionHistoryNotifierProvider);
    final notifier = ref.read(timeCorrectionHistoryNotifierProvider.notifier);

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              const _Header(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 16, 15, 32),
                    children: [
                      const _NewRequestBanner(),
                      heightBx(h: 16),
                      TimeCorrectionSummaryRow(
                        total: state.countOf(null),
                        pending: state.countOf(TimeCorrectionStatus.pending),
                        approved: state.countOf(TimeCorrectionStatus.approved),
                      ),
                      heightBx(h: 16),
                      TimeCorrectionFilterDropdown(
                        selected: state.filter,
                        countOf: state.countOf,
                        onSelect: notifier.selectFilter,
                      ),
                      heightBx(h: 16),
                      const _RecordsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          Expanded(
            child: customText(
              l10n.timeCorrectionHistoryTitle,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              alight: TextAlign.center,
            ),
          ),
          // Balances the back button so the title stays centred.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// The picked tab's records, or the list's loading, failed or empty state.
/// Records already on screen stay visible while a refresh runs.
class _RecordsList extends ConsumerWidget {
  const _RecordsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(timeCorrectionHistoryNotifierProvider);
    final records = state.records;

    if (records.isLoading && !records.hasValue) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerBox(width: double.infinity, height: 120),
          ),
        ),
      );
    }

    if (records.hasError && !records.hasValue) {
      return _Message(
        icon: Icons.error_outline,
        text: l10n.timeCorrectionHistoryLoadFailed,
        onRetry: ref
            .read(timeCorrectionHistoryNotifierProvider.notifier)
            .refresh,
      );
    }

    final visible = state.visible;
    if (visible.isEmpty) {
      return _Message(
        icon: Icons.inbox_outlined,
        text: l10n.timeCorrectionHistoryEmpty,
      );
    }

    return Column(
      children: [
        for (final record in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TimeCorrectionRecordCard(
              record: record,
              onTap: () async {
                final cancelled = await context.push<bool>(
                  AppRoutes.timeCorrectionHistoryDetail,
                  extra: record.id,
                );
                if (cancelled == true) {
                  ref
                      .read(timeCorrectionHistoryNotifierProvider.notifier)
                      .refresh();
                }
              },
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retry = onRetry;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gray400, size: 36),
          heightBx(h: 8),
          customText(
            text,
            color: AppColors.subTitle,
            alight: TextAlign.center,
            maxLine: 2,
          ),
          if (retry != null) ...[
            heightBx(h: 12),
            InkWell(
              onTap: retry,
              child: customText(
                l10n.retry,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "ສ້າງຄຳຮ້ອງໃໝ່" — opens the request form, and reloads the list when it
/// closes so a request just filed shows up.
class _NewRequestBanner extends ConsumerWidget {
  const _NewRequestBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () async {
            await context.push(AppRoutes.timeCorrectionRequest);
            ref.read(timeCorrectionHistoryNotifierProvider.notifier).refresh();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
                widthBx(w: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        l10n.timeCorrectionNewRequestTitle,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      heightBx(h: 2),
                      customText(
                        l10n.timeCorrectionNewRequestSubtitle,
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                ),
                widthBx(w: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
