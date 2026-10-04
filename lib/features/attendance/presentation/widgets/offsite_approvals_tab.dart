import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/presentation/widgets/leave_reject_reason_dialog.dart';
import '../../domain/entities/offsite_detail.dart';
import '../providers/offsite_approvals_notifier.dart';
import '../providers/offsite_approvals_state.dart';
import 'offsite_approval_card.dart';
import 'time_correction_approval_filters.dart';
import 'time_correction_history_summary.dart';
import 'time_correction_image_viewer.dart';

/// "ຄຳຮ້ອງສະແກນນອກພື້ນທີ່" — the off-site scan requests the signed-in approver
/// decides on (§5). A search box and a status dropdown narrow the list; each
/// pending card approves or rejects inline. Everything comes from
/// [offsiteApprovalsNotifierProvider].
///
/// The endpoint scopes to the caller's role, so a non-approver simply sees an
/// empty list — there is no role gate here, as on the other two tabs.
///
/// Body only, with no app bar of its own, so it drops straight into the
/// approvals page's third tab.
class OffsiteApprovalsTab extends ConsumerWidget {
  const OffsiteApprovalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offsiteApprovalsNotifierProvider);
    final notifier = ref.read(offsiteApprovalsNotifierProvider.notifier);

    return Container(
      color: AppColors.homeBackground,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
            child: Column(
              children: [
                TimeCorrectionApprovalSearchField(onChanged: notifier.search),
                heightBx(h: 12),
                TimeCorrectionFilterDropdown(
                  selected: state.filter,
                  countOf: state.countOf,
                  onSelect: notifier.selectFilter,
                  options: OffsiteApprovalsState.statuses,
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
    );
  }
}

/// The visible requests, or the list's loading, failed or empty state. Requests
/// already on screen stay visible while a refresh runs.
class _RequestsList extends ConsumerWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(offsiteApprovalsNotifierProvider);
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
        text: l10n.offsiteApprovalsLoadFailed,
        onRetry: ref.read(offsiteApprovalsNotifierProvider.notifier).refresh,
      );
    }

    final visible = state.visible;
    if (visible.isEmpty) {
      return _Message(
        icon: Icons.inbox_outlined,
        text: l10n.offsiteApprovalsEmpty,
      );
    }

    return Column(
      children: [
        for (final request in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OffsiteApprovalCard(
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
    OffsiteRequestDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final failure = await ref
        .read(offsiteApprovalsNotifierProvider.notifier)
        .approve(request);
    if (!context.mounted) return;

    if (failure == null) {
      AppToast.success(l10n.offsiteApprovalApproved);
    } else {
      AppToast.error(failure.localize(l10n));
    }
  }

  /// Collects the rejection reason — §8 requires a note — with the same dialog
  /// the other two approval tabs use, then rejects.
  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    OffsiteRequestDetail request,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await LeaveRejectReasonDialog.show(context);
    if (reason == null || !context.mounted) return;

    final failure = await ref
        .read(offsiteApprovalsNotifierProvider.notifier)
        .reject(request, reason);
    if (!context.mounted) return;

    if (failure == null) {
      AppToast.success(l10n.offsiteApprovalRejected);
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
