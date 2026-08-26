import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_approval.dart';
import '../../domain/entities/leave_status.dart';
import '../providers/leave_approvals_notifier.dart';
import 'leave_copy.dart';

/// "ອະນຸມັດຈາກສາຍງານ" — subordinates' leave requests still awaiting a
/// decision, each approvable/rejectable inline, followed by everything
/// already decided. Everything comes from [leaveApprovalsNotifierProvider];
/// the tab holds no fetching logic of its own.
///
/// There is no role check here yet — the app has no manager/employee
/// distinction to gate on, so this tab shows for every account until one
/// exists.
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
            itemBuilder: (approval) => _PendingApprovalCard(
              approval: approval,
              deciding: state.decidingIds.contains(approval.id),
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
            itemBuilder: (approval) => _HistoryApprovalRow(approval: approval),
          ),
        ],
      ),
    );
  }
}

class _ApprovalList extends ConsumerWidget {
  final AsyncValue<List<LeaveApproval>> value;
  final String emptyMessage;
  final Widget Function(LeaveApproval) itemBuilder;

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
        onRetry: () => ref.read(leaveApprovalsNotifierProvider.notifier).retry(),
      );
    }

    final items = value.valueOrNull ?? const [];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: customText(emptyMessage, color: AppColors.subTitle, fontSize: 13),
      );
    }

    return Column(children: [for (final a in items) itemBuilder(a)]);
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
            customText(message, color: AppColors.subTitle, alight: TextAlign.center),
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
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _PendingApprovalCard extends ConsumerWidget {
  final LeaveApproval approval;
  final bool deciding;

  const _PendingApprovalCard({required this.approval, required this.deciding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

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
              _Avatar(name: approval.requesterName),
              widthBx(w: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText(
                      approval.requesterName,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    heightBx(h: 2),
                    customText(
                      '${LeaveCopy.categoryLabel(l10n, approval.category)} • '
                      '${LeaveCopy.dateLine(
                        l10n,
                        startDate: approval.startDate,
                        endDate: approval.endDate,
                        totalDays: approval.totalDays,
                      )}',
                      fontSize: 12,
                      color: AppColors.subTitle,
                    ),
                  ],
                ),
              ),
              if (approval.isNew) _NewBadge(label: l10n.leaveApprovalNewBadge),
            ],
          ),
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
              '"${approval.reason}"',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          heightBx(h: 12),
          Row(
            children: [
              Expanded(
                child: _DecisionButton(
                  label: l10n.leaveApprovalApproveAction,
                  icon: Icons.check,
                  color: AppColors.primary,
                  enabled: !deciding,
                  onTap: () => _decide(context, ref, approve: true),
                ),
              ),
              widthBx(w: 12),
              Expanded(
                child: _DecisionButton(
                  label: l10n.leaveApprovalRejectAction,
                  icon: Icons.close,
                  color: AppColors.danger,
                  enabled: !deciding,
                  onTap: () => _decide(context, ref, approve: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ref
        .read(leaveApprovalsNotifierProvider.notifier)
        .decide(approval.id, approve: approve);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.leaveApprovalDecideFailed)));
  }
}

class _NewBadge extends StatelessWidget {
  final String label;

  const _NewBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          customText(
            label,
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          widthBx(w: 4),
          const Icon(Icons.notifications, size: 13, color: AppColors.warning),
        ],
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
  final LeaveApproval approval;

  const _HistoryApprovalRow({required this.approval});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pill = LeaveCopy.statusPill(l10n, approval.status);

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
          _Avatar(name: approval.requesterName),
          widthBx(w: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  '${approval.requesterName} • '
                  '${LeaveCopy.categoryLabel(l10n, approval.category)}',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                heightBx(h: 2),
                customText(
                  LeaveCopy.dateLine(
                    l10n,
                    startDate: approval.startDate,
                    endDate: approval.endDate,
                    totalDays: approval.totalDays,
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
                  approval.status == LeaveStatus.rejected
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
