import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/presentation/widgets/leave_reject_reason_dialog.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import '../providers/time_correction_approvals_notifier.dart';
import '../widgets/time_correction_approval_card.dart';
import '../widgets/time_correction_approval_filters.dart';
import '../widgets/time_correction_history_summary.dart';
import '../widgets/time_correction_image_viewer.dart';

/// "ຄຳຮ້ອງແກ້ໄຂເວລາ" — the time-correction requests the signed-in approver
/// decides on, reached from the "ອະນຸມັດແກ້ໄຂເວລາ" menu tile. A search box
/// and a status dropdown narrow the list; each pending card approves or
/// rejects inline. Everything comes from [timeCorrectionApprovalsNotifierProvider].
///
/// The endpoint scopes to the caller's role, so a non-approver simply sees
/// an empty list — there is no role gate here, as on the leave approvals tab.
class TimeCorrectionApprovalsPage extends ConsumerWidget {
  const TimeCorrectionApprovalsPage({super.key});

  /// The statuses an approver filters by — there is no "all" here, and
  /// cancelled requests are the employee's business, so both are left out
  /// of the dropdown. The list always shows one status at a time.
  static const List<TimeCorrectionStatus?> _filters = [
    TimeCorrectionStatus.pending,
    TimeCorrectionStatus.approved,
    TimeCorrectionStatus.rejected,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeCorrectionApprovalsNotifierProvider);
    final notifier = ref.read(timeCorrectionApprovalsNotifierProvider.notifier);

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              const _Header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
                child: Column(
                  children: [
                    TimeCorrectionApprovalSearchField(
                      onChanged: notifier.search,
                    ),
                    heightBx(h: 12),
                    TimeCorrectionFilterDropdown(
                      selected: state.filter,
                      countOf: state.countOf,
                      onSelect: notifier.selectFilter,
                      options: _filters,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 14, 15, 32),
                    children: const [_RequestsList()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 15, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          Expanded(
            child: customText(
              l10n.timeCorrectionApprovalsTitle,
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

/// The visible requests, or the list's loading, failed or empty state.
/// Requests already on screen stay visible while a refresh runs.
class _RequestsList extends ConsumerWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(timeCorrectionApprovalsNotifierProvider);
    final requests = state.requests;

    if (requests.isLoading && !requests.hasValue) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerBox(width: double.infinity, height: 220),
          ),
        ),
      );
    }

    if (requests.hasError && !requests.hasValue) {
      return _Message(
        icon: Icons.error_outline,
        text: l10n.timeCorrectionApprovalsLoadFailed,
        onRetry: ref
            .read(timeCorrectionApprovalsNotifierProvider.notifier)
            .refresh,
      );
    }

    final visible = state.visible;
    if (visible.isEmpty) {
      return _Message(
        icon: Icons.inbox_outlined,
        text: l10n.timeCorrectionApprovalsEmpty,
      );
    }

    return Column(
      children: [
        for (final request in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TimeCorrectionApprovalCard(
              request: request,
              deciding: state.decidingIds.contains(request.id),
              onApprove: () => _approve(context, ref, request),
              onReject: () => _reject(context, ref, request),
              onViewImage: (url) => showTimeCorrectionImage(context, url),
            ),
          ),
      ],
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    TimeCorrectionDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final failure = await ref
        .read(timeCorrectionApprovalsNotifierProvider.notifier)
        .approve(request.id);
    if (!context.mounted) return;

    if (failure == null) {
      AppToast.success(l10n.timeCorrectionApprovalApproved);
    } else {
      AppToast.error(failure.localize(l10n));
    }
  }

  /// Collects the rejection reason with the same dialog the leave approvals
  /// tab uses, then rejects.
  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    TimeCorrectionDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await LeaveRejectReasonDialog.show(context);
    if (reason == null || !context.mounted) return;

    final failure = await ref
        .read(timeCorrectionApprovalsNotifierProvider.notifier)
        .reject(request.id, reason);
    if (!context.mounted) return;

    if (failure == null) {
      AppToast.success(l10n.timeCorrectionApprovalRejected);
    } else {
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
