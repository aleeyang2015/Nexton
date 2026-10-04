import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/datasources/punch_location_source.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/offsite_method.dart';
import '../../domain/entities/offsite_outcome.dart';
import 'attendance_copy.dart';

/// Turns the off-site scan request's domain values into the words its form
/// shows. Pure functions, no widgets — so the mapping is testable on its own
/// and the widgets stay small.
class OffsiteCopy {
  OffsiteCopy._();

  static String methodLabel(AppLocalizations l10n, OffsiteMethod method) =>
      switch (method) {
        OffsiteMethod.checkIn => l10n.offsiteMethodCheckIn,
        OffsiteMethod.checkOut => l10n.offsiteMethodCheckOut,
      };

  static IconData methodIcon(OffsiteMethod method) => switch (method) {
    OffsiteMethod.checkIn => Icons.login,
    OffsiteMethod.checkOut => Icons.logout,
  };

  /// The approval card's direction chip — green going in, red coming out, the
  /// same reading the correction card's type chip gives.
  static ({String label, IconData icon, Color color}) methodChip(
    AppLocalizations l10n,
    OffsiteMethod method,
  ) => (
    label: methodLabel(l10n, method),
    icon: methodIcon(method),
    color: method == OffsiteMethod.checkIn
        ? AppColors.attendancePresent
        : AppColors.danger,
  );

  /// "02/10/2026" — the working day the scan belongs to, or its timestamp's day
  /// when the backend sent no `scan_date`.
  static String? scanDate(OffsiteRequestDetail request) {
    final date = request.scanDate ?? request.scanTimestamp;
    if (date == null) return null;
    return '${_two(date.day)}/${_two(date.month)}/${date.year}';
  }

  /// "08:15" — when the server stamped the scan, or null when it sent none.
  static String? scanTime(OffsiteRequestDetail request) {
    final at = request.scanTimestamp;
    return at == null ? null : AttendanceCopy.hourMinute(at);
  }

  /// The position as the card's coordinate line, or null when the request
  /// carries none (§11.4 allows it).
  static String? position(OffsiteRequestDetail request) {
    if (!request.hasCoordinates) return null;
    return '${request.latitude!.toStringAsFixed(5)}, '
        '${request.longitude!.toStringAsFixed(5)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// The position as the five-decimal pair the card shows (roughly a metre of
  /// precision — enough to recognise a place, short enough to read).
  static String? coordinates(PunchLocationReading? reading) {
    final lat = reading?.latitude;
    final lng = reading?.longitude;
    if (lat == null || lng == null) return null;
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  /// How good the fix is, when the device said. Rounded to whole metres —
  /// decimals of GPS accuracy are noise.
  static String? accuracy(
    AppLocalizations l10n,
    PunchLocationReading? reading,
  ) {
    final metres = reading?.gpsAccuracy;
    if (metres == null) return null;
    return l10n.offsiteAccuracy(metres.round());
  }

  /// What to tell the employee about a request the backend accepted.
  ///
  /// The two answers §3 can give mean different things to them: with
  /// `can_work_offsite` the punch is already recorded, without it the request
  /// is only filed and HR still has to approve it.
  static String filed(AppLocalizations l10n, OffsiteSubmission submission) =>
      submission.autoApproved
      ? l10n.offsiteSubmitApproved
      : l10n.offsiteSubmitPending;

  /// What to tell them about a scan a session rule refused.
  ///
  /// The backend's own wording is preferred wherever it exists — §3's messages
  /// name the session and the time ("clocking in opens at 07:45") — with the
  /// app's copy as the fallback. Shared with the punch card, which is refused
  /// by the same rules.
  static String blocked(AppLocalizations l10n, OffsiteBlocked blocked) {
    final serverMessage = blocked.message.trim();
    if (serverMessage.isNotEmpty) return serverMessage;

    return AttendanceCopy.ruleFallback(l10n, blocked.rule, blocked.details);
  }
}
