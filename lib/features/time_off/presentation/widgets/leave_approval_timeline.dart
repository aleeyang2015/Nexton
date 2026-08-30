import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_approval_step.dart';
import 'leave_copy.dart';

enum _DotVisual { done, current, rejected, upcoming }

/// The submit → step-by-step approval progress tracker shown on each history
/// / detail card, driven by the request's real `steps[]`
/// (leave-request-flutter.md §3.6).
///
/// A leading "Submitted" node is always complete; then one node per approval
/// step, coloured by that step's own status. A rejected step shows the ✕ and
/// every later step stays upcoming.
class LeaveApprovalTimeline extends StatelessWidget {
  final List<LeaveApprovalStep> steps;

  const LeaveApprovalTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final ordered = [...steps]..sort((a, b) => a.stepNo.compareTo(b.stepNo));
    final nodes = <({String label, _DotVisual visual})>[
      (label: l10n.leaveStepSubmitted, visual: _DotVisual.done),
      for (final step in ordered)
        (
          label: LeaveCopy.stepRoleLabel(l10n, step.role),
          visual: _visualFor(step.status),
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
          children: [
            for (var i = 0; i < nodes.length; i++)
              Expanded(
                child: _Label(
                  text: nodes[i].label,
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

  _DotVisual _visualFor(LeaveStepStatus status) => switch (status) {
    LeaveStepStatus.approved => _DotVisual.done,
    LeaveStepStatus.pending => _DotVisual.current,
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
  final _DotVisual visual;
  final TextAlign align;

  const _Label({required this.text, required this.visual, required this.align});

  @override
  Widget build(BuildContext context) {
    final color = switch (visual) {
      _DotVisual.done || _DotVisual.current => AppColors.primary,
      _DotVisual.rejected => AppColors.danger,
      _DotVisual.upcoming => AppColors.gray500,
    };

    return Text(
      text,
      textAlign: align,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    );
  }
}
