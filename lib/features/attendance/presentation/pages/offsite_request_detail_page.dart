import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/upload/presentation/file_link_image.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/attendance_failure_x.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import '../providers/offsite_detail_notifier.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../providers/offsite_decision_notifier.dart';
import '../widgets/offsite_approval_card.dart';
import '../widgets/attendance_decision_flow.dart';
import '../widgets/offsite_record_card.dart';
import '../widgets/time_correction_approval_workflow.dart';

/// One of the employee's off-site requests (#42), opened by its id from
/// "My requests" or the send toast's "View": the photo, the time, check-in
/// or check-out, the place, the reason, the steps with their notes and
/// dates, and — while it still waits — "Cancel request".
///
/// Loads its own copy by id; [initial] (the list row) is shown meanwhile.
/// Pull to refresh.
///
/// With [approver] (#46, `/approvals/offsite/:id`) it is an approver's page
/// of someone's scan: who filed it, the photo full size, the steps, and —
/// when the waiting step is theirs — Approve and Reject; never Cancel.
class OffsiteRequestDetailPage extends ConsumerWidget {
  const OffsiteRequestDetailPage({
    super.key,
    required this.requestId,
    this.initial,
    this.approver = false,
  });

  final String requestId;
  final OffsiteRequestDetail? initial;
  final bool approver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = offsiteDetailNotifierProvider(requestId);
    final loaded = ref.watch(provider);
    final gone = OffsiteDetailNotifier.isGone(loaded.error);
    // The list row only while the page's own copy loads: a load that failed
    // says so rather than leave the row passing for the request.
    final request =
        loaded.valueOrNull ?? (loaded.hasError || gone ? null : initial);
    final cancelling = ref.watch(offsiteCancellingProvider(requestId));
    final error = loaded.error;
    final notLinked = error is Failure && error.isEmployeeNotLinked;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          // Opened from a toast or a link there may be no page underneath.
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(approver ? AppRoutes.approvals : AppRoutes.myRequests),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: customText(
          l10n.attOffsiteDetailTitle,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      body: request != null
          ? RefreshIndicator(
              onRefresh: () => _refresh(context, ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 32),
                children: approver
                    ? [_ApproverBody(request: request)]
                    : [
                  OffsiteRecordCard(
                    request: request,
                    onViewImage: (url) => showImageViewer(
                      context,
                      url,
                      errorText: l10n.leaveFileOpenFailed,
                      onExpired: _renewLinks(context, ref, requestId),
                    ),
                    // Shown by the card only while the request waits.
                    onCancel: () => _cancel(context, ref),
                    cancelling: cancelling,
                  ),
                  heightBx(h: 16),
                  TimeCorrectionApprovalWorkflow(
                    steps: request.steps,
                    currentStepNo: request.currentStepNo,
                    cancelled: request.status == TimeCorrectionStatus.cancelled,
                  ),
                      ],
              ),
            )
          : loaded.hasError && !loaded.isLoading
          ? _Unavailable(
              // No staff record: #11's "not linked" text; nothing to retry.
              text: gone
                  ? l10n.apprRequestNotFound
                  : notLinked
                  ? error.localize(l10n)
                  : l10n.offsiteHistoryLoadFailed,
              onRetry: gone || notLinked
                  ? null
                  : () => ref.invalidate(provider),
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final failure = await ref
        .read(offsiteDetailNotifierProvider(requestId).notifier)
        .refresh();
    if (failure != null && !OffsiteDetailNotifier.isGone(failure)) {
      AppToast.error(failure.localize(l10n));
    }
  }

  /// Asks first, then withdraws it. On "already decided" the page shows the
  /// request as it now is (it was loaded again).
  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(
      offsiteDetailNotifierProvider(requestId).notifier,
    );
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.offsiteCancelAction,
      message: l10n.offsiteCancelConfirm,
      confirmLabel: l10n.offsiteCancelAction,
    );
    if (!confirmed) return;

    final result = await notifier.cancel();
    // Null: a withdrawal already on its way says how it went.
    result?.fold(
      (failure) => AppToast.error(failure.localize(l10n)),
      (_) => AppToast.success(l10n.offsiteCancelled),
    );
  }
}

/// The approver's page (#46): the request's card (who filed it, the scan,
/// the place, the reason), the photo full size, the steps, and the decision.
class _ApproverBody extends ConsumerWidget {
  const _ApproverBody({required this.request});

  final OffsiteRequestDetail request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user),
    );
    final decision = ref.watch(offsiteDecisionNotifierProvider(request.id));
    final photo = request.attachmentUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OffsiteApprovalCard(
          request: request,
          deciding: decision.deciding,
          canDecide:
              !decision.notMine &&
              ApproverAccess.canDecideAttendance(request, user),
          own: ApproverAccess.isOwnAttendance(request, user?.employeeId),
          rejectOnly: decision.rejectOnly,
          onApprove: () => _decided(
            context,
            AttendanceDecisionFlow.approve(
              context,
              ref.read(offsiteDecisionNotifierProvider(request.id).notifier),
              request,
            ),
          ),
          onReject: () => _decided(
            context,
            AttendanceDecisionFlow.reject(
              context,
              ref.read(offsiteDecisionNotifierProvider(request.id).notifier),
              request,
            ),
          ),
          onViewImage: (url) => showImageViewer(
            context,
            url,
            errorText: l10n.leaveFileOpenFailed,
            onExpired: _renewLinks(context, ref, request.id),
          ),
        ),
        if (photo != null) ...[
          heightBx(h: 16),
          GestureDetector(
            onTap: () => showImageViewer(
              context,
              photo,
              errorText: l10n.leaveFileOpenFailed,
              onExpired: _renewLinks(context, ref, request.id),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FileLinkImage(
                url: photo,
                fallback: const SizedBox.shrink(),
                onExpired: _renewLinks(context, ref, request.id),
              ),
            ),
          ),
        ],
        heightBx(h: 16),
        TimeCorrectionApprovalWorkflow(
          steps: request.steps,
          currentStepNo: request.currentStepNo,
          cancelled: request.status == TimeCorrectionStatus.cancelled,
        ),
      ],
    );
  }

  /// Decided: back to the list, which has been read again. Refused: the page
  /// stays, read again when the request moved on.
  static Future<void> _decided(BuildContext context, Future<bool> done) async {
    if (!await done || !context.mounted) return;
    context.canPop() ? context.pop() : context.go(AppRoutes.approvals);
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retry = onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: AppColors.gray400,
              size: 40,
            ),
            heightBx(h: 10),
            customText(
              text,
              color: AppColors.subTitle,
              alight: TextAlign.center,
              maxLine: 3,
            ),
            if (retry != null) ...[
              heightBx(h: 12),
              TextButton(
                onPressed: retry,
                child: customText(l10n.retry, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The scan read again, quietly, when one of its photo links has expired
/// (#73): every read gives new links, which last an hour. The page shows
/// what it has meanwhile; a failure here changes nothing on it.
VoidCallback _renewLinks(BuildContext context, WidgetRef ref, String id) =>
    () {
      if (!context.mounted) return;
      ref.read(offsiteDetailNotifierProvider(id).notifier).refresh();
    };
