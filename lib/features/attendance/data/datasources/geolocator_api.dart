import 'package:geolocator/geolocator.dart';

/// The slice of Geolocator's static API that
/// [GeolocatorPunchLocationSource] uses.
///
/// Geolocator exposes everything as statics, which cannot be substituted in a
/// test. Routing the four calls through this seam keeps the permission and
/// mapping logic — the part with the branches worth testing — verifiable
/// without a device.
abstract class GeolocatorApi {
  const factory GeolocatorApi() = _PlatformGeolocatorApi;

  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  /// Shows the system prompt. A no-op that returns the current answer when
  /// the permission was already decided permanently.
  Future<LocationPermission> requestPermission();

  Future<Position> getCurrentPosition(LocationSettings settings);
}

/// Delegates to the real plugin.
class _PlatformGeolocatorApi implements GeolocatorApi {
  const _PlatformGeolocatorApi();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) =>
      Geolocator.getCurrentPosition(locationSettings: settings);
}
