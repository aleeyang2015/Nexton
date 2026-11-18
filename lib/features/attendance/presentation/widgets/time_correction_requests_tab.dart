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
import '../../domain/attendance_failure_x.dart';
import '../providers/time_correction_history_notifier.dart';
import 'requests_list_message.dart';
import 'time_correction_history_summary.dart';
import 'time_correction_record_card.dart';

/// "ລືມລົງເວລາ", the "forgot to scan" tab of "My requests" (#45): the
/// corrections the employee has filed, a status filter the server applies,
/// a page at a time, pull to refresh. A row opens the request's own page.
///
/// Requests and the picked status live in
/// [timeCorrectionHistoryNotifierProvider].
class TimeCorrectionRequestsTab extends ConsumerStatefulWidget {
  const TimeCorrectionRequestsTab({super.key});

  @override
  ConsumerState<TimeCorrectionRequestsTab> createState() =>
      _TimeCorrectionRequestsTabState();
}

class _TimeCorrectionRequestsTabState
    extends ConsumerState<TimeCorrectionRequestsTab> {
  /// How close to the end of the list, in pixels, the next page is asked
  /// for: on scroll, as the off-site tab does, not as soon as a page lands.
  static const double _loadMoreWithin = 300;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMoreIfNearEnd);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _loadMoreIfNearEnd() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter > _loadMoreWithin) return;
    ref.read(timeCorrectionHistoryNotifierProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(
      timeCorrectionHistoryNotifierProvider.select((s) => s.filter),
    );
    final notifier = ref.read(timeCorrectionHistoryNotifierProvider.notifier);

    // A page that does not fill the screen leaves nothing to scroll, so no
    // scroll would ask for the next one. Check once it is laid out.
    ref.listen(timeCorrectionHistoryNotifierProvider.select((s) => s.records), (
      _,
      _,
    ) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMoreIfNearEnd();
      });
    });

    return RefreshIndicator(
      onRefresh: () async {
        final failure = await notifier.refresh();
        // The rows already shown stay; say why they were not renewed.
        if (failure != null) AppToast.error(failure.localize(l10n));
      },
      child: ListView(
        controller: _scroll,
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
          const _RecordsList(),
        ],
      ),
    );
  }
}

/// The picked status's requests, or the list's loading, failed or empty
/// state. Requests already on screen stay visible while a refresh runs.
class _RecordsList extends ConsumerWidget {
  const _RecordsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(timeCorrectionHistoryNotifierProvider);
    final records = state.records;
    final notifier = ref.read(timeCorrectionHistoryNotifierProvider.notifier);

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
      // No staff record: #11's "not linked" text, and nothing to retry.
      final error = records.error;
      final notLinked = error is Failure && error.isEmployeeNotLinked;
      return RequestsListMessage(
        icon: Icons.error_outline,
        text: notLinked
            ? error.localize(l10n)
            : l10n.timeCorrectionHistoryLoadFailed,
        onRetry: notLinked ? null : notifier.refresh,
      );
    }

    final visible = state.visible;
    if (visible.isEmpty) {
      return RequestsListMessage(
        icon: Icons.inbox_outlined,
        text: l10n.timeCorrectionHistoryEmpty,
      );
    }
    final list = records.valueOrNull;

    return Column(
      children: [
        for (final record in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TimeCorrectionRecordCard(
              record: record,
              // The request's own page; it reloads this list after a
              // withdrawal.
              onTap: () => context.push(
                AppRoutes.myCorrectionRequest(record.id),
                extra: record,
              ),
            ),
          ),
        if (list != null && list.loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else if (list != null && list.loadMoreError != null)
          RequestsListMessage(
            icon: Icons.error_outline,
            text: l10n.timeCorrectionHistoryLoadFailed,
            onRetry: notifier.retryLoadMore,
          ),
      ],
    );
  }
}
