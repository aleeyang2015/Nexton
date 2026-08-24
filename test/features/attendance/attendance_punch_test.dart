import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/errors/validation_codes.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/attendance_failure_x.dart';
import 'package:next_on/features/attendance/domain/datasources/punch_location_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/clock_method.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/punch_receipt.dart';
import 'package:next_on/features/attendance/domain/entities/punch_request.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_notifier.dart';

import '../../support/attendance_test_doubles.dart';

PunchReceipt _receipt({
  PunchVerification verification = PunchVerification.verified,
}) => PunchReceipt(
  checkinId: 'id',
  verification: verification,
  message: 'ok',
  timestamp: DateTime(2026, 8, 24, 8, 5),
);

AttendanceDay _openDay() => AttendanceDay(
  sessions: [
    AttendanceSession(label: '08:00–12:00', clockIn: DateTime(2026, 8, 24, 8)),
  ],
);

void main() {
  group('PunchRequest.validate', () {
    test('a GPS punch with no fix is refused before it is sent', () {
      const request = PunchRequest(
        method: ClockMethod.gps,
        reading: PunchLocationReading.unavailable,
      );

      final failure = request.validate().failureOrNull;

      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, ValidationCode.locationUnavailable);
      expect((failure as ValidationFailure).field, PunchFields.location);
    });

    test('a confirmed mock location is refused outright', () {
      const request = PunchRequest(
        method: ClockMethod.gps,
        reading: PunchLocationReading(
          latitude: 1,
          longitude: 2,
          isMockLocation: true,
        ),
      );

      expect(
        request.validate().failureOrNull!.message,
        ValidationCode.mockLocationDetected,
      );
    });

    test('an unknown mock verdict does not block a punch', () {
      const request = PunchRequest(
        method: ClockMethod.gps,
        reading: PunchLocationReading(latitude: 1, longitude: 2),
      );

      expect(request.validate().isSuccess, isTrue);
    });

    test('a WiFi punch needs a BSSID', () {
      const request = PunchRequest(
        method: ClockMethod.wifi,
        reading: PunchLocationReading(wifiSsid: 'Office'),
      );

      expect(
        request.validate().failureOrNull!.message,
        ValidationCode.wifiUnavailable,
      );
    });

    test('field work needs a non-blank reason', () {
      const blank = PunchRequest(
        method: ClockMethod.field,
        fieldWorkReason: '   ',
      );
      const given = PunchRequest(
        method: ClockMethod.field,
        fieldWorkReason: 'site visit',
      );

      expect(
        blank.validate().failureOrNull!.message,
        ValidationCode.fieldReasonRequired,
      );
      // Field work needs no device signal at all.
      expect(given.validate().isSuccess, isTrue);
    });
  });

  group('AttendanceNotifier', () {
    late FakeAttendanceRepository repository;
    late FakePunchLocationSource location;
    late ProviderContainer container;

    setUp(() {
      repository = FakeAttendanceRepository();
      location = FakePunchLocationSource();
      container = ProviderContainer(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(repository),
          punchLocationSourceProvider.overrideWithValue(location),
        ],
      );
    });

    tearDown(() => container.dispose());

    /// Reads the notifier and lets its deferred first load finish.
    Future<AttendanceNotifier> ready() async {
      final notifier = container.read(attendanceNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      return notifier;
    }

    test('loads today on creation', () async {
      repository.today = Result.success(_openDay());

      await ready();

      expect(repository.todayCalls, 1);
      expect(container.read(attendanceNotifierProvider).isClockedIn, isTrue);
    });

    test('punches clock-in when nothing is open', () async {
      repository.clockInResult = Result.success(PunchRecorded(_receipt()));

      final notifier = await ready();
      final result = await notifier.punch();

      expect(result!.dataOrNull, isA<PunchRecorded>());
      expect(repository.clockInRequests, hasLength(1));
      expect(repository.clockOutRequests, isEmpty);
      expect(location.reads.single, ClockMethod.gps);
    });

    test('punches clock-out once a session is open', () async {
      repository.today = Result.success(_openDay());
      repository.clockOutResult = Result.success(PunchRecorded(_receipt()));

      final notifier = await ready();
      await notifier.punch();

      expect(repository.clockOutRequests, hasLength(1));
      expect(repository.clockInRequests, isEmpty);
    });

    test('a recorded punch re-reads the day from the server', () async {
      repository.clockInResult = Result.success(PunchRecorded(_receipt()));

      final notifier = await ready();
      await notifier.punch();
      await Future<void>.delayed(Duration.zero);

      expect(repository.todayCalls, 2);
    });

    test('a missing GPS fix never reaches the network', () async {
      location.reading = PunchLocationReading.unavailable;

      final notifier = await ready();
      final result = await notifier.punch();

      expect(result!.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.isMissingEvidence, isTrue);
      expect(repository.clockInRequests, isEmpty);
    });

    test('a source that throws is read as "nothing available"', () async {
      location.error = StateError('permission denied');

      final notifier = await ready();
      final result = await notifier.punch();

      expect(result!.failureOrNull, isA<ValidationFailure>());
      expect(repository.clockInRequests, isEmpty);
    });

    test('the early-checkout retry re-sends the original reading', () async {
      repository.today = Result.success(_openDay());
      repository.clockOutResult = const Result.success(
        PunchBlocked(
          rule: AttendanceRule.earlyCheckoutRequiresReason,
          message: 'needs a reason',
          details: PunchBlockDetails(earliestCheckout: '17:20'),
        ),
      );

      final notifier = await ready();
      await notifier.punch();

      // The phone has moved on between the refusal and the retry.
      location.reading = PunchLocationReading.unavailable;
      repository.clockOutResult = Result.success(PunchRecorded(_receipt()));

      final retried = await notifier.retryWithReason('doctor');

      expect(retried!.dataOrNull, isA<PunchRecorded>());
      expect(repository.clockOutRequests, hasLength(2));

      final first = repository.clockOutRequests.first;
      final second = repository.clockOutRequests.last;
      expect(second.notes, 'doctor');
      // Same evidence as the first attempt — not a fresh, now-empty reading.
      expect(second.reading, first.reading);
      expect(location.reads, hasLength(1));
    });

    test('a 429 starts a cooldown that swallows the next press', () async {
      repository.clockInResult = const Result.failure(
        Failure.network(message: 'slow down', statusCode: 429),
      );

      final notifier = await ready();
      final first = await notifier.punch();

      expect(first!.failureOrNull!.isThrottled, isTrue);
      expect(container.read(attendanceNotifierProvider).isCoolingDown, isTrue);
      expect(container.read(attendanceNotifierProvider).canPunch, isFalse);

      // §7 rule 10: the control is inert until the window passes.
      expect(await notifier.punch(), isNull);
      expect(repository.clockInRequests, hasLength(1));
    });

    test('a failed day load leaves the control usable', () async {
      repository.today = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await ready();
      final state = container.read(attendanceNotifierProvider);

      expect(state.today.hasError, isTrue);
      expect(state.day, AttendanceDay.empty);
      expect(state.canPunch, isTrue);
    });

    test(
      'retryWithReason does nothing when there is no punch to retry',
      () async {
        final notifier = await ready();

        expect(await notifier.retryWithReason('x'), isNull);
      },
    );
  });
}
