import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../approvals/presentation/widgets/approver_hand_over.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../attendance_providers.dart';
import '../../domain/attendance_failure_x.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_status.dart';
import '../providers/time_correction_decision_notifier.dart';
import '../providers/time_correction_detail_notifier.dart';
import '../widgets/approval_card_parts.dart';
import '../widgets/attendance_decision_flow.dart';
import '../widgets/time_correction_approval_workflow.dart';
import '../widgets/time_correction_detail_cards.dart';
import '../widgets/time_correction_record_card.dart';

/// "ລາຍລະອຽດຄຳຮ້ອງ" — one of the employee's "forgot to scan" requests in
/// full (#45), opened by its id from "My requests" or the send toast's
/// "View": the day, the part, the type, the requested times, the reason,
/// the photo, the steps, the corrected day once approved, and — while it
/// still waits — "Cancel request".
///
/// Loads its own copy by id; [initial] (the list row) shows meanwhile. Pull
/// to refresh.
///
/// With [approver] (#47, `/approvals/correction/:id`) it is an approver's
/// page of someone's request: never Cancel; Approve and Reject at the
/// bottom when the waiting step is theirs. After a decision the page stays
/// and is read again, so the corrected day shows.
class TimeCorrectionHistoryDetailPage extends ConsumerWidget {
  final String id;
  final TimeCorrectionRecord? initial;
  final bool approver;

  /// The approver list's row, shown while the request loads (#47).
  final TimeCorrectionDetail? preview;

  /// A head's read-only view of a team member's request (#50, with
  /// [approver]): no buttons; a `404` on the page's own read (moved
  /// department) keeps the row's copy, with no error.
  final bool readOnly;

  const TimeCorrectionHistoryDetailPage({
    super.key,
    required this.id,
    this.initial,
    this.approver = false,
    this.preview,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = timeCorrectionDetailNotifierProvider(id);
    final state = ref.watch(provider);
    final detail = state.detail;
    // The list row while the page's own copy loads (approver, #47); a load
    // that failed says so rather than leave the row passing for it.
    final error = detail.error;
    final gone = TimeCorrectionDetailNotifier.isGone(error);
    final keepRow = readOnly && gone && preview != null;
    final shown = keepRow
        ? preview
        : detail.valueOrNull ?? (detail.hasError ? null : preview);
    final notLinked = error is Failure && error.isEmployeeNotLinked;

    final page = Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              _Header(approver: approver || readOnly),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refresh(context, ref),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 32),
                    children: [
                      if (shown != null && (!gone || keepRow))
                        _Body(
                          id: id,
                          approver: approver && !readOnly,
                          readOnlyView: readOnly,
                          detail: shown,
                          cancelling: state.cancelling,
                          downloading: state.downloading,
                        )
                      else if (detail.hasError && !detail.isLoading)
                        _LoadFailed(
                          // Gone or not the user's: #53's text. No staff
                          // record: #11's. Neither has anything to retry.
                          message: gone
                              ? l10n.pushItemUnavailable
                              : notLinked
                              ? error.localize(l10n)
                              : l10n.timeCorrectionDetailLoadFailed,
                          onRetry: gone || notLinked
                              ? null
                              : ref.read(provider.notifier).refresh,
                        )
                      else
                        _Loading(initial: initial),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Someone else's request on the employee's own page (opened from a
    // push, #53): the approver's page instead, with the copy loaded.
    if (approver || readOnly) return page;
    return ApproverHandOver<TimeCorrectionDetail>(
      loaded: provider.select((s) => s.detail.valueOrNull),
      ownerOf: (request) => request.employee.id,
      location: AppRoutes.approvalCorrection(id),
      attendance: true,
      child: page,
    );
  }

  /// A failed pull to refresh keeps the request on screen and says why.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final failure = await ref
        .read(timeCorrectionDetailNotifierProvider(id).notifier)
        .refresh();
    if (failure != null && !TimeCorrectionDetailNotifier.isGone(failure)) {
      AppToast.error(failure.localize(l10n));
    }
  }
}

class _Body extends ConsumerWidget {
  final String id;
  final bool approver;

  /// A head's read-only view (#50): no Cancel, no buttons, no contact note.
  final bool readOnlyView;
  final TimeCorrectionDetail detail;
  final bool cancelling;
  final bool downloading;

