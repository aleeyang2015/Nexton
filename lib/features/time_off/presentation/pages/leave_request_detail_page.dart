import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../providers/leave_request_detail_notifier.dart';
import '../widgets/leave_request_detail_body.dart';
import '../widgets/leave_request_unavailable.dart';

/// The full view of one of the employee's own leave requests, opened by its
/// id: from a history card, the "waiting" banner, or a push notification.
///
/// The page loads its own copy ([leaveRequestDetailNotifierProvider]) and
/// can be pulled to refresh, so a decision HR made a minute ago shows without
/// leaving the page. [initial] is the copy the caller already had; it is
/// shown while the first load runs. After a cancel, an edit, or a refusal
/// that says the page is out of date, the page reloads in place.
///
/// Shows the real approval chain and, while the request still allows it, the
/// Edit and Cancel actions.
class LeaveRequestDetailPage extends ConsumerWidget {
  const LeaveRequestDetailPage({
    super.key,
    required this.requestId,
    this.initial,
  });

  final String requestId;
  final LeaveRequest? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loaded = ref.watch(leaveRequestDetailNotifierProvider(requestId));
    final error = loaded.error;
    // A request the server says is gone is not shown from an old copy.
    final gone =
        loaded.hasError &&
        error is Failure &&
        LeaveErrorCode.isRequestGone(error);
    final request = gone ? null : (loaded.valueOrNull ?? initial);

    // Someone else's request (opened from a push, #53): the approver's page
    // instead, with the copy just loaded.
    ref.listen(leaveRequestDetailNotifierProvider(requestId), (_, next) {
      final loadedRequest = next.valueOrNull;
      if (loadedRequest == null || next.isLoading) return;
      final user = ref.read(authSessionProvider).valueOrNull?.user;
      if (ApproverAccess.opensAsApprover(
        ownerId: loadedRequest.employeeId,
        user: user,
      )) {
        context.replace(
          AppRoutes.approvalLeave(requestId),
          extra: loadedRequest,
        );
      }
    });

    // The copy handed in is on screen and the page's own load failed: say
    // so, or the old copy would pass for the current one.
    ref.listen(leaveRequestDetailNotifierProvider(requestId), (previous, next) {
      final failure = next.error;
      if (next.hasError &&
          !next.isLoading &&
          previous?.hasError != true &&
          initial != null &&
          failure is Failure &&
          !LeaveErrorCode.isRequestGone(failure)) {
        AppToast.error(failure.localize(l10n));
      }
    });

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              // Opened from a push there may be no page underneath.
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.timeOff),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
            ),
            title: customText(
              l10n.leaveDetailTitle,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
          body: request != null
              ? RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _refresh(context, ref),
                  child: _RequestBody(request: request),
                )
              : loaded.hasError && !loaded.isLoading
              ? LeaveRequestUnavailable(
                  error: error,
                  onRetry: () => ref.invalidate(
                    leaveRequestDetailNotifierProvider(requestId),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
        ),
      ),
    );
  }

  /// A pull to refresh. A reload that fails says why; the request already
  /// on screen stays.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final failure = await ref
        .read(leaveRequestDetailNotifierProvider(requestId).notifier)
        .refresh();
    if (failure != null && !LeaveErrorCode.isRequestGone(failure)) {
      AppToast.error(failure.localize(l10n));
    }
  }
}

/// The request's cards and its actions.
class _RequestBody extends ConsumerStatefulWidget {
  const _RequestBody({required this.request});

  final LeaveRequest request;

  @override
  ConsumerState<_RequestBody> createState() => _RequestBodyState();
}

class _RequestBodyState extends ConsumerState<_RequestBody> {
  /// True while a cancel is on its way, so the button cannot be tapped twice.
  bool _cancelling = false;

  LeaveRequest get request => widget.request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cancelling = _cancelling;
    // The phone's date. The server goes by the company's; where the two
    // differ around midnight, its refusal decides.
    final today = ref.watch(clockProvider)();
    final canCancel = request.canCancelInApp(today);
    final started = request.hasStartedOn(today);

    return ListView(
      // Always scrollable, so a short request can still be pulled to refresh.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
      children: [
        LeaveRequestDetailBody(request: request),
        if (started) ...[
          heightBx(h: 12),
          _StartedNotice(message: l10n.leaveStartedContactHr),
        ],
        if (request.canEdit || canCancel) ...[
          heightBx(h: 20),
          if (request.canEdit)
            button(_edit, l10n.leaveEditAction),
          if (request.canEdit && canCancel) heightBx(h: 10),
          if (canCancel)
            OutlinedButton(
              onPressed: cancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: customText(
                l10n.leaveCancelAction,
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
        ],
      ],
    );
  }

  /// Opens the edit page. It closes with `true` after a save, and after a
  /// save the server refused as out of date; either way this page reloads.
  Future<void> _edit() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(
      leaveRequestDetailNotifierProvider(request.id).notifier,
    );
    final changed = await context.push<bool>(
      AppRoutes.timeOffRequestEditOf(request.id),
      extra: request,
    );
    if (changed != true) return;

    // If the reload fails the page still shows the request as it was before
    // the edit: say so.
    final failure = await notifier.refresh();
    if (failure != null && !LeaveErrorCode.isRequestGone(failure)) {
      AppToast.error(failure.localize(l10n));
    }
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.leaveCancelAction,
      // Cancelling an approved leave gives its days back; say so.
      message: request.status == LeaveStatus.approved
          ? l10n.leaveCancelApprovedConfirm
          : l10n.leaveCancelConfirm,
      confirmLabel: l10n.leaveCancelAction,
    );
    if (!confirmed || !mounted || _cancelling) return;

    setState(() => _cancelling = true);
    // The notifier shows the cancelled request, or reloads the page when the
    // refusal says it is out of date. The words are said whether or not
    // this body is still on screen by then.
    final result = await ref
        .read(leaveRequestDetailNotifierProvider(request.id).notifier)
        .cancel();
    if (mounted) setState(() => _cancelling = false);

    result.fold(
      (failure) => AppToast.error(failure.localize(l10n)),
      (_) => AppToast.success(l10n.leaveRequestCancelled),
    );
  }
}

/// "This leave has started": why an approved leave has no Cancel button.
class _StartedNotice extends StatelessWidget {
  final String message;

  const _StartedNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          widthBx(w: 8),
          Expanded(
            child: customText(
              message,
              fontSize: 12.5,
              color: AppColors.textPrimary,
              maxLine: 4,
            ),
          ),
        ],
      ),
    );
  }
}
