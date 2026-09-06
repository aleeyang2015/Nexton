import 'package:flutter/widgets.dart';
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
    AttendanceSession(
      label: '08:00–12:00',
      clockIn: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        8,
      ),
    ),
  ],
);

/// A session opened yesterday and never closed — the forgotten-clock-out
/// case: the employee should be able to clock in fresh today rather than
/// have the button hang on "clock out".
AttendanceDay _openDayFromYesterday() {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return AttendanceDay(
    sessions: [
      AttendanceSession(
        label: '08:00–12:00',
        clockIn: DateTime(yesterday.year, yesterday.month, yesterday.day, 8),
      ),
    ],
  );
}

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
      // The provider is `autoDispose`; a bare `container.read` leaves it with
      // no listener, so Riverpod tears it down again before the test can act
      // on it. A no-op listen, same as a widget's `ref.watch`, keeps it alive
      // — done here rather than in `setUp` so it still builds after each
      // test has finished configuring the fake repository's response.
      container.listen(attendanceNotifierProvider, (_, _) {});
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

    // Regression test: a session left open by a missed clock-out used to
    // stay on screen indefinitely because nothing re-read `today` once the
    // provider was built — neither on resume, nor when the calendar day
    // quietly rolled over underneath a foregrounded app.
    testWidgets('re-reads today when the app resumes from the background', (
      tester,
    ) async {
      repository.today = Result.success(_openDay());

      // A container of its own, disposed before this body returns: the
      // shared `container`/`tearDown` pair disposes *after* Flutter's
      // pending-timer check for this test already ran, which would catch
      // the still-armed midnight timer as a leak.
      final localContainer = ProviderContainer(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(repository),
          punchLocationSourceProvider.overrideWithValue(location),
        ],
      );

      // Not `ready()`: testWidgets runs the body in a fake-async zone, so
      // the microtask-deferred first load needs a pump to flush, not a
      // real delay.
      //
      // The provider is `autoDispose`, so it needs a listener to survive
      // past this line the same way a widget's `ref.watch` would keep it
      // alive.
      localContainer.listen(attendanceNotifierProvider, (_, _) {});
      localContainer.read(attendanceNotifierProvider.notifier);
      await tester.pump();
      expect(repository.todayCalls, 1);

      // A real backgrounding is resumed -> inactive -> ... -> paused, then
      // back out the same way; only the round trip through a non-resumed
      // state counts as a resume.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(repository.todayCalls, 2);

      localContainer.dispose();
    });

    test('refreshIfNewDay does nothing on the day it already loaded', () async {
      repository.today = Result.success(_openDay());
      final notifier = await ready();

      notifier.refreshIfNewDay();
      await Future<void>.delayed(Duration.zero);

      expect(repository.todayCalls, 1);
    });

    test(
      'a session left open from yesterday does not block a fresh clock-in',
      () async {
        repository.today = Result.success(_openDayFromYesterday());
        repository.clockInResult = Result.success(PunchRecorded(_receipt()));

        final notifier = await ready();
        final state = container.read(attendanceNotifierProvider);

        expect(state.isClockedIn, isFalse);
        expect(state.nextAction, ClockAction.clockIn);

        await notifier.punch();

        expect(repository.clockInRequests, hasLength(1));
        expect(repository.clockOutRequests, isEmpty);
      },
    );
  });
}
