import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/slide_action_button.dart';
import '../../../../features/profile/presentation/providers/profile_notifier.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/attendance_day.dart';
import '../providers/attendance_notifier.dart';
import 'attendance_copy.dart';
import 'punch_flow.dart';

/// Home screen attendance card: a live clock, today's shift hours, and the
/// slide-to-confirm action that makes the next punch.
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
    final locale = ref.watch(localeProvider);
    final state = ref.watch(attendanceNotifierProvider);
    final day = state.day;
    // Only read for its shift, so a slow or failing profile lookup just
    // means the placeholder line and badge fall back to generic copy until
    // it resolves — never a blocker.
    final profile = ref.watch(profileNotifierProvider).valueOrNull;
    final shiftDetails = profile?.shiftDetails ?? const [];
    final shiftName = AttendanceCopy.employeeShiftName(
      locale,
      profile?.shiftName,
      profile?.shiftNameLo,
    );

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
          _CardHeader(day: day, shiftName: shiftName),
          const _LiveClock(),
          customText(
            AttendanceCopy.shiftHoursLine(
              l10n,
              locale,
              day.sessions,
              shiftDetails,
            ),
            fontSize: 14,
          ),
          heightBx(h: 20),
          SlideActionButton(
            label: state.nextAction == ClockAction.clockIn
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

/// The clock icon, "current time" label, and the shift-name/late badge above
/// the live clock.
class _CardHeader extends StatelessWidget {
  final AttendanceDay day;

  /// The employee's assigned shift name, already resolved to the app's
  /// language — null shows [AppLocalizations.regularTimeBadge] instead.
  final String? shiftName;

  const _CardHeader({required this.day, this.shiftName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = AttendanceCopy.statusBadge(l10n, day, shiftName: shiftName);

    return Row(
      children: [
        Container(
          height: 35,
          width: 35,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.access_time,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        widthBx(),
        Expanded(
          child: customText(l10n.currentTimeLabel, fontWeight: FontWeight.w700),
        ),
        widthBx(),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            color: badge.color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: customText(
            badge.label,
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A `HH:mm:ss` clock that ticks once a second, purely for display.
///
/// The tick doubles as the attendance notifier's cue to notice a day has
/// rolled over (see [AttendanceNotifier.refreshIfNewDay]) — no attendance
/// state flows through the clock itself, it just forwards the tick.
class _LiveClock extends ConsumerStatefulWidget {
  const _LiveClock();

  @override
  ConsumerState<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends ConsumerState<_LiveClock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
      ref.read(attendanceNotifierProvider.notifier).refreshIfNewDay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return customText(
      AttendanceCopy.hourMinuteSecond(_now),
      fontWeight: FontWeight.w700,
      fontSize: 30,
      color: AppColors.textPrimary,
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
        .map((method) => AttendanceCopy.methodLabel(l10n, method))
        .toList(growable: false);
  }
}
