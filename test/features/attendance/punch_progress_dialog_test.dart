import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/presentation/widgets/punch_progress_dialog.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  /// Pumps a bare host and hands back a context under a Navigator.
  Future<BuildContext> host(WidgetTester tester) async {
    late BuildContext captured;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold();
          },
        ),
      ),
    );

    return captured;
  }

  /// Builds the just-pushed dialog.
  ///
  /// Explicit pumps rather than `pumpAndSettle`: the progress spinner never
  /// stops animating, so settling would wait forever.
  Future<void> show(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// Clears the minimum-visible hold and the dismissal animation.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(PunchProgressDialog.minimumVisible);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('names the punch in flight and blocks the screen', (
    tester,
  ) async {
    final context = await host(tester);
    final pending = Completer<String>();

    final run = PunchProgressDialog.runWhile(
      context,
      ClockAction.clockIn,
      () => pending.future,
    );
    await show(tester);

    expect(find.text('Checking you in…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Not dismissible: the punch is already on its way.
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    pending.complete('recorded');
    await settle(tester);

    expect(await run, 'recorded');
    expect(find.byType(PunchProgressDialog), findsNothing);
  });

  testWidgets('says "checking you out" for a clock-out', (tester) async {
    final context = await host(tester);
    final pending = Completer<String>();

    final run = PunchProgressDialog.runWhile(
      context,
      ClockAction.clockOut,
      () => pending.future,
    );
    await show(tester);

    expect(find.text('Checking you out…'), findsOneWidget);
    expect(find.text('Checking you in…'), findsNothing);

    pending.complete('recorded');
    await settle(tester);
    await run;
  });

  testWidgets('comes down even when the punch throws', (tester) async {
    final context = await host(tester);
    final pending = Completer<String>();

    final run = PunchProgressDialog.runWhile(
      context,
      ClockAction.clockIn,
      () => pending.future,
    );
    await show(tester);
    expect(find.byType(PunchProgressDialog), findsOneWidget);

    // The error still reaches the caller — the dialog changes nothing about
    // how a failure is reported. Claimed before the error is raised, so the
    // rejection is never momentarily unhandled.
    final expectation = expectLater(run, throwsA(isA<StateError>()));

    pending.completeError(StateError('boom'));
    await settle(tester);
    await expectation;

    expect(find.byType(PunchProgressDialog), findsNothing);
  });

  testWidgets('stays up long enough to be seen when the punch is instant', (
    tester,
  ) async {
    final context = await host(tester);

    final run = PunchProgressDialog.runWhile(
      context,
      ClockAction.clockIn,
      () async => 'immediate',
    );

    // A dialog that appeared and vanished within a frame would read as a
    // glitch, so it is held for the minimum instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PunchProgressDialog), findsOneWidget);

    await settle(tester);
    expect(await run, 'immediate');
    expect(find.byType(PunchProgressDialog), findsNothing);
  });
}
