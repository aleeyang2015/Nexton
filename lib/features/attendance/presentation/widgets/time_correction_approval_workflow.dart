import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/leave_approval_step.dart';
import '../../domain/entities/time_correction_detail.dart';
import 'time_correction_copy.dart';
import 'time_correction_detail_cards.dart';
import 'time_correction_detail_copy.dart';

/// "ຂັ້ນຕອນການອະນຸມັດ" — the request's approval steps as a vertical
/// timeline, with who holds each and where it stands.
class TimeCorrectionApprovalWorkflow extends StatelessWidget {
  final List<TimeCorrectionApprovalStep> steps;
  final int currentStepNo;

  const TimeCorrectionApprovalWorkflow({
    super.key,
    required this.steps,
    required this.currentStepNo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TimeCorrectionDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimeCorrectionSectionTitle(
            icon: Icons.account_tree_outlined,
            title: l10n.timeCorrectionWorkflowSection,
            trailing: currentStepNo > 0
                ? customText(
                    l10n.timeCorrectionStepOf(currentStepNo, steps.length),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTxt,
                  )
                : null,
          ),
          heightBx(h: 18),
          for (var i = 0; i < steps.length; i++)
            _StepRow(step: steps[i], last: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final TimeCorrectionApprovalStep step;
  final bool last;

  const _StepRow({required this.step, required this.last});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                heightBx(h: 14),
                _StepDot(status: step.status),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: AppColors.primaryTint),
                  ),
              ],
            ),
          ),
          widthBx(w: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: _StepBox(step: step),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final LeaveStepStatus status;

  const _StepDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      LeaveStepStatus.pending => (Icons.schedule, AppColors.attendanceLate),
      LeaveStepStatus.approved => (Icons.check, AppColors.attendancePresent),
      LeaveStepStatus.rejected => (Icons.close, AppColors.danger),
      LeaveStepStatus.waiting => (null, AppColors.gray500),
    };

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
      ),
      child: icon == null
          ? Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            )
          : Icon(icon, size: 16, color: color),
    );
  }
}

class _StepBox extends StatelessWidget {
  final TimeCorrectionApprovalStep step;

  const _StepBox({required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pill = TimeCorrectionDetailCopy.stepStatus(l10n, step);
    final approver = step.approverName;
    final note = step.note;
    final decided =
        step.status == LeaveStepStatus.approved ||
        step.status == LeaveStepStatus.rejected;
    final time = decided
        ? step.actedAt
        : step.status == LeaveStepStatus.pending
        ? step.createdAt
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: customText(
                  '${step.stepNo}. '
                  '${TimeCorrectionDetailCopy.stepRole(l10n, step.role)}',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  maxLine: 2,
                ),
              ),
              widthBx(w: 6),
              TimeCorrectionTag(
                label: pill.label,
                color: pill.color,
                background: pill.color.withValues(alpha: 0.14),
              ),
            ],
          ),
          heightBx(h: 4),
          if (approver != null)
            customText(
              TimeCorrectionDetailCopy.displayName(approver),
              fontSize: 15,
              color: AppColors.textPrimary,
            )
          else
            Text(
              l10n.timeCorrectionApproverUnassigned,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.secondaryTxt,
              ),
            ),
          if (time != null) ...[
            heightBx(h: 6),
            Row(
              children: [
                const Icon(
                  Icons.send_outlined,
                  size: 14,
                  color: AppColors.gray500,
                ),
                widthBx(w: 6),
                Expanded(
                  child: customText(
                    decided
                        ? l10n.timeCorrectionActedAt(
                            TimeCorrectionCopy.submittedAt(time),
                          )
                        : l10n.timeCorrectionSentAt(
                            TimeCorrectionCopy.submittedAt(time),
                          ),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTxt,
                  ),
                ),
              ],
            ),
          ],
          if (note != null) ...[
            heightBx(h: 6),
            customText(
              note,
              fontSize: 13,
              color: AppColors.secondaryTxt,
              maxLine: 4,
            ),
          ],
        ],
      ),
    );
  }
}
