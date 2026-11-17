import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/core/widgets/error_page.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_request.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/presentation/pages/offsite_request_page.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/upload_test_doubles.dart';

/// Holds the submit until [hold] completes, when set.
class _HeldOffsite extends FakeOffsiteRepository {
  Completer<void>? hold;

  @override
  FutureResult<OffsiteOutcome> submit(OffsiteRequest request) async {
    final answer = super.submit(request);
    final h = hold;
    hold = null;
    await h?.future;
    return answer;
  }
}

/// The off-site form (#40): opened only from a refused punch, camera only,
/// and today read again after sending.
void main() {
  final en = AppLocalizationsEn();
  late _HeldOffsite offsite;
  late FakeAttendanceRepository attendance;
  late GoRouter router;

  setUp(() {
    offsite = _HeldOffsite();
    attendance = FakeAttendanceRepository();
  });

  Future<ProviderContainer> open(
    WidgetTester tester, {
    Object? extra = OffsiteMethod.checkIn,
  }) async {
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: AppRoutes.offsiteRequest,
          builder: (context, state) => offsiteRequestPageFor(state.extra),
        ),
        // The camera: pops at once with a photo.
        GoRoute(
          path: AppRoutes.cameraCapture,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(
                const LocalFile(path: '/phone/shop.jpg', name: 'shop.jpg'),
              ),
              child: const Text('SHOOT'),
            ),
          ),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        offsiteRepositoryProvider.overrideWithValue(offsite),
        attendanceRepositoryProvider.overrideWithValue(attendance),
        punchLocationSourceProvider.overrideWithValue(
          FakePunchLocationSource(),
        ),
        uploadRepositoryProvider.overrideWithValue(FakeUploads()),
      ],
    );
    addTearDown(container.dispose);
    // Today's card is on screen behind the form.
    container.listen(attendanceNotifierProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    unawaited(router.push(AppRoutes.offsiteRequest, extra: extra));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> fillIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Client visit at the shop');
    await tester.tap(find.text(en.timeCorrectionTakePhoto).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SHOOT'));
    // The photo's size is read from disk: real IO, outside the test clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.text(en.offsiteSubmit));
    await tester.pumpAndSettle();
  }

  testWidgets('no direction (a link, a restored route): not found',
      (tester) async {
    await open(tester, extra: null);

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.byType(OffsiteRequestPage), findsNothing);
  });

  testWidgets('the direction is the refused punch\'s, shown and not offered '
      'to change; the photo is camera only', (tester) async {
    await open(tester, extra: OffsiteMethod.checkOut);

    expect(find.text(en.offsiteMethodCheckOut), findsOneWidget);
    expect(find.text(en.offsiteMethodCheckIn), findsNothing);
    expect(find.text(en.offsiteChooseImage), findsNothing);
    expect(find.text(en.timeCorrectionTakePhoto), findsWidgets);
  });

  testWidgets('without a photo nothing is sent', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Client visit');

    await send(tester);

    expect(offsite.submitted, isEmpty);
    expect(find.byType(OffsiteRequestPage), findsOneWidget);
  });

  testWidgets('recorded: says so, today is read again, the form closes',
      (tester) async {
    await open(tester);
    final todayBefore = attendance.todayCalls;
    await fillIn(tester);

    await send(tester);

    expect(offsite.submitted.single.method, OffsiteMethod.checkIn);
    expect(find.text(en.offsiteSubmitApproved), findsOneWidget);
    expect(attendance.todayCalls, greaterThan(todayBefore));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('sent for approval: says so, today is read again, the form '
      'closes', (tester) async {
    offsite.submitResult = const Result.success(
      OffsiteFiled(OffsiteSubmission(autoApproved: false)),
    );
    await open(tester);
    final todayBefore = attendance.todayCalls;
    await fillIn(tester);

    await send(tester);

    expect(find.text(en.offsiteSubmitPending), findsOneWidget);
    expect(attendance.todayCalls, greaterThan(todayBefore));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a session that already started (SESSION_*): says why, today '
      'is read again, the form closes', (tester) async {
    offsite.submitResult = const Result.success(
      OffsiteBlocked(
        rule: AttendanceRule.sessionAlreadyStarted,
        message: 'server text',
      ),
    );
    await open(tester);
    final todayBefore = attendance.todayCalls;
    await fillIn(tester);

    await send(tester);

    expect(attendance.todayCalls, greaterThan(todayBefore));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('the clock-in still waits for approval: its own words (when the '
      'server sends none), and the form closes', (tester) async {
    offsite.submitResult = const Result.success(
      OffsiteBlocked(rule: AttendanceRule.checkinPendingApproval, message: ''),
    );
    await open(tester);
    await fillIn(tester);

    await send(tester);

    expect(find.text(en.attCheckinPendingApproval), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('too early: says why, and the form stays', (tester) async {
    offsite.submitResult = const Result.success(
      OffsiteBlocked(
        rule: AttendanceRule.tooEarlyCheckin,
        message: 'server text',
      ),
    );
    await open(tester);
    final todayBefore = attendance.todayCalls;
    await fillIn(tester);

    await send(tester);

    expect(find.byType(OffsiteRequestPage), findsOneWidget);
    expect(attendance.todayCalls, todayBefore);
  });

  testWidgets('a double tap on Send sends one request', (tester) async {
    await open(tester);
    await fillIn(tester);
    final slow = Completer<void>();
    offsite.hold = slow;

    final button = tester.getCenter(find.text(en.offsiteSubmit));
    await tester.tapAt(button);
    await tester.pump();
    // The second tap lands where the button was: it shows a spinner now.
    await tester.tapAt(button);
    await tester.pump();
    slow.complete();
    await tester.pumpAndSettle();

    expect(offsite.submitted, hasLength(1));
  });
}
