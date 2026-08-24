import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/slide_action_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/attendance_day.dart';
import '../providers/attendance_notifier.dart';
import '../providers/attendance_state.dart';
import 'attendance_copy.dart';
import 'punch_flow.dart';

/// Home screen attendance card: today's status, the punches made so far, and
/// the slide-to-confirm action that makes the next one.
///
/// Everything it shows comes from [attendanceNotifierProvider]; the widget
/// holds no attendance logic and makes no decisions about what a punch meant
/// — it forwards the gesture to [PunchFlow] and renders the state.
class AttendanceStatusCard extends ConsumerWidget {
  /// The methods this employer accepts, shown as a hint under the divider.
  ///
  /// Static for now: the API has no endpoint that reports a site's accepted
  /// methods, and the slide action always punches with
  /// [AttendanceNotifier.defaultMethod].
  static const List<String> methods = ['gps', 'wifi', 'biometric', 'field'];

  const AttendanceStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(attendanceNotifierProvider);
    final day = state.day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusLine(state: state),
          heightBx(h: 16),
          Row(
            children: [
              Expanded(
                child: _TimeColumn(
                  label: l10n.timeIn,
                  time: AttendanceCopy.clockTime(l10n, day.firstClockIn),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gray400),
              Expanded(
                child: _TimeColumn(
                  label: l10n.timeOut,
                  time: AttendanceCopy.clockTime(l10n, day.lastClockOut),
                ),
              ),
            ],
          ),
          heightBx(h: 20),
          SlideActionButton(
            label: day.nextAction == ClockAction.clockIn
                ? l10n.slideToClockIn
                : l10n.slideToClockOut,
            // Inert while a punch is in flight, while a 429 cooldown runs,
            // and until today's record says which punch is owed.
            enabled: state.canPunch && !state.isLoadingToday,
            onComplete: () => PunchFlow.start(context, ref),
            resetAfterComplete: true,
          ),
          heightBx(h: 16),
          const Divider(height: 1, color: AppColors.border),
          heightBx(h: 12),
          _MethodsRow(methods: methods),
        ],
      ),
    );
  }
}

/// The coloured dot and the line beside it: whether a session is open, which
/// one, and whether today's record could be read at all.
class _StatusLine extends ConsumerWidget {
  final AttendanceState state;

  const _StatusLine({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final failedToLoad = state.today.hasError;

    final color = failedToLoad
        ? AppColors.danger
        : (state.isClockedIn ? AppColors.success : AppColors.warning);

    final label = failedToLoad
        ? l10n.attendanceLoadFailed
        : (state.isClockedIn ? l10n.checkedInStatus : l10n.notCheckedIn);

    // Which block of a split shift is open, when the backend labels them.
    final sessionLabel = state.day.openSession?.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            widthBx(w: 8),
            Expanded(
              child: customText(
                label,
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (state.isLoadingToday)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gray400,
                ),
              )
            else if (failedToLoad)
              InkWell(
                onTap: () =>
                    ref.read(attendanceNotifierProvider.notifier).loadToday(),
                child: customText(
                  l10n.retry,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        if (sessionLabel != null) ...[
          heightBx(h: 4),
          customText(sessionLabel, color: AppColors.secondary, fontSize: 13),
        ],
      ],
    );
  }
}

class _MethodsRow extends StatelessWidget {
  final List<String> methods;

  const _MethodsRow({required this.methods});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 18,
          color: AppColors.gray500,
        ),
        widthBx(w: 8),
        Expanded(
          child: customText(
            l10n.clockMethodsLabel(_labels(l10n).join(' · ')),
            color: AppColors.subTitle,
            fontSize: 12,
          ),
        ),
        const Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: AppColors.gray500,
        ),
      ],
    );
  }

  List<String> _labels(AppLocalizations l10n) {
    return methods
        .map((method) {
          switch (method) {
            case 'gps':
              return l10n.methodGps;
            case 'wifi':
              return l10n.methodWifi;
            case 'biometric':
              return l10n.methodBiometric;
            case 'field':
              return l10n.methodField;
            default:
              return method;
          }
        })
        .toList(growable: false);
  }
}

class _TimeColumn extends StatelessWidget {
  final String label;
  final String time;

  const _TimeColumn({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        customText(label, color: AppColors.subTitle, fontSize: 13),
        heightBx(h: 4),
        customText(time, fontWeight: FontWeight.w700, fontSize: 30),
      ],
    );
  }
}
