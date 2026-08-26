import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_status.dart';

enum _StepVisual { done, current, rejected, upcoming }

/// The submit → manager review → HR approval progress tracker shown on each
/// history card.
///
/// A rejection is assumed to always happen at the manager-review step — the
/// only rejection case the product has specified so far — so HR approval
/// stays "upcoming" (never reached) whenever a request is rejected.
class LeaveApprovalTimeline extends StatelessWidget {
  final LeaveStatus status;

  const LeaveApprovalTimeline({super.key, required this.status});

  List<_StepVisual> get _steps => switch (status) {
    LeaveStatus.pending => const [
      _StepVisual.done,
      _StepVisual.current,
      _StepVisual.upcoming,
    ],
    LeaveStatus.approved => const [
      _StepVisual.done,
      _StepVisual.done,
      _StepVisual.done,
    ],
    LeaveStatus.rejected => const [
      _StepVisual.done,
      _StepVisual.rejected,
      _StepVisual.upcoming,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = _steps;
    final labels = [
      l10n.leaveStepSubmitted,
      switch (steps[1]) {
        _StepVisual.rejected => l10n.leaveStatusRejected,
        _StepVisual.current => l10n.leaveStepManagerWaiting,
        _ => l10n.leaveStepManagerReview,
      },
      l10n.leaveStepHrApproval,
    ];

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _StepDot(index: i, state: steps[i]),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: steps[i] == _StepVisual.done
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
            SizedBox(
              width: 72,
              child: _StepLabel(text: labels[0], state: steps[0], align: TextAlign.left),
            ),
            Expanded(
              child: _StepLabel(text: labels[1], state: steps[1], align: TextAlign.center),
            ),
            SizedBox(
              width: 72,
              child: _StepLabel(text: labels[2], state: steps[2], align: TextAlign.right),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final _StepVisual state;

  const _StepDot({required this.index, required this.state});

  @override
  Widget build(BuildContext context) {
    const size = 32.0;

    if (state == _StepVisual.upcoming) {
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

    final (color, icon) = switch (state) {
      _StepVisual.done => (AppColors.primary, Icons.check),
      _StepVisual.current => (AppColors.primary, Icons.more_horiz),
      _StepVisual.rejected || _StepVisual.upcoming => (AppColors.danger, Icons.close),
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

class _StepLabel extends StatelessWidget {
  final String text;
  final _StepVisual state;
  final TextAlign align;

  const _StepLabel({required this.text, required this.state, required this.align});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepVisual.done || _StepVisual.current => AppColors.primary,
      _StepVisual.rejected => AppColors.danger,
      _StepVisual.upcoming => AppColors.gray500,
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
