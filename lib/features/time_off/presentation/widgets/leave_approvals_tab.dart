import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/presentation/widgets/approve_note_dialog.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_type.dart';
import '../providers/leave_approvals_notifier.dart';
import '../providers/leave_approvals_state.dart';
import '../providers/leave_types_notifier.dart';
import 'leave_copy.dart';
import 'leave_filter_chip.dart';
import 'leave_reject_reason_dialog.dart';

/// "ອະນຸມັດຂໍລາພັກ" — the requests awaiting the signed-in approver's
/// decision (`my-approvals?status=pending`), each approvable / rejectable
/// inline, followed by the ones they approved or rejected. Everything comes
/// from [leaveApprovalsNotifierProvider].
///
/// The endpoint scopes to the caller's role, so a non-approver simply sees an
/// empty pending list — there is no role gate here.
///
/// Both lists come a page at a time. Each asks for its next page when the
/// end of its own rows comes near the screen ([_LoadMoreWhenShown]); whether
/// there is one is the notifier's to decide.
class LeaveApprovalsTab extends ConsumerWidget {
  const LeaveApprovalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(leaveApprovalsNotifierProvider);
    final notifier = ref.read(leaveApprovalsNotifierProvider.notifier);
    final pending = state.pending.valueOrNull;
    final decided = state.decided.valueOrNull;

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
        children: [
          customText(
            // The loaded count, with a `+` while there is more to load.
            l10n.leaveApprovalsPendingHeader(pending?.countLabel ?? '0'),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          heightBx(h: 12),
          _ApprovalList(
            value: state.pending,
            onRetry: notifier.retryPending,
            emptyMessage: l10n.leaveApprovalsPendingEmpty,
            itemBuilder: (request) => _OpensRequest(
              request: request,
              child: _PendingApprovalCard(
                request: request,
                deciding: state.decidingIds.contains(request.id),
                own: state.isOwn(request),
              ),
            ),
          ),
          if (pending != null && !state.pending.isLoading)
            _ListEnd(
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
          _DecidedFilterChips(
            selected: state.decidedFilter,
            onSelect: notifier.setDecidedFilter,
          ),
          heightBx(h: 12),
          _ApprovalList(
            value: state.decided,
            onRetry: notifier.retryDecided,
            emptyMessage: l10n.leaveApprovalsHistoryEmpty,
            itemBuilder: (request) => _OpensRequest(
              request: request,
              child: _DecidedApprovalRow(
                request: request,
                filter: state.decidedFilter,
              ),
            ),
          ),
          if (decided != null && !state.decided.isLoading)
            _ListEnd(
              list: decided,
              onLoadMore: notifier.loadMoreDecided,
              onRetry: notifier.retryLoadMoreDecided,
            ),
        ],
      ),
    );
  }
}

/// "I approved" / "I rejected": which of the approver's own decisions the
/// list below shows.
class _DecidedFilterChips extends StatelessWidget {
  final LeaveDecidedFilter selected;
  final ValueChanged<LeaveDecidedFilter> onSelect;

  const _DecidedFilterChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        LeaveFilterChip(
          label: l10n.leaveDecidedByMeApproved,
          selected: selected == LeaveDecidedFilter.approved,
          onTap: () => onSelect(LeaveDecidedFilter.approved),
        ),
        LeaveFilterChip(
          label: l10n.leaveDecidedByMeRejected,
          selected: selected == LeaveDecidedFilter.rejected,
          onTap: () => onSelect(LeaveDecidedFilter.rejected),
        ),
      ],
    );
  }
}

