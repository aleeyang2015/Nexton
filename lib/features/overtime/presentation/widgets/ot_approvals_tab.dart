import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/paged_list_end.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/presentation/widgets/requests_list_message.dart';
import '../../../time_off/presentation/widgets/leave_filter_chip.dart';
import '../../domain/entities/ot_request.dart';
import '../providers/ot_approvals_notifier.dart';
import 'ot_approval_row.dart';

/// The approvals page's OT tab (#48), for department heads: the requests
/// waiting at their step, then "decided by me" with its two chips, each a
/// page at a time. HR steps never show. A row opens the request's page
/// (#30); #49 adds the decisions.
///
/// Body only; kept alive across tab switches.
class OtApprovalsTab extends ConsumerStatefulWidget {
  const OtApprovalsTab({super.key});

  @override
  ConsumerState<OtApprovalsTab> createState() => _OtApprovalsTabState();
}

class _OtApprovalsTabState extends ConsumerState<OtApprovalsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(otApprovalsNotifierProvider);
    final notifier = ref.read(otApprovalsNotifierProvider.notifier);
    final pending = state.pending.valueOrNull;
    final decided = state.decided.valueOrNull;
    final pendingRows = state.pendingRows;

    return Container(
      color: AppColors.homeBackground,
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
          children: [
            customText(
              l10n.leaveApprovalsPendingHeader(
                '${pendingRows.length}${pending?.hasMore ?? false ? '+' : ''}',
              ),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            heightBx(h: 12),
            _OtList(
              value: state.pending,
              rows: pendingRows,
              waiting: true,
              onRetry: notifier.retryPending,
              emptyMessage: l10n.apprOtWaitingEmpty,
            ),
            if (pending != null && !state.pending.isLoading)
              PagedListEnd(
                list: pending,
                onLoadMore: notifier.loadMorePending,
                onRetry: notifier.retryLoadMorePending,
              ),
            heightBx(h: 24),
            customText(
              l10n.leaveApprovalsHistoryHeader,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            heightBx(h: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                LeaveFilterChip(
                  label: l10n.leaveDecidedByMeApproved,
                  selected: state.decidedFilter == OtApprovalStatus.approved,
                  onTap: () =>
                      notifier.selectDecided(OtApprovalStatus.approved),
                ),
                LeaveFilterChip(
                  label: l10n.leaveDecidedByMeRejected,
                  selected: state.decidedFilter == OtApprovalStatus.rejected,
                  onTap: () =>
                      notifier.selectDecided(OtApprovalStatus.rejected),
                ),
              ],
            ),
            heightBx(h: 12),
            _OtList(
              value: state.decided,
              rows: state.decidedRows,
              waiting: false,
              onRetry: notifier.retryDecided,
              emptyMessage: l10n.leaveApprovalsHistoryEmpty,
            ),
            if (decided != null && !state.decided.isLoading)
              PagedListEnd(
                list: decided,
                onLoadMore: notifier.loadMoreDecided,
                onRetry: notifier.retryLoadMoreDecided,
              ),
          ],
        ),
      ),
    );
  }
}

/// One list's rows (HR steps already left out), or its loading, failed or
/// empty state. "None" shows only once the list has ended: while a next
/// page is on its way or can still be asked for, the list is not empty yet.
class _OtList extends ConsumerWidget {
  const _OtList({
    required this.value,
    required this.rows,
    required this.waiting,
    required this.onRetry,
    required this.emptyMessage,
  });

  final AsyncValue<PagedList<OtRequest>> value;
  final List<OtRequest> rows;
  final bool waiting;
  final VoidCallback onRetry;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final list = value.valueOrNull;

    if (value.isLoading && list == null) return const _Loading();

    if (value.hasError && list == null) {
      return RequestsListMessage(
        icon: Icons.error_outline,
        text: l10n.otListLoadFailed,
        onRetry: onRetry,
      );
    }

    if (rows.isEmpty) {
      // The pages so far held only HR steps: more are on their way.
      if (list != null && (list.loadingMore || list.canLoadMore)) {
        return const _Loading();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: customText(
          emptyMessage,
          color: AppColors.subTitle,
          fontSize: 13,
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    return Column(
      children: [
        for (final request in rows)
          OtApprovalRow(
            request: request,
            waiting: waiting,
            now: now,
            onTap: () =>
                context.push(AppRoutes.otRequest(request.id), extra: request),
          ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      2,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerBox(width: double.infinity, height: 110),
      ),
    ),
  );
}
