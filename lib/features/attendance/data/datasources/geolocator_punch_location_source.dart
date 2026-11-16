import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/datasources/punch_location_source.dart';
import '../../domain/entities/clock_method.dart';
import 'geolocator_api.dart';

/// Reads a real position for a GPS punch, asking for the permission it needs.
///
/// Honours the port's contract to the letter: a signal it cannot obtain comes
/// back as an empty reading with a [LocationUnavailableReason], never as a
/// thrown error and never as an invented coordinate. `PunchRequest.validate`
/// then turns that reason into the right advice, so "Location Services are
/// off" and "you denied this permanently" reach the user as different
/// messages.
///
/// When no fresh fix arrives in time it answers from the platform's cached
/// one, provided that fix is younger than [maxCachedFixAge]. Indoors this is
/// the difference between a punch and a dead end: a device without Google
/// Play Services falls back to `LocationManager`, which serves any accuracy
/// above the lowest from the GPS provider alone — so under a roof the fresh
/// fix simply never comes, however long it is given.
class GeolocatorPunchLocationSource implements PunchLocationSource {
  /// How long to wait for a fresh fix before falling back to the cache.
  ///
  /// A first fix indoors can take a while, but the user is holding a phone
  /// waiting for a slider to respond — beyond this it is kinder to answer
  /// from [maxCachedFixAge] than to hang.
  static const Duration fixTimeout = Duration(seconds: 15);

  /// How stale a cached fix may be and still stand in for a fresh one.
  ///
  /// The punch is a geofence check, so a position from across town would be
  /// a false alibi. Two minutes is short enough that the employee cannot
  /// have left the site and long enough to cover the walk indoors that lost
  /// the satellites in the first place.
  static const Duration maxCachedFixAge = Duration(minutes: 2);

  final GeolocatorApi _api;

  /// Whether this platform can report a mock provider at all.
  ///
  /// Android can; iOS cannot, and geolocator reports a flat `false` there. A
  /// `false` we did not verify would be a lie to the backend, so on every
  /// other platform the verdict stays `null` — "unknown" — and the request
  /// omits the field entirely.
  final bool _reportsMockLocation;

  GeolocatorPunchLocationSource({
    GeolocatorApi api = const GeolocatorApi(),
    bool? reportsMockLocation,
  }) : _api = api,
       _reportsMockLocation =
           reportsMockLocation ??
           defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<PunchLocationReading> read(ClockMethod method) async {
    // Only the GPS punch needs a fix. Sampling a position for a `field` punch
    // would prompt for a permission the punch never uses.
    if (!method.needsCoordinates) return PunchLocationReading.unavailable;

    if (!await _api.isLocationServiceEnabled()) {
      return const PunchLocationReading.unavailableBecause(
        LocationUnavailableReason.serviceDisabled,
      );
    }

    final permission = await _resolvePermission();
    if (permission != null) {
      return PunchLocationReading.unavailableBecause(permission);
    }

    try {
      final position = await _api.getCurrentPosition(
        const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: fixTimeout,
        ),
      );

      return _readingOf(position);
    } on TimeoutException {
      // No satellites in time. A recent cached fix is a truthful answer to
      // "where is this device"; an older one is not, so it stays a timeout.
      return await _cachedReading() ??
          const PunchLocationReading.unavailableBecause(
            LocationUnavailableReason.timeout,
          );
    } on LocationServiceDisabledException {
      // Services can be switched off between the check above and the fix.
      return const PunchLocationReading.unavailableBecause(
        LocationUnavailableReason.serviceDisabled,
      );
    } on PermissionDeniedException {
      return const PunchLocationReading.unavailableBecause(
        LocationUnavailableReason.permissionDenied,
      );
    } catch (_) {
      return const PunchLocationReading.unavailableBecause(
        LocationUnavailableReason.unknown,
      );
    }
  }

  /// The platform's last fix, if it is recent enough to still describe where
  /// the device is now. Null when there is none, when it is too old, or when
  /// the lookup itself fails — every one of which leaves the timeout standing.
  Future<PunchLocationReading?> _cachedReading() async {
    final Position? position;
    try {
      position = await _api.getLastKnownPosition();
    } catch (_) {
      return null;
    }
    if (position == null) return null;

    final age = DateTime.now().difference(position.timestamp.toLocal());
    // A timestamp in the future means a clock that cannot be trusted to age
    // anything, so the fix is not used.
    if (age.isNegative || age > maxCachedFixAge) return null;

    return _readingOf(position);
  }

  PunchLocationReading _readingOf(Position position) => PunchLocationReading(
    latitude: position.latitude,
    longitude: position.longitude,
    // §7 rule 3 — always sent, so a disputed geofence can be audited.
    gpsAccuracy: position.accuracy,
    isMockLocation: _reportsMockLocation ? position.isMocked : null,
  );

  /// Returns null when the app may read a position, or the reason it may not.
  ///
  /// The prompt is only raised for a permission that has not been decided —
  /// requesting one that was denied forever returns immediately without
  /// showing anything, which would look to the user like a button that does
  /// nothing.
  Future<LocationUnavailableReason?> _resolvePermission() async {
    var permission = await _api.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _api.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => null,
      LocationPermission.deniedForever =>
        LocationUnavailableReason.permissionDeniedForever,
      LocationPermission.denied || LocationPermission.unableToDetermine =>
        LocationUnavailableReason.permissionDenied,
    };
  }
}
