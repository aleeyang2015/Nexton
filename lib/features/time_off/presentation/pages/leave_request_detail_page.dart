import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_approval_step.dart';
import '../../domain/entities/leave_request.dart';
import '../providers/leave_history_notifier.dart';
import '../widgets/leave_approval_timeline.dart';
import '../widgets/leave_copy.dart';

/// The full view of one of the employee's own leave requests, reached by
/// tapping a history card. Shows the real approval chain and — while the
/// request still allows it — the Edit and Cancel actions
/// (leave-request-flutter.md §3.4/§3.5).
class LeaveRequestDetailPage extends ConsumerWidget {
  const LeaveRequestDetailPage({super.key, required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pill = LeaveCopy.statusPill(l10n, request.status);
    final cancelling = ref
        .watch(leaveHistoryNotifierProvider)
        .cancellingIds
        .contains(request.id);

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
              onTap: () => context.pop(),
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
          body: ListView(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
            children: [
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: customText(
                            LeaveCopy.leaveTypeLabel(l10n, request.leaveType),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        _Pill(label: pill.label, color: pill.color),
                      ],
                    ),
                    heightBx(h: 8),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      text: LeaveCopy.dateLine(
                        l10n,
                        startDate: request.startDate,
                        endDate: request.endDate,
                        totalDays: request.totalDays,
                      ),
                    ),
                    if (request.durationType.isHalfDay)
                      _InfoRow(
                        icon: Icons.timelapse_outlined,
                        text: LeaveCopy.durationLabel(
                          l10n,
                          request.durationType,
                        ),
                      ),
                    if (request.returnDate != null)
                      _InfoRow(
                        icon: Icons.work_history_outlined,
                        text:
                            '${l10n.leaveReturnToWorkLabel}: '
                            '${LeaveCopy.shortDate(l10n, request.returnDate!)}',
                      ),
                  ],
                ),
              ),
              if (request.requestDays.length > 1) ...[
                heightBx(h: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        l10n.leaveSelectDatesLabel,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      heightBx(h: 8),
                      for (final d in request.requestDays)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            text: LeaveCopy.shortDate(l10n, d),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (request.reason.isNotEmpty) ...[
                heightBx(h: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        l10n.leaveRequestReasonLabel,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      heightBx(h: 6),
                      customText(
                        request.reason,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        maxLine: 10,
                      ),
                    ],
                  ),
                ),
              ],
              if (request.attachments.isNotEmpty) ...[
                heightBx(h: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        l10n.leaveAttachmentsLabel,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      heightBx(h: 6),
                      for (final a in request.attachments)
                        _InfoRow(icon: Icons.attach_file, text: a.fileName),
                    ],
                  ),
                ),
              ],
              heightBx(h: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText(
                      l10n.leaveApprovalChainLabel,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    heightBx(h: 14),
                    LeaveApprovalTimeline(steps: request.steps),
                    heightBx(h: 10),
                    for (final step in request.steps)
                      _StepNote(step: step, l10n: l10n),
                  ],
                ),
              ),
              if (request.canEdit || request.canCancel) ...[
                heightBx(h: 20),
                if (request.canEdit)
                  button(() => _edit(context), l10n.leaveEditAction),
                if (request.canEdit && request.canCancel) heightBx(h: 10),
                if (request.canCancel)
                  OutlinedButton(
                    onPressed: cancelling ? null : () => _cancel(context, ref),
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
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final changed = await context.push<bool>(
      AppRoutes.timeOffRequestEdit,
      extra: request,
    );
    if (changed == true && context.mounted) context.pop();
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.leaveCancelAction,
      message: l10n.leaveCancelConfirm,
      confirmLabel: l10n.leaveCancelAction,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref
        .read(leaveHistoryNotifierProvider.notifier)
        .cancel(request.id);
    if (!context.mounted) return;

    if (ok) {
      AppToast.success(l10n.leaveRequestCancelled);
      context.pop();
    } else {
      AppToast.error(l10n.leaveRequestCancelFailed);
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: customText(
        label,
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.subTitle),
          widthBx(w: 8),
          Expanded(
            child: customText(
              text,
              fontSize: 13,
              color: AppColors.textPrimary,
              maxLine: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNote extends StatelessWidget {
  final LeaveApprovalStep step;
  final AppLocalizations l10n;

  const _StepNote({required this.step, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final approver = step.approverName;
    final note = step.note;
    if ((approver == null || approver.isEmpty) &&
        (note == null || note.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            '${LeaveCopy.stepRoleLabel(l10n, step.role)}'
            '${approver != null && approver.isNotEmpty ? ' • $approver' : ''}',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          if (note != null && note.isNotEmpty) ...[
            heightBx(h: 2),
            customText(
              '${l10n.leaveApproverNoteLabel}: $note',
              fontSize: 12,
              color: AppColors.subTitle,
              maxLine: 4,
            ),
          ],
        ],
      ),
    );
  }
}
