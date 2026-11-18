import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../core/widgets/paged_list_end.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../../time_off/presentation/widgets/leave_filter_chip.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import '../providers/offsite_approvals_notifier.dart';
import '../providers/offsite_decision_notifier.dart';
import 'offsite_approval_card.dart';
import 'offsite_decision_flow.dart';
import 'requests_list_message.dart';

/// The approvals page's off-site tab (#46): the scans waiting at the
/// approver's step, then "decided by me" with its two chips, each list a
/// page at a time. A row decides inline (Approve with an optional note,
/// Reject with a reason) or opens the request's own page.
///
/// Body only, with no app bar of its own, so it drops straight into the
/// approvals page. Kept alive across tab switches.
class OffsiteApprovalsTab extends ConsumerStatefulWidget {
  const OffsiteApprovalsTab({super.key});

  @override
  ConsumerState<OffsiteApprovalsTab> createState() =>
      _OffsiteApprovalsTabState();
}

class _OffsiteApprovalsTabState extends ConsumerState<OffsiteApprovalsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(offsiteApprovalsNotifierProvider);
    final notifier = ref.read(offsiteApprovalsNotifierProvider.notifier);
    final pending = state.pending.valueOrNull;
    final decided = state.decided.valueOrNull;

    return Container(
      color: AppColors.homeBackground,
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
          children: [
            customText(
              // The loaded count, with a `+` while there is more to load.
              l10n.leaveApprovalsPendingHeader(pending?.countLabel ?? '0'),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            heightBx(h: 12),
            _ScanList(
              value: state.pending,
              onRetry: notifier.retryPending,
              emptyMessage: l10n.leaveApprovalsPendingEmpty,
              rejectOnlyIds: state.rejectOnlyIds,
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
            _DecidedChips(
              selected: state.decidedFilter,
              onSelect: notifier.selectDecided,
            ),
            heightBx(h: 12),
            _ScanList(
              value: state.decided,
              onRetry: notifier.retryDecided,
              emptyMessage: l10n.leaveApprovalsHistoryEmpty,
              rejectOnlyIds: state.rejectOnlyIds,
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

/// "I approved" / "I rejected": which of the approver's own decisions the
/// list below shows.
class _DecidedChips extends StatelessWidget {
  final TimeCorrectionStatus selected;
  final ValueChanged<TimeCorrectionStatus> onSelect;

  const _DecidedChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        LeaveFilterChip(
          label: l10n.leaveDecidedByMeApproved,
          selected: selected == TimeCorrectionStatus.approved,
          onTap: () => onSelect(TimeCorrectionStatus.approved),
        ),
        LeaveFilterChip(
          label: l10n.leaveDecidedByMeRejected,
          selected: selected == TimeCorrectionStatus.rejected,
          onTap: () => onSelect(TimeCorrectionStatus.rejected),
        ),
      ],
    );
  }
}

/// One list's rows, or its loading, failed or empty state. Rows already on
/// screen stay while it loads again.
class _ScanList extends StatelessWidget {
  final AsyncValue<PagedList<OffsiteRequestDetail>> value;
  final VoidCallback onRetry;
  final String emptyMessage;
  final Set<String> rejectOnlyIds;

  const _ScanList({
    required this.value,
    required this.onRetry,
    required this.emptyMessage,
    required this.rejectOnlyIds,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (value.isLoading && !value.hasValue) {
      return Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerBox(width: double.infinity, height: 220),
          ),
        ),
      );
    }

    if (value.hasError && !value.hasValue) {
      return RequestsListMessage(
        icon: Icons.error_outline,
        text: l10n.offsiteApprovalsLoadFailed,
        onRetry: onRetry,
      );
    }

    final items = value.valueOrNull?.items ?? const <OffsiteRequestDetail>[];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: customText(
          emptyMessage,
          color: AppColors.subTitle,
          fontSize: 13,
        ),
      );
    }

    return Column(
      children: [
        for (final request in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ScanRow(
              request: request,
              rejectOnly: rejectOnlyIds.contains(request.id),
            ),
          ),
      ],
    );
  }
}

/// One scan: its card, deciding inline when the waiting step is the
/// approver's; a tap opens the request's own page.
class _ScanRow extends ConsumerWidget {
  final OffsiteRequestDetail request;
  final bool rejectOnly;

  const _ScanRow({required this.request, required this.rejectOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user),
    );
    final deciding = ref.watch(offsiteDecisionNotifierProvider(request.id));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.push(AppRoutes.approvalOffsite(request.id), extra: request),
      child: OffsiteApprovalCard(
        request: request,
        deciding: deciding,
        canDecide: ApproverAccess.canDecideOffsite(request, user),
        own: ApproverAccess.isOwnOffsite(request, user?.employeeId),
        rejectOnly: rejectOnly,
        onApprove: () => OffsiteDecisionFlow.approve(context, ref, request),
        onReject: () => OffsiteDecisionFlow.reject(context, ref, request),
        onViewImage: (url) => showImageViewer(context, url),
      ),
    );
  }
}
