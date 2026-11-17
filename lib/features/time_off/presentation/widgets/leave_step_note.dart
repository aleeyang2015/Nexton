import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_approval_step.dart';
import 'leave_copy.dart';

/// Under the approval timeline: who a step is ("ຫົວໜ້າ • Somchai") and the
/// note they left. Nothing for a step with neither. The timeline itself
/// shows only the role, so this is where the approver's name is.
///
/// Shared by the leave request page and the OT request page.
class LeaveStepNote extends StatelessWidget {
  final LeaveApprovalStep step;

  const LeaveStepNote({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
