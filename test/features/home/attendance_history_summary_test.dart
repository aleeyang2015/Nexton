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

  Future<void> pumpCard(WidgetTester tester) async {
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
          locale: const Locale('en'),
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

  testWidgets('renders the real month summary once it loads', (tester) async {
    repository.monthSummary = const Result.success(
      AttendanceSummary(
        presentDays: 15,
        lateDays: 2,
        absentDays: 1,
        totalWorkHours: 121.5,
      ),
    );

    await pumpCard(tester);
    await tester.pump();

    expect(find.text('15'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('121.5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a failed load falls back to zeros rather than showing a retry — this '
    'small at-a-glance card degrades quietly, unlike the full history page',
    (tester) async {
      repository.monthSummary = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await pumpCard(tester);
      await tester.pump();

      expect(find.text('Retry'), findsNothing);
      expect(find.text('0'), findsNWidgets(3)); // present/late/absent days
      expect(find.text('0.0'), findsOneWidget); // work hours
    },
  );

  testWidgets(
    'falls back to zeros rather than hanging when the backend never answers',
    (tester) async {
      repository.hangSummary = true;

      await pumpCard(tester);
      await tester.pump(const Duration(seconds: 16));

      expect(find.text('Retry'), findsNothing);
      expect(find.text('0'), findsNWidgets(3));
      expect(find.text('0.0'), findsOneWidget);
    },
  );

  testWidgets('tapping view all navigates to the history page', (
    tester,
  ) async {
    repository.monthSummary = const Result.success(AttendanceSummary.empty);

    await pumpCard(tester);
    await tester.pump();

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(find.text('HISTORY'), findsOneWidget);
  });
}