/// What sits under a list's last row: the trigger that asks for its next
/// page when it comes near the screen, and the footer that shows how that
/// page is doing.
class _ListEnd extends StatelessWidget {
  final PagedList<LeaveRequest> list;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  const _ListEnd({
    required this.list,
    required this.onLoadMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (list.canLoadMore)
          // A new one for each length, so a page that lands and leaves the
          // end still in view asks for the one after it.
          _LoadMoreWhenShown(
            key: ValueKey(list.items.length),
            onShown: onLoadMore,
          ),
        LoadMoreFooter(
          loadingMore: list.loadingMore,
          failed: list.loadMoreError != null,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

/// Calls [onShown] once, when it is first built.
///
/// A `ListView` builds a child only when it comes within reach of the
/// screen, so placing this after a list's last row means "the user is near
/// the end of this list": the moment to ask for its next page. That works
/// for a list in the middle of the page too, which the page's own scroll
/// position cannot tell from the one below it.
class _LoadMoreWhenShown extends StatefulWidget {
  final VoidCallback onShown;

  const _LoadMoreWhenShown({super.key, required this.onShown});

  @override
  State<_LoadMoreWhenShown> createState() => _LoadMoreWhenShownState();
}

class _LoadMoreWhenShownState extends State<_LoadMoreWhenShown> {
  @override
  void initState() {
    super.initState();
    // After this frame: asking changes the notifier's state, which may not
    // happen while the list is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ApprovalList extends StatelessWidget {
  final AsyncValue<PagedList<LeaveRequest>> value;

  /// Loads this list again after it failed; the other list is left as it is.
  final VoidCallback onRetry;
  final String emptyMessage;
  final Widget Function(LeaveRequest) itemBuilder;

  const _ApprovalList({
    required this.value,
    required this.onRetry,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loading = value.isLoading && !value.hasValue;

    if (loading) {
      return Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerBox(width: double.infinity, height: 96),
          ),
        ),
      );
    }

    if (value.hasError) {
      return _ErrorBlock(
        message: l10n.leaveApprovalsLoadFailed,
        onRetry: onRetry,
      );
    }

    final items = value.valueOrNull?.items ?? const <LeaveRequest>[];
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

    return Column(children: [for (final r in items) itemBuilder(r)]);
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 28),
            heightBx(h: 8),
            customText(
              message,
              color: AppColors.subTitle,
              alight: TextAlign.center,
            ),
            heightBx(h: 8),
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

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryTint,
        shape: BoxShape.circle,
      ),
      child: customText(
        _initials(name),
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _PendingApprovalCard extends ConsumerWidget {
  final LeaveRequest request;
  final bool deciding;

  /// The approver's own request. Nobody decides their own: no buttons, and
  /// a line saying why.
  final bool own;

  const _PendingApprovalCard({
    required this.request,
    required this.deciding,
    required this.own,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Requests carry no Lao type name; the loaded list has it.
    final types =
        ref.watch(leaveTypesNotifierProvider).valueOrNull ?? const <LeaveType>[];
    final untouched = request.awaitsFirstApproval;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: request.employeeName),
              widthBx(w: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText(
                      request.employeeName,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    heightBx(h: 2),
                    customText(
                      '${LeaveCopy.leaveTypeLabel(l10n, request.leaveType, types: types)} • '
                      '${LeaveCopy.dateLine(l10n, startDate: request.startDate, endDate: request.endDate, totalDays: request.totalDays)}',
                      fontSize: 12,
                      color: AppColors.subTitle,
                      maxLine: 2,
                    ),
                  ],
                ),
              ),
              if (untouched) const _NewBadge(),
            ],
          ),
          if (!untouched) ...[
            heightBx(h: 12),
            const _ClearedNotice(),
          ],
          if (request.reason.isNotEmpty) ...[
            heightBx(h: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: customText(
                '"${request.reason}"',
                fontSize: 13,
                color: AppColors.textPrimary,
                maxLine: 4,
              ),
            ),
          ],
          heightBx(h: 12),
          if (own)
            customText(
              l10n.leaveOwnRequestNoActions,
              fontSize: 12.5,
              color: AppColors.subTitle,
              maxLine: 3,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _DecisionButton(
                    label: LeaveCopy.approveActionLabel(l10n, request),
                    icon: Icons.check,
                    filled: true,
                    enabled: !deciding,
                    onTap: () => _approve(context, ref),
                  ),
                ),
                widthBx(w: 12),
                Expanded(
                  child: _DecisionButton(
                    label: l10n.leaveApprovalRejectAction,
                    icon: Icons.close,
                    filled: false,
                    enabled: !deciding,
                    onTap: () => _reject(context, ref),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // The words are looked up before the call, and the result is reported
  // whether or not this card is still on screen: a refusal reloads the list,
  // and the reload takes this card away before the answer is reported. The
  // toast does not need the card; it is shown by the App's own messenger.
  //
  // Approve asks first, with an optional note: on the last step the days
  // leave the employee's balance at once.
  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(leaveApprovalsNotifierProvider.notifier);
    final note = await ApproveNoteDialog.show(
      context,
      lastStep: request.isFinalApprovalStep,
      approveLabel: LeaveCopy.approveActionLabel(l10n, request),
    );
    if (note == null) return;

    _report(l10n, await notifier.approve(request, note: note));
  }

  // Everything the reject needs is taken before the dialog opens. While the
  // approver types a reason the lists may reload (another card was decided)
  // and take this card off the screen; the reason they typed is still sent,
  // and the answer still reported. If the request is no longer theirs to
  // reject, the server says so.
  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(leaveApprovalsNotifierProvider.notifier);

    final reason = await LeaveRejectReasonDialog.show(context);
    if (reason == null) return;

    _report(l10n, await notifier.reject(request, reason), rejected: true);
  }

  void _report(
    AppLocalizations l10n,
    LeaveDecisionOutcome outcome, {
    bool rejected = false,
  }) {
    if (outcome.kind == LeaveDecisionKind.success && !outcome.abandoned) {
      AppToast.success(
        rejected ? l10n.apprRejectedToast : l10n.apprApprovedToast,
      );
      return;
    }
    final text = LeaveCopy.decisionRefusal(l10n, outcome);
    if (text == null) return;

    switch (outcome.kind) {
      case LeaveDecisionKind.success:
        break;
      case LeaveDecisionKind.reloaded:
        AppToast.info(text);
      case LeaveDecisionKind.failed:
        AppToast.error(text);
    }
  }
}

/// "New" — flags a request nobody in the chain has acted on yet. It gives
/// way to [_ClearedNotice] once an earlier step approves, so the card always
/// carries exactly one marker of where the request stands.
class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          customText(
            l10n.leaveApprovalNewBadge,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          widthBx(w: 4),
          const Icon(
            Icons.notifications_active,
            size: 12,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// "Approved by the department head" — tells the current approver the
/// request has already cleared an earlier step, which is what makes their
/// own decision the final one.
class _ClearedNotice extends StatelessWidget {
  const _ClearedNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.success),
          widthBx(w: 8),
          Expanded(
            child: customText(
              l10n.leaveApprovalClearedNotice,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              maxLine: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the two decisions on a pending card. [filled] marks the approve
/// side: solid primary against the outlined reject, so the action that moves
/// the request forward is the one the eye lands on.
class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled
        ? AppColors.textWhite
        : (enabled ? AppColors.textPrimary : AppColors.gray400);

    // "Final approval" is a good deal longer than "Approve" — and longer
    // still in Lao — but the two buttons split the row evenly. Scaling down
    // keeps the long label whole where ellipsis would eat the word that
    // makes it different from a plain approval.
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          widthBx(w: 6),
          customText(
            label,
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            alight: TextAlign.center,
          ),
        ],
      ),
    );

    const shape = StadiumBorder();
    const padding = EdgeInsets.symmetric(vertical: 12);

    if (filled) {
      return FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.gray300,
          shape: shape,
          padding: padding,
        ),
        child: child,
      );
    }

