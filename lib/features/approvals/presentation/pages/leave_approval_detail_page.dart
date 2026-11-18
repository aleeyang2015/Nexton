import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../../time_off/data/datasources/leave_error_code.dart';
import '../../../time_off/domain/entities/leave_request.dart';
import '../../../time_off/presentation/providers/leave_request_detail_notifier.dart';
import '../../../time_off/presentation/widgets/leave_request_detail_body.dart';
import '../../../time_off/presentation/widgets/leave_request_unavailable.dart';
import '../../domain/approver_access.dart';
import '../widgets/leave_approval_actions.dart';

/// One leave request as its approver sees it, opened by its id from the
/// Approvals lists: who asked, every day, the reason, the files, the chain
/// with its notes and dates, and — when the waiting step is theirs
/// ([ApproverAccess.canDecideLeave]) — Approve and Reject.
///
/// Loads its own copy by id ([leaveRequestDetailNotifierProvider]) and can
/// be pulled to refresh; [initial] is the list row, shown while it loads.
class LeaveApprovalDetailPage extends ConsumerWidget {
  const LeaveApprovalDetailPage({
    super.key,
    required this.requestId,
    this.initial,
    this.readOnly = false,
  });

  final String requestId;
  final LeaveRequest? initial;

  /// A head's read-only view of a team member's request (#50): no buttons;
  /// a `404` on the page's own read (moved department) keeps the row's copy,
  /// with no error.
  final bool readOnly;

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
    final keepRow = readOnly && gone && initial != null;
    final request = keepRow
        ? initial
        : gone
        ? null
        : (loaded.valueOrNull ?? initial);

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
              // Opened from a link there may be no page underneath.
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.approvals),
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
                  // The buttons wait for the page's own copy: the list row
                  // may be out of date.
                  child: _Body(
                    request: request,
                    loaded: loaded.hasValue && !readOnly,
                  ),
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

class _Body extends ConsumerWidget {
  const _Body({required this.request, required this.loaded});

  final LeaveRequest request;

  /// True once the page's own copy is in, not just the list row.
  final bool loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user),
    );
    final canDecide = loaded && ApproverAccess.canDecideLeave(request, user);

    return ListView(
      // Always scrollable, so a short request can still be pulled to refresh.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
      children: [
        _EmployeeCard(request: request),
        heightBx(h: 12),
        LeaveRequestDetailBody(request: request, showEveryDay: true),
        if (canDecide) ...[
          heightBx(h: 20),
          LeaveApprovalActions(request: request),
        ],
      ],
    );
  }
}

/// Who asked: name, employee number and department.
class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = request.employeeNumber;
    final department = request.departmentName;

    return LeaveDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            l10n.apprEmployeeLabel,
            fontSize: 12,
            color: AppColors.subTitle,
          ),
          heightBx(h: 4),
          customText(
            request.employeeName,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          if (number != null && number.isNotEmpty)
            LeaveInfoRow(icon: Icons.badge_outlined, text: number),
          if (department != null && department.isNotEmpty)
            LeaveInfoRow(icon: Icons.apartment_outlined, text: department),
        ],
      ),
    );
  }
}
