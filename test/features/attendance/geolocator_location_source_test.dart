import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:next_on/core/errors/validation_codes.dart';
import 'package:next_on/features/attendance/data/datasources/geolocator_api.dart';
import 'package:next_on/features/attendance/data/datasources/geolocator_punch_location_source.dart';
import 'package:next_on/features/attendance/domain/datasources/punch_location_source.dart';
import 'package:next_on/features/attendance/domain/entities/clock_method.dart';
import 'package:next_on/features/attendance/domain/entities/punch_request.dart';

Position _position({double accuracy = 8.0, bool isMocked = false}) => Position(
  latitude: 17.9757,
  longitude: 102.6331,
  timestamp: DateTime.utc(2026, 8, 24, 1, 15),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: isMocked,
);

/// Scripted stand-in for the plugin's statics.
class _FakeGeolocatorApi implements GeolocatorApi {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;
  Position? position;
  Object? positionError;

  int requestCalls = 0;
  LocationSettings? lastSettings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestCalls++;
    return permissionAfterRequest;
  }

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) async {
    lastSettings = settings;
    if (positionError != null) throw positionError!;
    return position ?? _position();
  }
}

void main() {
  late _FakeGeolocatorApi api;

  setUp(() => api = _FakeGeolocatorApi());

  GeolocatorPunchLocationSource source({bool reportsMock = true}) =>
      GeolocatorPunchLocationSource(api: api, reportsMockLocation: reportsMock);

  test('a granted permission yields a usable reading', () async {
    api.position = _position(accuracy: 12.5);

    final reading = await source().read(ClockMethod.gps);

    expect(reading.hasCoordinates, isTrue);
    expect(reading.latitude, 17.9757);
    expect(reading.longitude, 102.6331);
    // §7 rule 3 — accuracy always accompanies the fix.
    expect(reading.gpsAccuracy, 12.5);
    expect(reading.unavailableReason, isNull);

    const request = PunchRequest(method: ClockMethod.gps);
    expect(request.copyWith(reading: reading).validate().isSuccess, isTrue);
  });

  test(
    'reports the Android mock verdict, and stays silent elsewhere',
    () async {
      api.position = _position(isMocked: true);

      final android = await source(reportsMock: true).read(ClockMethod.gps);
      final other = await source(reportsMock: false).read(ClockMethod.gps);

      expect(android.isMockLocation, isTrue);
      expect(android.isMockConfirmed, isTrue);
      // A platform that cannot tell must not assert `false`.
      expect(other.isMockLocation, isNull);
      expect(other.isMockConfirmed, isFalse);
    },
  );

  test('a confirmed mock stops the punch before it is sent', () async {
    api.position = _position(isMocked: true);

    final reading = await source().read(ClockMethod.gps);
    final failure = const PunchRequest(
      method: ClockMethod.gps,
    ).copyWith(reading: reading).validate().failureOrNull;

    expect(failure!.message, ValidationCode.mockLocationDetected);
  });

  test('disabled location services are named as such', () async {
    api.serviceEnabled = false;

    final reading = await source().read(ClockMethod.gps);

    expect(
      reading.unavailableReason,
      LocationUnavailableReason.serviceDisabled,
    );
    expect(
      const PunchRequest(
        method: ClockMethod.gps,
      ).copyWith(reading: reading).validate().failureOrNull!.message,
      ValidationCode.locationServiceDisabled,
    );
  });

  test('an undecided permission prompts once', () async {
    api
      ..permission = LocationPermission.denied
      ..permissionAfterRequest = LocationPermission.whileInUse
      ..position = _position();

    final reading = await source().read(ClockMethod.gps);

    expect(api.requestCalls, 1);
    expect(reading.hasCoordinates, isTrue);
  });

  test('a refused prompt reports a retryable denial', () async {
    api
      ..permission = LocationPermission.denied
      ..permissionAfterRequest = LocationPermission.denied;

    final reading = await source().read(ClockMethod.gps);

    expect(
      reading.unavailableReason,
      LocationUnavailableReason.permissionDenied,
    );
  });

  test('a permanent denial is not re-prompted, and says so', () async {
    api.permission = LocationPermission.deniedForever;

    final reading = await source().read(ClockMethod.gps);

    // Re-prompting here shows nothing and looks like a dead button.
    expect(api.requestCalls, 0);
    expect(
      reading.unavailableReason,
      LocationUnavailableReason.permissionDeniedForever,
    );
    expect(
      const PunchRequest(
        method: ClockMethod.gps,
      ).copyWith(reading: reading).validate().failureOrNull!.message,
      ValidationCode.locationPermissionDeniedForever,
    );
  });

  test('a fix that never arrives is a timeout, not a crash', () async {
    api.positionError = TimeoutException('no fix');

    final reading = await source().read(ClockMethod.gps);

    expect(reading.unavailableReason, LocationUnavailableReason.timeout);
  });

  test('an unexpected plugin error degrades instead of throwing', () async {
    api.positionError = StateError('boom');

    final reading = await source().read(ClockMethod.gps);

    expect(reading.unavailableReason, LocationUnavailableReason.unknown);
  });

  test('field work never asks for a location permission', () async {
    api.permission = LocationPermission.denied;

    final reading = await source().read(ClockMethod.field);

    expect(api.requestCalls, 0);
    expect(reading, PunchLocationReading.unavailable);
    // Field work needs a reason, not a fix.
    expect(
      const PunchRequest(
        method: ClockMethod.field,
        fieldWorkReason: 'site visit',
      ).copyWith(reading: reading).validate().isSuccess,
      isTrue,
    );
  });

  test('asks for a high-accuracy fix with a bounded wait', () async {
    api.position = _position();

    await source().read(ClockMethod.gps);

    expect(api.lastSettings!.accuracy, LocationAccuracy.high);
    expect(
      api.lastSettings!.timeLimit,
      GeolocatorPunchLocationSource.fixTimeout,
    );
  });
}
