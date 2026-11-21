import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_type.dart';
import '../providers/leave_types_notifier.dart';
import 'attachment_opener.dart';
import 'leave_approval_timeline.dart';
import 'leave_copy.dart';
import 'leave_step_note.dart';

/// The read-only cards of one leave request: type and status, dates, the
/// days, the reason, the files, and the approval chain with its notes.
///
/// Shared by the employee's own request page (which adds Edit and Cancel)
/// and the approver's page (which adds who asked, and Approve and Reject).
class LeaveRequestDetailBody extends ConsumerWidget {
  const LeaveRequestDetailBody({
    super.key,
    required this.request,
    this.showEveryDay = false,
    this.onFileExpired,
  });

  final LeaveRequest request;

  /// Told once when a file's link is past its hour (#73): the page reads
  /// the request again for new links.
  final VoidCallback? onFileExpired;

  /// List the days even when there is one: an approver checks which day.
  /// The employee's own page lists them only when there are two or more.
  final bool showEveryDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pill = LeaveCopy.statusPill(l10n, request.status);
    // The request carries no Lao type name; the loaded list has it.
    final types =
        ref.watch(leaveTypesNotifierProvider).valueOrNull ??
        const <LeaveType>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LeaveDetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: customText(
                      LeaveCopy.leaveTypeLabel(
                        l10n,
                        request.leaveType,
                        types: types,
                      ),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  _Pill(label: pill.label, color: pill.color),
                ],
              ),
              heightBx(h: 8),
              LeaveInfoRow(
                icon: Icons.event_outlined,
                text: LeaveCopy.dateLine(
                  l10n,
                  startDate: request.startDate,
                  endDate: request.endDate,
                  totalDays: request.totalDays,
                ),
              ),
              if (request.durationType.isHalfDay)
                LeaveInfoRow(
                  icon: Icons.timelapse_outlined,
                  text: LeaveCopy.durationLabel(l10n, request.durationType),
                ),
              if (request.returnDate != null)
                LeaveInfoRow(
                  icon: Icons.work_history_outlined,
                  text:
                      '${l10n.leaveReturnToWorkLabel}: '
                      '${LeaveCopy.shortDate(l10n, request.returnDate!)}',
                ),
            ],
          ),
        ),
        if (request.requestDays.length > 1 || showEveryDay) ...[
          heightBx(h: 12),
          LeaveDetailCard(
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
                    child: LeaveInfoRow(
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
          LeaveDetailCard(
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
          LeaveDetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  l10n.leaveAttachmentsLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                heightBx(h: 6),
                // Each opens: a photo full screen, a PDF in the viewer.
                for (final a in request.attachments)
                  LeaveFileTile(file: a, onExpired: onFileExpired),
              ],
            ),
          ),
        ],
        heightBx(h: 12),
        LeaveDetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              customText(
                l10n.leaveApprovalChainLabel,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              heightBx(h: 14),
              LeaveApprovalTimeline(
                steps: request.steps,
                requestStatus: request.status,
              ),
              heightBx(h: 10),
              for (final step in request.steps) LeaveStepNote(step: step),
            ],
          ),
        ),
      ],
    );
  }
}

class LeaveDetailCard extends StatelessWidget {
  final Widget child;

  const LeaveDetailCard({super.key, required this.child});

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

class LeaveInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const LeaveInfoRow({super.key, required this.icon, required this.text});

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
