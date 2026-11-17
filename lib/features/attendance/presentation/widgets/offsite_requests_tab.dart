import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';

import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import '../providers/offsite_history_notifier.dart';
import 'offsite_record_card.dart';
import 'time_correction_history_summary.dart';
import '../../../../core/widgets/image_viewer.dart';

/// "ລົງເວລານອກພື້ນທີ່", the off-site tab of "My requests" (#42): the scans
/// the employee has filed, a status filter the server applies, a page at a
/// time, pull to refresh. A row opens the request's own page.
///
/// Requests and the picked status live in [offsiteHistoryNotifierProvider].
class OffsiteRequestsTab extends ConsumerWidget {
  const OffsiteRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(
      offsiteHistoryNotifierProvider.select((s) => s.filter),
    );
    final notifier = ref.read(offsiteHistoryNotifierProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 32),
        children: [
          // No counts: the server filters and pages each status's list.
          TimeCorrectionFilterDropdown(
            selected: filter,
            countOf: (_) => null,
            onSelect: notifier.selectFilter,
          ),
          heightBx(h: 16),
          const _RequestsList(),
        ],
      ),
    );
  }
}

/// The picked tab's requests, or the list's loading, failed or empty state.
/// Requests already on screen stay visible while a refresh runs.
class _RequestsList extends ConsumerWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(offsiteHistoryNotifierProvider);
    final requests = state.requests;

    if (requests.isLoading && !requests.hasValue) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerBox(width: double.infinity, height: 200),
          ),
        ),
      );
    }

    if (requests.hasError && !requests.hasValue) {
      return _Message(
        icon: Icons.error_outline,
        text: l10n.offsiteHistoryLoadFailed,
        onRetry: ref.read(offsiteHistoryNotifierProvider.notifier).refresh,
      );
    }

    final visible = state.visible;
    if (visible.isEmpty) {
      return _Message(
        icon: Icons.inbox_outlined,
        text: l10n.offsiteHistoryEmpty,
      );
    }
    final list = requests.valueOrNull;
    final notifier = ref.read(offsiteHistoryNotifierProvider.notifier);

    return Column(
      children: [
        for (final request in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // The request's own page; its buttons keep their own taps.
              onTap: () => context.push(
                AppRoutes.myOffsiteRequest(request.id),
                extra: request,
              ),
              child: OffsiteRecordCard(
                request: request,
                onViewImage: (url) => showImageViewer(context, url),
                onCancel: () => _cancel(context, ref, request),
                cancelling: state.cancellingIds.contains(request.id),
              ),
            ),
          ),
        if (list != null && list.loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else if (list != null && list.loadMoreError != null)
          _Message(
            icon: Icons.error_outline,
            text: l10n.offsiteHistoryLoadFailed,
            onRetry: notifier.retryLoadMore,
          )
        else if (list != null && list.canLoadMore)
          // Near the end: the next page.
          _LoadMoreWhenShown(
            key: ValueKey(list.items.length),
            onShown: notifier.loadMore,
          ),
      ],
    );
  }

  /// Asks first — a withdrawal can't be undone, and the scan would have to be
  /// filed again — then reports what the endpoint said.
  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    OffsiteRequestDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.offsiteCancelAction,
      message: l10n.offsiteCancelConfirm,
      confirmLabel: l10n.offsiteCancelAction,
    );
    if (!confirmed || !context.mounted) return;

    final failure = await ref
        .read(offsiteHistoryNotifierProvider.notifier)
        .cancel(request);
    if (!context.mounted) return;

    if (failure == null) {
      AppToast.success(l10n.offsiteCancelled);
    } else {
      // `CANNOT_CANCEL` arrives localized through the datasource's token, so
      // the employee is told the request moved on rather than "it failed".
      AppToast.error(failure.localize(l10n));
    }
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

/// Asks for the next page once, when the end of the list is built.
class _LoadMoreWhenShown extends StatefulWidget {
  const _LoadMoreWhenShown({super.key, required this.onShown});

  final VoidCallback onShown;

  @override
  State<_LoadMoreWhenShown> createState() => _LoadMoreWhenShownState();
}

class _LoadMoreWhenShownState extends State<_LoadMoreWhenShown> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 1);
}
