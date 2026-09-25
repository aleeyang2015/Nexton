import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'attendance_copy.dart';
import 'shift_session_slot.dart';

/// The card's grid of shift tiles — one per segment of the employee's shift,
/// two to a row, each showing today's clock-in and clock-out for it.
class AttendanceSessionGrid extends StatelessWidget {
  final List<ShiftSessionSlot> slots;
  final Locale locale;

  const AttendanceSessionGrid({
    super.key,
    required this.slots,
    required this.locale,
  });

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var row = 0; row < slots.length; row += 2) ...[
            if (row > 0) const SizedBox(height: _gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _tile(row)),
                  if (row + 1 < slots.length) ...[
                    const SizedBox(width: _gap),
                    Expanded(child: _tile(row + 1)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(int index) => _SessionTile(
    slot: slots[index],
    locale: locale,
    // The first segment of the day is marked orange, later ones blue.
    dotColor: index == 0 ? AppColors.attendanceLate : AppColors.primary,
  );
}

class _SessionTile extends StatelessWidget {
  final ShiftSessionSlot slot;
  final Locale locale;
  final Color dotColor;

  const _SessionTile({
    required this.slot,
    required this.locale,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clockIn = slot.clockIn;
    final clockOut = slot.clockOut;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _TileHeader(
            name: AttendanceCopy.shiftDetailName(locale, slot.detail),
            hours: AttendanceCopy.shiftDetailHours(
              slot.detail,
            ).replaceAll(' ', ''),
            dotColor: dotColor,
          ),
          const Divider(height: 14, color: AppColors.gray200),
          Row(
            children: [
              Expanded(
                child: clockIn == null
                    ? _TimeBox.empty(label: l10n.sessionClockInLabel)
                    : _TimeBox.punchedIn(
                        label: l10n.sessionClockInLabel,
                        time: AttendanceCopy.hourMinute(clockIn),
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: clockOut != null
                    ? _TimeBox.punchedOut(
                        label: l10n.sessionClockOutLabel,
                        time: AttendanceCopy.hourMinute(clockOut),
                      )
                    : slot.isAwaitingClockOut
                    ? _TimeBox.awaiting(
                        label: l10n.sessionClockOutLabel,
                        note: l10n.sessionAwaitingClockOut,
                      )
                    : _TimeBox.empty(label: l10n.sessionClockOutLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The dot, the segment's name, and its scheduled hours.
class _TileHeader extends StatelessWidget {
  final String name;
  final String hours;
  final Color dotColor;

  const _TileHeader({
    required this.name,
    required this.hours,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        widthBx(w: 6),
        // Name and hours share the row: the name ellipsizes, the hours
        // shrink, so neither pushes past the tile on a narrow phone.
        Flexible(
          child: customText(
            name,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (hours.isNotEmpty) ...[
          widthBx(w: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: customText(hours, fontSize: 11, color: AppColors.gray500),
            ),
          ),
        ],
      ],
    );
  }
}

/// One clock-in or clock-out box. Its tint says what state the punch is in:
/// green for a clock-in, grey for a clock-out or nothing yet, blue for a
/// clock-out still owed.
class _TimeBox extends StatelessWidget {
  final String label;
  final String time;
  final String? note;
  final Color background;
  final Color border;
  final Color labelColor;
  final Color timeColor;

  static const _placeholder = '--:--';

  const _TimeBox._({
    required this.label,
    required this.time,
    required this.background,
    required this.border,
    required this.labelColor,
    required this.timeColor,
    this.note,
  });

  _TimeBox.punchedIn({required String label, required String time})
    : this._(
        label: label,
        time: time,
        background: AppColors.attendancePresent.withValues(alpha: 0.08),
        border: AppColors.attendancePresent.withValues(alpha: 0.3),
        labelColor: AppColors.secondaryTxt,
        timeColor: const Color(0xFF2E8B45),
      );

  const _TimeBox.punchedOut({required String label, required String time})
    : this._(
        label: label,
        time: time,
        background: const Color(0xFFF7F8FA),
        border: AppColors.gray200,
        labelColor: AppColors.secondaryTxt,
        timeColor: AppColors.textPrimary,
      );

  _TimeBox.awaiting({required String label, required String note})
    : this._(
        label: label,
        time: _placeholder,
        note: note,
        background: AppColors.primaryTint,
        border: AppColors.primary.withValues(alpha: 0.25),
        labelColor: AppColors.primary,
        timeColor: AppColors.primary,
      );

  const _TimeBox.empty({required String label})
    : this._(
        label: label,
        time: _placeholder,
        background: const Color(0xFFF7F8FA),
        border: AppColors.gray200,
        labelColor: AppColors.secondaryTxt,
        timeColor: AppColors.gray500,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 6, 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(label, fontSize: 11, color: labelColor),
          // Scales down rather than truncating, so a narrow phone still
          // shows the whole time.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: time,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: timeColor,
                ),
                children: [
                  if (note != null)
                    TextSpan(
                      text: ' $note',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