    // Red border on the reject side — the outline carries the warning, so
    // the label stays dark rather than turning the whole button red.
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: enabled ? AppColors.danger : AppColors.gray300,
        ),
        shape: shape,
        padding: padding,
      ),
      child: child,
    );
  }
}

/// One request the approver approved or rejected, shown as it stands now:
/// the request's own status, and when it is still pending, the step it
/// waits for. The icon says what the approver did (the chip), which a
/// request cancelled since would not.
class _DecidedApprovalRow extends ConsumerWidget {
  final LeaveRequest request;
  final LeaveDecidedFilter filter;

  const _DecidedApprovalRow({required this.request, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final types =
        ref.watch(leaveTypesNotifierProvider).valueOrNull ?? const <LeaveType>[];
    final pill = LeaveCopy.statusPill(l10n, request.status);
    final waitingFor = request.isPending ? request.currentStep : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Avatar(name: request.employeeName),
          widthBx(w: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  '${request.employeeName} • '
                  '${LeaveCopy.leaveTypeLabel(l10n, request.leaveType, types: types)}',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                heightBx(h: 2),
                customText(
                  LeaveCopy.dateLine(
                    l10n,
                    startDate: request.startDate,
                    endDate: request.endDate,
                    totalDays: request.totalDays,
                  ),
                  fontSize: 12,
                  color: AppColors.subTitle,
                ),
                if (waitingFor != null) ...[
                  heightBx(h: 2),
                  customText(
                    l10n.leaveWaitingForStep(
                      LeaveCopy.stepRoleLabel(l10n, waitingFor.role),
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
          widthBx(w: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pill.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter == LeaveDecidedFilter.rejected
                      ? Icons.close
                      : Icons.check,
                  size: 13,
                  color: pill.color,
                ),
                widthBx(w: 4),
                customText(
                  pill.label,
                  color: pill.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the approver's page of [request] when its card is tapped, with the
/// row for a first paint. The card's own buttons keep their taps.
class _OpensRequest extends StatelessWidget {
  final LeaveRequest request;
  final Widget child;

  const _OpensRequest({required this.request, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.push(AppRoutes.approvalLeave(request.id), extra: request),
      child: child,
    );
  }
}
