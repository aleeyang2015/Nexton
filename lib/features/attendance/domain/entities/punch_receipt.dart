import 'package:equatable/equatable.dart';

/// What the location check concluded (§3).
///
/// The spec's loudest warning: **HTTP 200 does not mean the punch was
/// accepted**. The body's `status` is the real answer, and two of its three
/// values still need a warning in front of the user.
enum PunchVerification {
  /// Inside the geofence / on a known AP. The punch counts.
  verified('verified'),

  /// Stored, but the location check failed — the user must be told, because
  /// nothing about the HTTP status hints at it.
  rejected('rejected'),

  /// The check could not run (backend hiccup). Stored for later resolution.
  pending('pending');

  const PunchVerification(this.wireValue);

  final String wireValue;

  /// Unknown values are treated as [pending] rather than [verified]: never
  /// tell someone their punch counted on the strength of a value we don't
  /// recognise.
  static PunchVerification fromWire(String? value) {
    for (final status in PunchVerification.values) {
      if (status.wireValue == value) return status;
    }
    return PunchVerification.pending;
  }
}

/// Why a punch was [PunchVerification.rejected] (§3). Kept as a raw string
/// too, so a reason the backend adds later still reaches the user.
enum PunchRejectionReason {
  outsideGeofence('outside_geofence'),
  missingCoordinates('missing_coordinates'),
  unknownWifi('unknown_wifi'),
  missingBssid('missing_bssid');

  const PunchRejectionReason(this.wireValue);

  final String wireValue;

  static PunchRejectionReason? fromWire(String? value) {
    for (final reason in PunchRejectionReason.values) {
      if (reason.wireValue == value) return reason;
    }
    return null;
  }
}

/// A punch the backend stored, whatever it concluded about the location.
///
/// `isLate` / `lateMinutes` / `attendanceStatus` are clock-in only, and the
/// session fields only exist once a shift is configured — hence the nullables.
class PunchReceipt extends Equatable {
  final String checkinId;
  final PunchVerification verification;

  /// The backend's own wording. Shown verbatim, per §5's rule that message
  /// text is display-only and `code` is what logic keys on.
  final String message;

  final PunchRejectionReason? rejectionReason;

  /// The raw `rejection_reason`, preserved when it isn't one of the four
  /// documented values.
  final String? rawRejectionReason;

  final String? locationName;
  final double? distanceFromCenter;

  /// Sent as UTC (RFC3339); already converted to local time here so no
  /// display code has to remember to (§7 rule 9).
  final DateTime timestamp;

  final bool? isLate;
  final int? lateMinutes;
  final String? attendanceStatus;
  final int? sessionOrder;
  final String? sessionLabel;

  const PunchReceipt({
    required this.checkinId,
    required this.verification,
    required this.message,
    required this.timestamp,
    this.rejectionReason,
    this.rawRejectionReason,
    this.locationName,
    this.distanceFromCenter,
    this.isLate,
    this.lateMinutes,
    this.attendanceStatus,
    this.sessionOrder,
    this.sessionLabel,
  });

  /// The punch counted. Anything else needs a warning, not a success message.
  bool get isVerified => verification == PunchVerification.verified;

  /// Stored but not confirmed — show the amber path (§7 rule 5).
  bool get needsWarning => !isVerified;

  @override
  List<Object?> get props => [
    checkinId,
    verification,
    message,
    rejectionReason,
    rawRejectionReason,
    locationName,
    distanceFromCenter,
    timestamp,
    isLate,
    lateMinutes,
    attendanceStatus,
    sessionOrder,
    sessionLabel,
  ];
}
