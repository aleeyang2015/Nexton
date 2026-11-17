import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:next_on/features/attendance/presentation/widgets/punch_flow.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';

/// The slide while an off-site check-in waits (#41): the clock-out goes as
/// an off-site request too, never through the phone door.
void main() {
  testWidgets('opens the off-site form as a check-out; the punch endpoint is '
      'not called; today is read again on the way back', (tester) async {
    final now = DateTime.now();
    final attendance = FakeAttendanceRepository();
    final offsite = FakeOffsiteRepository()
      ..waitingResult = Result.success([
        waitingOffsite(
          method: OffsiteMethod.checkIn,
          at: DateTime(now.year, now.month, now.day, 8),
        ),
      ]);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(attendanceNotifierProvider);
                return TextButton(
                  onPressed: () => PunchFlow.start(context, ref),
                  child: const Text('PUNCH'),
                );
              },
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.offsiteRequest,
          builder: (_, state) => Scaffold(body: Text('FORM:${state.extra}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(attendance),
          offsiteRepositoryProvider.overrideWithValue(offsite),
          punchLocationSourceProvider.overrideWithValue(
            FakePunchLocationSource(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final todayBefore = attendance.todayCalls;

    await tester.tap(find.text('PUNCH'));
    await tester.pumpAndSettle();

    expect(find.text('FORM:${OffsiteMethod.checkOut}'), findsOneWidget);
    expect(attendance.clockInRequests, isEmpty);
    expect(attendance.clockOutRequests, isEmpty);

    router.pop();
    await tester.pumpAndSettle();
    expect(attendance.todayCalls, greaterThan(todayBefore));
  });
}
