import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/paged_list_end.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../../time_off/presentation/widgets/leave_filter_chip.dart';
import '../../domain/entities/attendance_approval_request.dart';
import '../../domain/entities/time_correction_status.dart';
import '../providers/attendance_approvals_lists.dart';
import '../providers/attendance_decision_notifier.dart';
import 'attendance_decision_flow.dart';
import 'requests_list_message.dart';

/// What a row's card needs to know about its decision: whether it is on its
/// way, whether the buttons show (and which), and what they do.
class AttendanceRowActions {
  const AttendanceRowActions({
    required this.deciding,
    required this.canDecide,
    required this.own,
    required this.rejectOnly,
    required this.onApprove,
    required this.onReject,
  });

  final bool deciding;
  final bool canDecide;
  final bool own;
  final bool rejectOnly;
  final VoidCallback onApprove;
  final VoidCallback onReject;
}

/// An attendance approvals tab (#46 off-site, #47 "forgot to scan"), in
/// #19's shape: the requests waiting at the approver's step, then "decided
/// by me" with its two chips, each list a page at a time. A row decides
/// inline (Approve with an optional note, Reject with a reason) or opens the
/// request's own page ([routeOf]).
///
/// Body only, with no app bar of its own, so it drops straight into the
/// approvals page. Kept alive across tab switches.
class AttendanceApprovalsView<T extends AttendanceApprovalRequest>
    extends ConsumerStatefulWidget {
  const AttendanceApprovalsView({
    super.key,
    required this.lists,
    required this.decisionOf,
    required this.routeOf,
    required this.loadFailedText,
    required this.cardOf,
  });

  final AutoDisposeNotifierProvider<
    AttendanceApprovalsNotifier<T>,
    AttendanceApprovalsState<T>
  >
  lists;

  final AutoDisposeFamilyNotifierProvider<
    AttendanceDecisionNotifier<T>,
    AttendanceDecisionState,
    String
  >
  Function(String id)
  decisionOf;

  /// The request's own page for its approver.
  final String Function(String id) routeOf;

  /// "Couldn't load …", in this kind's words.
  final String Function(AppLocalizations l10n) loadFailedText;

  /// The row's card.
  final Widget Function(
    BuildContext context,
    T request,
    AttendanceRowActions actions,
  )
  cardOf;

  @override
  ConsumerState<AttendanceApprovalsView<T>> createState() =>
      _AttendanceApprovalsViewState<T>();
}

class _AttendanceApprovalsViewState<T extends AttendanceApprovalRequest>
    extends ConsumerState<AttendanceApprovalsView<T>>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(widget.lists);
    final notifier = ref.read(widget.lists.notifier);
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
            _RequestList<T>(
              value: state.pending,
              onRetry: notifier.retryPending,
              emptyMessage: l10n.leaveApprovalsPendingEmpty,
              loadFailed: widget.loadFailedText(l10n),
              state: state,
              view: widget,
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
            _RequestList<T>(
              value: state.decided,
              onRetry: notifier.retryDecided,
              emptyMessage: l10n.leaveApprovalsHistoryEmpty,
              loadFailed: widget.loadFailedText(l10n),
              state: state,
              view: widget,
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
class _RequestList<T extends AttendanceApprovalRequest>
    extends StatelessWidget {
  final AsyncValue<PagedList<T>> value;
  final VoidCallback onRetry;
  final String emptyMessage;
  final String loadFailed;
  final AttendanceApprovalsState<T> state;
  final AttendanceApprovalsView<T> view;

  const _RequestList({
    required this.value,
    required this.onRetry,
    required this.emptyMessage,
    required this.loadFailed,
    required this.state,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
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
        text: loadFailed,
        onRetry: onRetry,
      );
    }

    final items = value.valueOrNull?.items ?? const [];
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
            child: _RequestRow<T>(
              request: request,
              rejectOnly: state.rejectOnlyIds.contains(request.id),
              notMine: state.notMineIds.contains(request.id),
              view: view,
            ),
          ),
      ],
    );
  }
}

/// One request: its card, deciding inline when the waiting step is the
/// approver's; a tap opens the request's own page.
class _RequestRow<T extends AttendanceApprovalRequest> extends ConsumerWidget {
  final T request;
  final bool rejectOnly;
  final bool notMine;
  final AttendanceApprovalsView<T> view;

  const _RequestRow({
    required this.request,
    required this.rejectOnly,
    required this.notMine,
    required this.view,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user),
    );
    final provider = view.decisionOf(request.id);
    final decision = ref.watch(provider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(view.routeOf(request.id), extra: request),
      child: view.cardOf(
        context,
        request,
        AttendanceRowActions(
          deciding: decision.deciding,
          canDecide:
              !notMine &&
              !decision.notMine &&
              ApproverAccess.canDecideAttendance(request, user),
          own: ApproverAccess.isOwnAttendance(request, user?.employeeId),
          rejectOnly: rejectOnly || decision.rejectOnly,
          onApprove: () => AttendanceDecisionFlow.approve(
            context,
            ref.read(provider.notifier),
            request,
          ),
          onReject: () => AttendanceDecisionFlow.reject(
            context,
            ref.read(provider.notifier),
            request,
          ),
        ),
      ),
    );
  }
}
