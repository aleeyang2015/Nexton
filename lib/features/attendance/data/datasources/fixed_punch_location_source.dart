import '../../domain/datasources/punch_location_source.dart';
import '../../domain/entities/clock_method.dart';

/// A [PunchLocationSource] that answers every GPS punch with one fixed
/// coordinate instead of reading the device.
///
/// Why this exists: an emulator has no real GPS receiver. The position it is
/// fed through the tooling is reported back as a *mock provider*, which
/// `PunchRequest.validate` rejects outright (§7 rule 1) before the punch ever
/// leaves the app — so clock-in / clock-out cannot be exercised on an emulator
/// at all. This source returns a real-looking fix with the mock flag cleared,
/// so the whole flow can be run end to end during local development.
///
/// It is a development aid only: `attendance_providers.dart` wires it in for
/// debug builds and keeps [GeolocatorPunchLocationSource] for release builds.
///
/// The coordinate defaults to the value the developer supplied, and can be
/// pointed elsewhere per build without a code change:
///
/// ```
/// flutter run \
///   --dart-define=NEXTON_DEBUG_PUNCH_LAT=18.5049 \
///   --dart-define=NEXTON_DEBUG_PUNCH_LNG=102.4180
/// ```
class FixedPunchLocationSource implements PunchLocationSource {
  /// Latitude sent for every GPS punch.
  final double latitude;

  /// Longitude sent for every GPS punch.
  final double longitude;

  /// Metres of reported accuracy. §7 rule 3 wants this on every GPS punch, so
  /// a plausible small value is sent rather than nothing.
  final double gpsAccuracy;

  const FixedPunchLocationSource({
    // Vientiane, Laos — the emulator location the developer is testing with.
    this.latitude = 18.5049,
    this.longitude = 102.4180,
    this.gpsAccuracy = 8,
  });

  /// Builds the source from `--dart-define` overrides when present, falling
  /// back to the baked-in coordinate. `double.fromEnvironment` is not const on
  /// this SDK, so the read is done here rather than in the const constructor.
  factory FixedPunchLocationSource.fromEnvironment() {
    const lat = String.fromEnvironment('NEXTON_DEBUG_PUNCH_LAT');
    const lng = String.fromEnvironment('NEXTON_DEBUG_PUNCH_LNG');
    const fallback = FixedPunchLocationSource();
    return FixedPunchLocationSource(
      latitude: double.tryParse(lat) ?? fallback.latitude,
      longitude: double.tryParse(lng) ?? fallback.longitude,
    );
  }

  @override
  Future<PunchLocationReading> read(ClockMethod method) async {
    // Match the real source: only a GPS punch needs coordinates.
    if (!method.needsCoordinates) return PunchLocationReading.unavailable;

    return PunchLocationReading(
      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,
      // Explicitly *not* a mock provider — clearing this is the entire reason
      // this source exists.
      isMockLocation: false,
    );
  }
}
