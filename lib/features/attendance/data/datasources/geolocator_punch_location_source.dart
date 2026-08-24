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
class GeolocatorPunchLocationSource implements PunchLocationSource {
  /// How long to wait for a fix before giving up.
  ///
  /// A first fix indoors can take a while, but the user is holding a phone
  /// waiting for a slider to respond — beyond this it is kinder to fail and
  /// let them retry by the window than to hang.
  static const Duration fixTimeout = Duration(seconds: 15);

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

      return PunchLocationReading(
        latitude: position.latitude,
        longitude: position.longitude,
        // §7 rule 3 — always sent, so a disputed geofence can be audited.
        gpsAccuracy: position.accuracy,
        isMockLocation: _reportsMockLocation ? position.isMocked : null,
      );
    } on TimeoutException {
      return const PunchLocationReading.unavailableBecause(
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
