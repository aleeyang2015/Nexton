import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/validation_codes.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../datasources/punch_location_source.dart';
import 'clock_method.dart';

/// Field names a punch [ValidationFailure] can point at, so the UI can react
/// to *which* evidence is missing without matching on message strings.
class PunchFields {
  PunchFields._();

  static const String location = 'location';
  static const String wifi = 'wifi_bssid';
  static const String reason = 'field_work_reason';
}

/// Everything one clock-in or clock-out sends (§3's request body).
///
/// Clock-in and clock-out share this shape exactly — §4 says the endpoints
/// take the same `ClockInRequest` — so the direction of the punch lives in
/// which repository method is called, not in the payload.
class PunchRequest extends Equatable implements BaseParams {
  final ClockMethod method;

  /// The device signals, already read. Held whole so a retry re-sends the
  /// same evidence rather than sampling a new position from wherever the
  /// phone has drifted to while a dialog was open.
  final PunchLocationReading reading;

  /// Required when [method] is [ClockMethod.field].
  final String? fieldWorkReason;

  /// Doubles as the early-checkout justification: re-sending a refused
  /// clock-out with this set is what clears
  /// [AttendanceRule.earlyCheckoutRequiresReason] (§4 rule 4).
  final String? notes;

  /// A selfie already uploaded elsewhere; the API takes the URL, not bytes.
  final String? photoUrl;

  /// Optional device identifier for the audit trail. Unset until the app has
  /// a source for it.
  final String? deviceId;

  const PunchRequest({
    required this.method,
    this.reading = PunchLocationReading.unavailable,
    this.fieldWorkReason,
    this.notes,
    this.photoUrl,
    this.deviceId,
  });

  /// Used by the early-checkout retry: same punch, same evidence, plus the
  /// reason the user just typed.
  PunchRequest copyWith({
    ClockMethod? method,
    PunchLocationReading? reading,
    String? fieldWorkReason,
    String? notes,
    String? photoUrl,
    String? deviceId,
  }) => PunchRequest(
    method: method ?? this.method,
    reading: reading ?? this.reading,
    fieldWorkReason: fieldWorkReason ?? this.fieldWorkReason,
    notes: notes ?? this.notes,
    photoUrl: photoUrl ?? this.photoUrl,
    deviceId: deviceId ?? this.deviceId,
  );

  /// The pre-flight rules from §7, applied in the order the backend would.
  ///
  /// Each one stops a punch that is already known to fail: a mock provider
  /// earns a 403, a `gps` punch with no fix earns `missing_coordinates`, and
  /// so on. Catching them here keeps the failure instant and the wording
  /// specific, and spares a rate-limited endpoint a pointless request.
  @override
  Result<Unit> validate() {
    // Rule 1 — refuse a spoofed position outright. The backend answers 403 for
    // this, but only after the punch is on the wire.
    if (reading.isMockConfirmed) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.mockLocationDetected,
          field: PunchFields.location,
        ),
      );
    }

    // Rule 2 — no fix, no GPS punch. The reason the source gave decides the
    // advice: turning Location Services back on, granting the permission and
    // opening Settings are three different actions.
    if (method.needsCoordinates && !reading.hasCoordinates) {
      return Result.failure(
        Failure.validation(
          message: _locationCode(reading.unavailableReason),
          field: PunchFields.location,
        ),
      );
    }

    if (method.needsWifiBssid && !reading.hasWifiBssid) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.wifiUnavailable,
          field: PunchFields.wifi,
        ),
      );
    }

    if (method.needsFieldWorkReason &&
        (fieldWorkReason == null || fieldWorkReason!.trim().isEmpty)) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.fieldReasonRequired,
          field: PunchFields.reason,
        ),
      );
    }

    return const Result.success(Unit.instance);
  }

  static String _locationCode(LocationUnavailableReason? reason) =>
      switch (reason) {
        LocationUnavailableReason.serviceDisabled =>
          ValidationCode.locationServiceDisabled,
        LocationUnavailableReason.permissionDenied =>
          ValidationCode.locationPermissionDenied,
        LocationUnavailableReason.permissionDeniedForever =>
          ValidationCode.locationPermissionDeniedForever,
        LocationUnavailableReason.timeout => ValidationCode.locationTimeout,
        LocationUnavailableReason.unknown ||
        null => ValidationCode.locationUnavailable,
      };

  @override
  List<Object?> get props => [
    method,
    reading,
    fieldWorkReason,
    notes,
    photoUrl,
    deviceId,
  ];
}
