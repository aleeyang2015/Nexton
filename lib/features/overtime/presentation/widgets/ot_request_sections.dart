import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/presentation/widgets/leave_approval_timeline.dart';
import '../../../time_off/presentation/widgets/leave_step_note.dart';
import '../../domain/entities/ot_request.dart';
import 'ot_copy.dart';
import 'ot_step_adapter.dart';

/// The OT request page's content, top to bottom: the header (day, window,
/// status, who it waits for), the reason, the steps with their notes, the
/// pieces and their pay, HR's note, the notes the request carries, and
/// where the money is.
///
/// It never shows a paid amount: the request has none. Paid hours and money
/// are on the payslip (#24).
class OtRequestSections extends StatelessWidget {
  final OtRequest request;

  const OtRequestSections({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workDate = request.workDate;
    final pill = OtCopy.statusPill(l10n, request.status);
    final waiting = OtCopy.waitingFor(l10n, request);
    final window = OtCopy.window(l10n, request);
    final steps = OtStepAdapter.toLeaveSteps(request.steps);
    final notes = OtCopy.notes(l10n, request);
    final agreement = request.agreementNote;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 40),
      children: [
        _Card(
          children: [
            Row(
              children: [
                Expanded(
                  child: customText(
                    workDate == null ? '' : OtCopy.date(workDate),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (pill != null) _Pill(label: pill.label, color: pill.color),
              ],
            ),
            if (window.isNotEmpty) ...[
              heightBx(h: 4),
              customText(window, fontSize: 15, color: AppColors.subTitle),
            ],
            if (waiting != null) ...[
              heightBx(h: 8),
              customText(
                waiting,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
        _Card(
          title: l10n.leaveRequestReasonLabel,
          children: [
            customText(
              request.reason ?? '—',
              color: AppColors.textPrimary,
              maxLine: 20,
            ),
          ],
        ),
        _Card(
          children: [
            LeaveApprovalTimeline(
              steps: steps,
              requestStatus: OtStepAdapter.toLeaveStatus(request.status),
            ),
            // Who each step is, and the note they left: the timeline shows
            // only the role.
            for (final step in steps) LeaveStepNote(step: step),
          ],
        ),
        if (request.pieces.isNotEmpty)
          _Card(
            children: [
              for (final piece in OtCopy.orderedPieces(request))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: customText(
                    OtCopy.piece(l10n, piece),
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          )
        else if (request.status == OtStatus.pending)
          _Card(
            children: [
              customText(
                l10n.otPiecesSetOnApproval,
                color: AppColors.subTitle,
                maxLine: 4,
              ),
            ],
          ),
        if (agreement != null)
          _Card(
            title: l10n.otAgreementNoteLabel,
            children: [
              customText(agreement, color: AppColors.textPrimary, maxLine: 20),
            ],
          ),
        for (final note in notes)
          _Card(
            children: [
              customText(
                note,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                maxLine: 4,
              ),
            ],
          ),
        if (request.status == OtStatus.approved)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: customText(
              l10n.otPaidOnPayslip,
              fontSize: 13,
              color: AppColors.subTitle,
              maxLine: 4,
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _Card({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            customText(
              title,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.subTitle,
            ),
            heightBx(h: 6),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: customText(
      label,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}