  const _Body({
    required this.id,
    required this.approver,
    this.readOnlyView = false,
    required this.detail,
    required this.cancelling,
    required this.downloading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final attachment = detail.attachmentUrl;
    final result = detail.result;
    final canCancel =
        !approver &&
        !readOnlyView &&
        detail.canCancelBy(ref.watch(attendanceOwnEmployeeIdProvider));

    return Column(
      children: [
        TimeCorrectionSummaryCard(detail: detail),
        if (result != null) ...[
          heightBx(h: 16),
          TimeCorrectionResultCard(result: result),
        ],
        heightBx(h: 16),
        TimeCorrectionTimesCard(
          detail: detail,
          title: l10n.attCorrectionRequested,
        ),
        if (detail.reason.isNotEmpty) ...[
          heightBx(h: 16),
          TimeCorrectionReasonCard(reason: detail.reason),
        ],
        if (attachment != null) ...[
          heightBx(h: 16),
          TimeCorrectionAttachmentCard(
            url: attachment,
            downloading: downloading,
            onView: () => showImageViewer(
              context,
              attachment,
              errorText: l10n.leaveFileOpenFailed,
            ),
            onDownload: () => _download(context, ref),
          ),
        ],
        if (detail.steps.isNotEmpty) ...[
          heightBx(h: 16),
          TimeCorrectionApprovalWorkflow(
            steps: detail.steps,
            currentStepNo: detail.currentStepNo,
            cancelled: detail.status == TimeCorrectionStatus.cancelled,
          ),
        ],
        if (canCancel) ...[
          heightBx(h: 24),
          _CancelButton(
            loading: cancelling,
            onTap: () => _cancel(context, ref),
          ),
        ],
        if (approver) ...[heightBx(h: 24), _ApproverActions(detail: detail)],
        if (!approver && !readOnlyView) ...[
          heightBx(h: 16),
          customText(
            l10n.timeCorrectionContactNote,
            fontSize: 13,
            color: AppColors.secondaryTxt,
            alight: TextAlign.center,
            maxLine: 2,
          ),
        ],
      ],
    );
  }

  /// Asks first, then withdraws it. The page stays and shows the request as
  /// it now is: cancelled, or — "already decided" — as it was decided.
  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(
      timeCorrectionDetailNotifierProvider(id).notifier,
    );
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.leaveCancelAction,
      message: l10n.timeCorrectionCancelConfirm,
      confirmLabel: l10n.leaveCancelAction,
    );
    if (!confirmed) return;

    final result = await notifier.cancel();
    // Null: a withdrawal already on its way says how it went.
    result?.fold(
      (failure) => AppToast.error(failure.localize(l10n)),
      (_) => AppToast.success(l10n.timeCorrectionCancelled),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await ref
        .read(timeCorrectionDetailNotifierProvider(id).notifier)
        .saveAttachment();

    switch (outcome) {
      case AttachmentSaveOutcome.saved:
        AppToast.success(l10n.timeCorrectionAttachmentSaved);
      case AttachmentSaveOutcome.failed:
        AppToast.error(l10n.timeCorrectionAttachmentSaveFailed);
      case AttachmentSaveOutcome.dismissed:
        break;
    }
  }
}

/// Approve and Reject for the approver (#47), when the waiting step is
/// theirs; the "your own request" line on their own.
class _ApproverActions extends ConsumerWidget {
  const _ApproverActions({required this.detail});

  final TimeCorrectionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user),
    );
    final provider = timeCorrectionDecisionNotifierProvider(detail.id);
    final decision = ref.watch(provider);

    if (ApproverAccess.isOwnAttendance(detail, user?.employeeId) &&
        detail.status == TimeCorrectionStatus.pending) {
      return customText(
        l10n.leaveOwnRequestNoActions,
        fontSize: 13,
        color: AppColors.subTitle,
        alight: TextAlign.center,
        maxLine: 3,
      );
    }
    if (decision.notMine ||
        decision.decided ||
        !ApproverAccess.canDecideAttendance(detail, user)) {
      return const SizedBox.shrink();
    }
    return ApprovalDecisionRow(
      enabled: !decision.deciding,
      onApprove: () => AttendanceDecisionFlow.approve(
        context,
        ref.read(provider.notifier),
        detail,
      ),
      onReject: () => AttendanceDecisionFlow.reject(
        context,
        ref.read(provider.notifier),
        detail,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.approver = false});

  final bool approver;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 15, 8),
      child: Row(
        children: [
          IconButton(
            // Opened from a toast or a link there may be no page underneath:
            // "My requests" on its "forgot to scan" tab.
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(
                    approver
                        ? AppRoutes.timeCorrectionApprovals
                        : AppRoutes.timeCorrectionHistory,
                  ),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          Expanded(
            child: customText(
              l10n.timeCorrectionDetailTitle,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _CancelButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.danger.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 54,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.danger,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.danger,
                      ),
                      widthBx(w: 8),
                      Flexible(
                        child: customText(
                          l10n.leaveCancelAction,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The list row while the request loads, when there is one, over
/// placeholders for the rest.
class _Loading extends StatelessWidget {
  final TimeCorrectionRecord? initial;

  const _Loading({this.initial});

  @override
  Widget build(BuildContext context) {
    final initial = this.initial;
    return Column(
      children: [
        if (initial != null) ...[
          TimeCorrectionRecordCard(record: initial),
          heightBx(h: 16),
        ],
        for (final height in const [150.0, 260.0, 110.0])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerBox(width: double.infinity, height: height),
          ),
      ],
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _LoadFailed({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retry = onRetry;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
          heightBx(h: 8),
          customText(
            message,
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
