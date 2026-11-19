import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_summary.dart';
import 'package:next_on/features/home/presentation/widgets/attendance_history_summary.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';

void main() {
  late FakeAttendanceRepository repository;

  setUp(() {
    repository = FakeAttendanceRepository();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: AttendanceHistorySummary()),
        ),
        GoRoute(
          path: '/attendance-history',
          builder: (_, __) => const Scaffold(body: Text('HISTORY')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
  }

  testWidgets('shows a loading skeleton before the summary resolves', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Days present'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders all eight numbers and the base line once it loads', (
    tester,
  ) async {
    repository.monthSummary = const Result.success(
      AttendanceSummary(
        totalWorkingDays: 23,
        presentDays: 15,
        lateDays: 2,
        halfDays: 1,
        incompleteDays: 3,
        absentDays: 4,
        leaveDays: 5,
        totalWorkHours: 121.5,
        totalOvertimeHours: 6.5,
      ),
    );

    await pumpCard(tester);
    await tester.pump();

    expect(find.text('Out of 23 working days'), findsOneWidget);
    for (final (label, value) in const [
      ('Days present', '15'),
      ('Days late', '2'),
      ('Half day', '1'),
      ('Incomplete', '3'),
      ('Days absent', '4'),
      ('Leave Days', '5'),
      ('Work Hours', '121.5'),
      ('OT Hours', '6.5'),
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
      expect(find.text(value), findsOneWidget, reason: '$label = $value');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a month with no OT shows 0 on the OT card', (tester) async {
    repository.monthSummary = const Result.success(
      AttendanceSummary(totalWorkingDays: 23, presentDays: 15),
    );

    await pumpCard(tester);
    await tester.pump();

    expect(find.text('OT Hours'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(6)); // five day counts and the OT
  });

  testWidgets('fits a small phone in Lao without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository.monthSummary = const Result.success(
      AttendanceSummary(
        totalWorkingDays: 23,
        presentDays: 15,
        lateDays: 12,
        halfDays: 10,
        incompleteDays: 13,
        absentDays: 14,
        leaveDays: 15,
        totalWorkHours: 1121.5,
        totalOvertimeHours: 110.5,
      ),
    );

    await pumpCard(tester, locale: const Locale('lo'));
    await tester.pump();

    expect(find.text('ຈາກ 23 ມື້ເຮັດວຽກ'), findsOneWidget);
    expect(find.text('ວັນລາພັກ'), findsOneWidget);
    // The OT tile says "ໂອທີ" alone: on a phone this narrow the labels are
    // cut short, and "ຊົ່ວໂມງໂອທີ" was cut to the same first word as the work
    // hours tile beside it ("ຊົ່ວໂມງວຽກ").
    expect(find.text('ໂອທີ'), findsOneWidget);
    expect(find.text('ຊົ່ວໂມງໂອທີ'), findsNothing);
    expect(find.text('ຊົ່ວໂມງວຽກ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed load says "could not load" with a Retry, never '
      'zeros', (tester) async {
    repository.monthSummary = const Result.failure(
      Failure.network(message: 'offline'),
    );

    await pumpCard(tester);
    await tester.pump();

    expect(find.text('Could not load attendance.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('0.0'), findsNothing);
    expect(find.text('Days present'), findsNothing);
  });

  testWidgets('Retry loads the numbers', (tester) async {
    repository.monthSummary = const Result.failure(
      Failure.network(message: 'offline'),
    );
    await pumpCard(tester);
    await tester.pump();

    repository.monthSummary = const Result.success(
      AttendanceSummary(totalWorkingDays: 20, presentDays: 18),
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Out of 20 working days'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a login with no employee record is told so, with no Retry', (
    tester,
  ) async {
    repository.monthSummary = const Result.failure(
      Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      ),
    );

    await pumpCard(tester);
    await tester.pump();

    expect(
      find.text(
        'Your account is not linked to an employee record. '
        'Please contact HR.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a backend that never answers ends in "could not load" with a '
      'Retry, not zeros', (tester) async {
    repository.hangSummary = true;

    await pumpCard(tester);
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();

    expect(find.text('Could not load attendance.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('tapping view details navigates to the history page', (
    tester,
  ) async {
    repository.monthSummary = const Result.success(AttendanceSummary.empty);

    await pumpCard(tester);
    await tester.pump();

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('HISTORY'), findsOneWidget);
  });
}
