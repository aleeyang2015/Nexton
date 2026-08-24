import 'package:equatable/equatable.dart';

import '../entities/clock_method.dart';

/// Why a reading came back empty.
///
/// A punch that cannot be sent is a dead end unless the user is told which
/// dead end it is: "turn on Location Services" and "you denied this
/// permanently, open Settings" call for different actions, and a single
/// generic "location unavailable" leaves the user with nowhere to go.
enum LocationUnavailableReason {
  /// Location Services are switched off device-wide.
  serviceDisabled,

  /// The app was refused this time; asking again is still possible.
  permissionDenied,

  /// Refused permanently (or blocked by policy). Only the system settings
  /// screen can undo it — asking again silently does nothing.
  permissionDeniedForever,

  /// No fix arrived in time. Usually indoors; worth simply retrying.
  timeout,

  /// Anything else, including a platform that cannot answer at all.
  unknown,
}

/// The location evidence a punch carries (§3's request table).
///
/// Every field is nullable and means "not available", never "zero". The
/// difference matters: sending `latitude: 0` would put the employee off the
/// coast of Africa and earn an `outside_geofence` rejection, so a missing
/// reading must stay missing and be caught before the request goes out.
class PunchLocationReading extends Equatable {
  final double? latitude;
  final double? longitude;

  /// Metres. §7 rule 3 asks for this on every GPS punch so a geofence
  /// dispute can be audited afterwards.
  final double? gpsAccuracy;

  /// `null` means the device could not be checked — which is **not** the same
  /// as "no mock detected". The request omits the flag entirely in that case
  /// rather than asserting `false`, so the backend is never told something the
  /// app doesn't know.
  final bool? isMockLocation;

  final String? wifiSsid;
  final String? wifiBssid;

  /// Set when a signal is missing and the source knows why, so the user can
  /// be told what to do about it rather than just that it failed.
  final LocationUnavailableReason? unavailableReason;

  const PunchLocationReading({
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.isMockLocation,
    this.wifiSsid,
    this.wifiBssid,
    this.unavailableReason,
  });

  /// Nothing could be read, and the source could not say why.
  static const unavailable = PunchLocationReading();

  /// Nothing could be read, for a reason worth telling the user about.
  const PunchLocationReading.unavailableBecause(
    LocationUnavailableReason reason,
  ) : this(unavailableReason: reason);

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasWifiBssid => wifiBssid != null && wifiBssid!.isNotEmpty;

  /// True only when the device positively reported a mock provider. Unknown
  /// stays false here — [isMockLocation] is where the uncertainty lives.
  bool get isMockConfirmed => isMockLocation == true;

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    gpsAccuracy,
    isMockLocation,
    wifiSsid,
    wifiBssid,
    unavailableReason,
  ];
}

/// Reads the device signals a punch needs.
///
/// This is a port, not an implementation: the domain states what evidence it
/// requires and stays free of any platform plugin. Swapping the current stub
/// for a real GPS/WiFi reader is a change to one binding in
/// `attendance_providers.dart` and nothing else.
///
/// Implementations must not throw for a signal they simply cannot obtain —
/// they return it as `null` and let the use case decide whether the punch can
/// proceed, which is what keeps "GPS is off" a friendly message instead of a
/// crash.
abstract class PunchLocationSource {
  /// Reads whatever [method] needs. Permission prompts, if any, belong here.
  Future<PunchLocationReading> read(ClockMethod method);
}
