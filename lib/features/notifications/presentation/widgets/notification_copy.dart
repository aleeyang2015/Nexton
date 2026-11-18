import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/presentation/widgets/attendance_copy.dart';
import '../../../time_off/presentation/widgets/leave_copy.dart';
import '../../domain/push_route.dart';

/// The bell list's words and icons for a row's kind (#54): the same words
/// as the screens the rows open.
abstract final class NotificationCopy {
  static String kindLabel(AppLocalizations l10n, String type) => switch (type) {
    PushTypes.leaveRequest => l10n.leaveMenu,
    PushTypes.correction => l10n.forgotClockInMenu,
    PushTypes.offsite => l10n.offsiteTitle,
    PushTypes.otAnnouncement || PushTypes.otRequest => l10n.otMenu,
    _ => l10n.notifications,
  };

  static IconData kindIcon(String type) => switch (type) {
    PushTypes.leaveRequest => Icons.event_note_outlined,
    PushTypes.correction => Icons.edit_calendar_outlined,
    PushTypes.offsite => Icons.location_off_outlined,
    PushTypes.otAnnouncement || PushTypes.otRequest => Icons.more_time,
    _ => Icons.notifications_outlined,
  };

  /// "18 ພ.ຈ. 2026 14:05" / "18 Nov 2026 14:05", on the phone's clock.
  static String when(AppLocalizations l10n, DateTime at) {
    final local = at.toLocal();
    return '${LeaveCopy.shortDate(l10n, local)} '
        '${AttendanceCopy.hourMinute(local)}';
  }
}
