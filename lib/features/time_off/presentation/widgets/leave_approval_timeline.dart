import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_approval_step.dart';
import '../../domain/entities/leave_status.dart';
import 'leave_copy.dart';

enum _DotVisual { done, current, rejected, upcoming, cancelled }

typedef _Node = ({String label, _DotVisual visual, String? time});

/// The submit → step-by-step approval progress tracker shown on each history
/// / detail card, driven by the request's real `steps[]`
/// (leave-request-flutter.md §3.6).
///
/// A leading "Submitted" node is always complete; then one node per approval
/// step, coloured by that step's own status. A rejected step shows the ✕ and
/// every later step stays upcoming. An approved or rejected step shows when
/// it was decided under its name.
///
/// A cancelled request ends in a "Cancelled" node. Cancelling changes only
/// the request's status, so a step that was waiting still says `pending` on
/// the server; here it is drawn as not reached, since nobody is going to
/// decide it.
class LeaveApprovalTimeline extends StatelessWidget {
  final List<LeaveApprovalStep> steps;

  /// The request's own status. Null draws the steps as they are.
  final LeaveStatus? requestStatus;

  const LeaveApprovalTimeline({
    super.key,
    required this.steps,
    this.requestStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final ordered = [...steps]..sort((a, b) => a.stepNo.compareTo(b.stepNo));
    final cancelled = requestStatus == LeaveStatus.cancelled;
    final nodes = <_Node>[
      (label: l10n.leaveStepSubmitted, visual: _DotVisual.done, time: null),
      for (final step in ordered)
        (
          label: LeaveCopy.stepRoleLabel(l10n, step.role),
          visual: _visualFor(step.status, cancelled: cancelled),
          time: step.isDecided && step.decidedAt != null
              ? LeaveCopy.stepTime(l10n, step.decidedAt!)
              : null,
        ),
      if (cancelled)
        (
          label: l10n.leaveStatusCancelled,
          visual: _DotVisual.cancelled,
          time: null,
        ),
    ];

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < nodes.length; i++) ...[
              _Dot(index: i, visual: nodes[i].visual),
              if (i < nodes.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: nodes[i].visual == _DotVisual.done
                        ? AppColors.primary
                        : AppColors.gray300,
                  ),
                ),
            ],
          ],
        ),
        heightBx(h: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < nodes.length; i++)
              Expanded(
                child: _Label(
                  text: nodes[i].label,
                  time: nodes[i].time,
                  visual: nodes[i].visual,
                  align: i == 0
                      ? TextAlign.left
                      : (i == nodes.length - 1
                            ? TextAlign.right
                            : TextAlign.center),
                ),
              ),
          ],
        ),
      ],
    );
  }

  _DotVisual _visualFor(LeaveStepStatus status, {required bool cancelled}) =>
      switch (status) {
        LeaveStepStatus.approved => _DotVisual.done,
        // On a cancelled request nobody is deciding this step any more.
        LeaveStepStatus.pending =>
          cancelled ? _DotVisual.upcoming : _DotVisual.current,
        LeaveStepStatus.rejected => _DotVisual.rejected,
        LeaveStepStatus.waiting => _DotVisual.upcoming,
      };
}

class _Dot extends StatelessWidget {
  final int index;
  final _DotVisual visual;

  const _Dot({required this.index, required this.visual});

  @override
  Widget build(BuildContext context) {
    const size = 32.0;

    if (visual == _DotVisual.upcoming) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: customText(
          '${index + 1}',
          color: AppColors.gray500,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      );
    }

    final (color, icon) = switch (visual) {
      _DotVisual.done => (AppColors.primary, Icons.check),
      _DotVisual.current => (AppColors.primary, Icons.more_horiz),
      _DotVisual.cancelled => (AppColors.gray500, Icons.block),
      _DotVisual.rejected ||
      _DotVisual.upcoming => (AppColors.danger, Icons.close),
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  /// When the step was decided, shown under [text]; null for no line.
  final String? time;
  final _DotVisual visual;
  final TextAlign align;

  const _Label({
    required this.text,
    required this.time,
    required this.visual,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (visual) {
      _DotVisual.done || _DotVisual.current => AppColors.primary,
      _DotVisual.rejected => AppColors.danger,
      _DotVisual.upcoming || _DotVisual.cancelled => AppColors.gray500,
    };
    final decidedAt = time;

    return Column(
      crossAxisAlignment: switch (align) {
        TextAlign.left => CrossAxisAlignment.start,
        TextAlign.right => CrossAxisAlignment.end,
        _ => CrossAxisAlignment.center,
      },
      children: [
        Text(
          text,
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (decidedAt != null)
          Text(
            decidedAt,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.subTitle),
          ),
      ],
    );
  }
}
