import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/punch_receipt.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:next_on/features/attendance/presentation/widgets/punch_flow.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';

/// A punch the backend logged but refused on location, for [reason].
PunchReceipt _rejected({
  PunchRejectionReason reason = PunchRejectionReason.outsideGeofence,
}) => PunchReceipt(
  checkinId: 'id',
  verification: PunchVerification.rejected,
  message: 'Recorded, outside the work area',
  rejectionReason: reason,
  timestamp: DateTime(2026, 10, 6, 8, 5),
);

/// The day a clock-out is owed on: one session opened this morning.
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

void main() {
  /// Mounts a button that runs [PunchFlow.start], with the off-site form
  /// stubbed at its real route so what the flow pushes — and with which
  /// direction — can be read off the screen.
  Future<FakeAttendanceRepository> pumpFlow(
    WidgetTester tester, {
    AttendanceDay? today,
    Result<PunchOutcome>? clockIn,
    Result<PunchOutcome>? clockOut,
  }) async {
    final repository = FakeAttendanceRepository()
      ..clockInResult = clockIn
      ..clockOutResult = clockOut;
    if (today != null) repository.today = Result.success(today);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(repository),
          punchLocationSourceProvider.overrideWithValue(
            FakePunchLocationSource(),
          ),
        ],
        child: MaterialApp.router(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      // Watched, as the real status card does: the flow reads
                      // `nextAction` off this state, so the day has to have
                      // loaded before the button is pressed.
                      ref.watch(attendanceNotifierProvider);
                      return TextButton(
                        onPressed: () => PunchFlow.start(context, ref),
                        child: const Text('PUNCH'),
                      );
                    },
                  ),
                ),
              ),
              // Stands in for OffsiteRequestPage, reading the direction the
              // flow handed over exactly as the real route does.
              GoRoute(
                path: AppRoutes.offsiteRequest,
                builder: (_, state) =>
                    Scaffold(body: Text('FORM:${state.extra}')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  group('a punch refused for being out of area', () {
    testWidgets('offers the off-site request and opens it on the punch\'s '
        'direction', (tester) async {
      await pumpFlow(
        tester,
        clockIn: Result.success(PunchRecorded(_rejected())),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();

      expect(find.text('Outside the work area'), findsOneWidget);
      // The documented 200 path *does* store the punch, so this wording stays.
      expect(
        find.textContaining('was recorded but not accepted'),
        findsOneWidget,
      );
      expect(
        find.textContaining('request an off-site clock-in from here'),
        findsOneWidget,
      );

      await tester.tap(find.text('Request off-site scan'));
      await tester.pumpAndSettle();

      // Straight to the form, opened as a check-in — the punch that failed.
      expect(find.text('FORM:${OffsiteMethod.checkIn}'), findsOneWidget);
    });

    testWidgets('a refused clock-out opens the form as a check-out', (
      tester,
    ) async {
      await pumpFlow(
        tester,
        today: _openDay(),
        clockOut: Result.success(PunchRecorded(_rejected())),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('request an off-site clock-out from here'),
        findsOneWidget,
      );

      await tester.tap(find.text('Request off-site scan'));
      await tester.pumpAndSettle();

      expect(find.text('FORM:${OffsiteMethod.checkOut}'), findsOneWidget);
    });

    testWidgets('declining stays put and still warns the punch didn\'t count', (
      tester,
    ) async {
      await pumpFlow(
        tester,
        clockIn: Result.success(PunchRecorded(_rejected())),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('FORM:'), findsNothing);
      // They are still told the punch didn't pass its location check.
      expect(
        find.text(
          'Recorded, but your location could not be verified: you are outside '
          'the allowed area',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a verified punch is not offered the off-site form', (
      tester,
    ) async {
      await pumpFlow(
        tester,
        clockIn: Result.success(
          PunchRecorded(
            PunchReceipt(
              checkinId: 'id',
              verification: PunchVerification.verified,
              message: 'ok',
              timestamp: DateTime(2026, 10, 6, 8, 5),
            ),
          ),
        ),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();

      expect(find.text('Outside the work area'), findsNothing);
    });

    testWidgets('a rejection the off-site form cannot fix only warns', (
      tester,
    ) async {
      // No coordinates means no request to file — §3 requires lat/lng — so the
      // flow must not send the employee to a form that can't be submitted.
      await pumpFlow(
        tester,
        clockIn: Result.success(
          PunchRecorded(
            _rejected(reason: PunchRejectionReason.missingCoordinates),
          ),
        ),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();

      expect(find.text('Outside the work area'), findsNothing);
    });
  });

  group('a punch the backend refused outright for being out of area', () {
    // The deployed API answers this case with an error rather than the 200
    // rejected receipt §3 documents, so it arrives as a PunchBlocked. Both
    // paths owe the employee the same way forward.
    testWidgets('offers the off-site request and opens it as a check-out', (
      tester,
    ) async {
      await pumpFlow(
        tester,
        today: _openDay(),
        clockOut: Result.success(
          const PunchBlocked(
            rule: AttendanceRule.outsideWorkArea,
            message: 'Clock-out rejected: you are outside all work locations',
          ),
        ),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();

      expect(find.text('Outside the work area'), findsOneWidget);
      // Refused, not stored — the wording must not claim a record exists.
      expect(
        find.textContaining('was not accepted and nothing was recorded'),
        findsOneWidget,
      );
      expect(
        find.textContaining('request an off-site clock-out from here'),
        findsOneWidget,
      );

      await tester.tap(find.text('Request off-site scan'));
      await tester.pumpAndSettle();

      expect(find.text('FORM:${OffsiteMethod.checkOut}'), findsOneWidget);
    });

    testWidgets('declining still shows the backend\'s own wording', (
      tester,
    ) async {
      await pumpFlow(
        tester,
        clockIn: Result.success(
          const PunchBlocked(
            rule: AttendanceRule.outsideWorkArea,
            message: 'Clock-in rejected: you are outside all work locations',
          ),
        ),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('FORM:'), findsNothing);
      expect(
        find.text('Clock-in rejected: you are outside all work locations'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to localized copy when the backend sent none', (
      tester,
    ) async {
      await pumpFlow(
        tester,
        clockIn: Result.success(
          const PunchBlocked(
            rule: AttendanceRule.outsideWorkArea,
            message: '',
          ),
        ),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You are outside every work area, so this punch was not accepted.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a different refusal is not offered the off-site form', (
      tester,
    ) async {
      await pumpFlow(
        tester,
        today: _openDay(),
        clockOut: Result.success(
          const PunchBlocked(
            rule: AttendanceRule.sessionAlreadyCheckedOut,
            message: 'Already checked out',
          ),
        ),
      );

      await tester.tap(find.text('PUNCH'));
      await tester.pumpAndSettle();

      expect(find.text('Outside the work area'), findsNothing);
    });
  });
}
