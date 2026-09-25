import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/slide_action_button.dart';
import '../../../../features/profile/domain/entities/shift_detail.dart';
import '../../../../features/profile/presentation/providers/profile_notifier.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/attendance_day.dart';
import '../providers/attendance_notifier.dart';
import 'attendance_copy.dart';
import 'attendance_session_grid.dart';
import 'punch_flow.dart';
import 'shift_session_slot.dart';

/// Home screen attendance card: a live clock, the employee's shift hours,
/// today's clock-in/out per shift segment, and the slide-to-confirm action
/// that makes the next punch.
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
    // Only read for its shift, so a slow or failing profile lookup just
    // means the hours line stays hidden and the badge falls back to generic
    // copy until it resolves — never a blocker.
    final profile = ref.watch(profileNotifierProvider).valueOrNull;
    final shiftDetails = profile?.shiftDetails ?? const <ShiftDetail>[];
    final slots = ShiftSessionSlot.build(shiftDetails, state.day.sessions);
    final shiftName = AttendanceCopy.employeeShiftName(
      locale,
      profile?.shiftName,
      profile?.shiftNameLo,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(shiftName: shiftName),
          heightBx(h: 10),
          const _LiveClock(),
          // Both hidden when the profile has no shift to show.
          if (shiftDetails.isNotEmpty) ...[
            // heightBx(h: 6),
            // _ShiftHoursLine(details: shiftDetails, locale: locale),
            // heightBx(h: 14),
            AttendanceSessionGrid(slots: slots, locale: locale),
          ],
          heightBx(h: 16),
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
          const Divider(height: 1, color: AppColors.gray200),
          heightBx(h: 14),
          _MethodsRow(methods: methods),
        ],
      ),
    );
  }
}

/// The clock icon, "current time" label, and the shift-name badge above the
/// live clock.
class _CardHeader extends StatelessWidget {
  /// The employee's assigned shift name, already resolved to the app's
  /// language — null shows [AppLocalizations.regularTimeBadge] instead.
  final String? shiftName;

  const _CardHeader({this.shiftName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = AttendanceCopy.statusBadge(l10n, shiftName: shiftName);
    final maxBadgeWidth = MediaQuery.sizeOf(context).width * 0.45;

    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.access_time,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        widthBx(),
        Expanded(
          child: customText(
            l10n.currentTimeLabel,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        widthBx(),
        // Capped so a long shift name ellipsizes instead of pushing the row
        // past the card's edge on a narrow phone.
        Container(
          constraints: BoxConstraints(maxWidth: maxBadgeWidth),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(
            color: badge.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badge.color.withValues(alpha: 0.3)),
          ),
          child: customText(
            badge.label,
            color: badge.color,
            fontSize: 12,
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
      fontWeight: FontWeight.w800,
      fontSize: 46,
      color: const Color(0xFF111827),
    );
  }
}

/// The employee's shift segments on one line — each name muted, its hours
/// bold — e.g. "ກະເຊົ້າ: **08:00 - 12:00** | ກະແລງ: **13:00 - 17:00**".
class _ShiftHoursLine extends StatelessWidget {
  final List<ShiftDetail> details;
  final Locale locale;

  const _ShiftHoursLine({required this.details, required this.locale});

  static const _muted = TextStyle(color: AppColors.gray500);
  static const _bold = TextStyle(
    color: AppColors.secondaryTxt,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    for (final detail in details) {
      final name = AttendanceCopy.shiftDetailName(locale, detail);
      final hours = AttendanceCopy.shiftDetailHours(detail);
      if (name.isEmpty && hours.isEmpty) continue;

      if (spans.isNotEmpty) {
        spans.add(const TextSpan(text: '  |  ', style: _muted));
      }
      if (name.isNotEmpty) {
        spans.add(
          TextSpan(text: hours.isEmpty ? name : '$name: ', style: _muted),
        );
      }
      if (hours.isNotEmpty) spans.add(TextSpan(text: hours, style: _bold));
    }

    // Scales down rather than truncating, so every segment stays readable.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(style: const TextStyle(fontSize: 13), children: spans),
        maxLines: 1,
      ),
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
          size: 20,
          color: AppColors.gray500,
        ),
        widthBx(w: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '${l10n.clockMethodsLabel} ',
              style: const TextStyle(color: AppColors.secondaryTxt),
              children: [
                TextSpan(
                  text: _labels(l10n).join(' • '),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
