import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../providers/leave_approvals_notifier.dart';
import '../providers/leave_approvals_state.dart';
import 'leave_copy.dart';
import 'leave_reject_reason_dialog.dart';

/// "ອະນຸມັດຈາກສາຍງານ" — the requests awaiting the signed-in approver's
/// decision (`my-approvals?status=pending`), each approvable / rejectable
/// inline, followed by everything already decided. Everything comes from
/// [leaveApprovalsNotifierProvider].
///
/// The endpoint scopes to the caller's role, so a non-approver simply sees an
/// empty pending list — there is no role gate here.
class LeaveApprovalsTab extends ConsumerWidget {
  const LeaveApprovalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(leaveApprovalsNotifierProvider);
    final pendingCount = state.pending.valueOrNull?.length ?? 0;

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
        children: [
          customText(
            l10n.leaveApprovalsPendingHeader(pendingCount),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          heightBx(h: 12),
          _ApprovalList(
            value: state.pending,
            emptyMessage: l10n.leaveApprovalsPendingEmpty,
            itemBuilder: (request) => _PendingApprovalCard(
              request: request,
              deciding: state.decidingIds.contains(request.id),
            ),
          ),
          heightBx(h: 24),
          customText(
            l10n.leaveApprovalsHistoryHeader,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          heightBx(h: 12),
          _ApprovalList(
            value: state.history,
            emptyMessage: l10n.leaveApprovalsHistoryEmpty,
            itemBuilder: (request) => _HistoryApprovalRow(request: request),
          ),
        ],
      ),
    );
  }
}

class _ApprovalList extends ConsumerWidget {
  final AsyncValue<List<LeaveRequest>> value;
  final String emptyMessage;
  final Widget Function(LeaveRequest) itemBuilder;

  const _ApprovalList({
    required this.value,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onRetry: () =>
            ref.read(leaveApprovalsNotifierProvider.notifier).retry(),
      );
    }

    final items = value.valueOrNull ?? const [];
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

  const _PendingApprovalCard({required this.request, required this.deciding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stepLabel = request.currentStep == null
        ? null
        : LeaveCopy.stepRoleLabel(l10n, request.currentStep!.role);

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
                      '${LeaveCopy.leaveTypeLabel(l10n, request.leaveType)} • '
                      '${LeaveCopy.dateLine(l10n, startDate: request.startDate, endDate: request.endDate, totalDays: request.totalDays)}',
                      fontSize: 12,
                      color: AppColors.subTitle,
                      maxLine: 2,
                    ),
                  ],
                ),
              ),
              if (stepLabel != null) _StepChip(label: stepLabel),
            ],
          ),
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
          Row(
            children: [
              Expanded(
                child: _DecisionButton(
                  label: l10n.leaveApprovalApproveAction,
                  icon: Icons.check,
                  color: AppColors.primary,
                  enabled: !deciding,
                  onTap: () => _approve(context, ref),
                ),
              ),
              widthBx(w: 12),
              Expanded(
                child: _DecisionButton(
                  label: l10n.leaveApprovalRejectAction,
                  icon: Icons.close,
                  color: AppColors.danger,
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

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(leaveApprovalsNotifierProvider.notifier)
        .approve(request);
    if (context.mounted) _report(context, outcome);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await LeaveRejectReasonDialog.show(context);
    if (reason == null || !context.mounted) return;
    final outcome = await ref
        .read(leaveApprovalsNotifierProvider.notifier)
        .reject(request, reason);
    if (context.mounted) _report(context, outcome);
  }

  void _report(BuildContext context, LeaveDecisionOutcome outcome) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (outcome) {
      LeaveDecisionOutcome.success => null,
      LeaveDecisionOutcome.stepChanged => l10n.leaveStepRefreshed,
      LeaveDecisionOutcome.failed => l10n.leaveApprovalDecideFailed,
    };
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StepChip extends StatelessWidget {
  final String label;

  const _StepChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: customText(
        label,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: enabled ? color : AppColors.gray300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      icon: Icon(icon, size: 16, color: enabled ? color : AppColors.gray400),
      label: customText(
        label,
        color: enabled ? color : AppColors.gray400,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _HistoryApprovalRow extends StatelessWidget {
  final LeaveRequest request;

  const _HistoryApprovalRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pill = LeaveCopy.statusPill(l10n, request.status);

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
                  '${LeaveCopy.leaveTypeLabel(l10n, request.leaveType)}',
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
                  request.status == LeaveStatus.rejected
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
