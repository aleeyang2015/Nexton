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
  late FakePunchLocationSource location;
  late GoRouter router;

  setUp(() {
    offsite = _HeldOffsite();
    attendance = FakeAttendanceRepository();
    location = FakePunchLocationSource();
  });

  Future<ProviderContainer> open(
    WidgetTester tester, {
    Object? extra = OffsiteMethod.checkIn,
    bool settle = true,
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
        // A request's page, opened by "View" on the toast (#42).
        GoRoute(
          path: AppRoutes.myOffsiteRequestDetail,
          builder: (_, state) =>
              Scaffold(body: Text('DETAIL:${state.pathParameters['id']}')),
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
        punchLocationSourceProvider.overrideWithValue(location),
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // A spinner is running: let the page in, without waiting for it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
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
    expect(find.text('Choose image'), findsNothing);
    expect(find.byIcon(Icons.photo_library_outlined), findsNothing);
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

  testWidgets('the OT changed as the check-out went (OT_CHANGED, #110): '
      'today is read again and the form closes; with no server words, the '
      'App\'s own', (tester) async {
    offsite.submitResult = const Result.success(
      OffsiteBlocked(rule: AttendanceRule.otChanged, message: ''),
    );
    await open(tester);
    final todayBefore = attendance.todayCalls;
    await fillIn(tester);

    await send(tester);

    expect(find.text(en.ruleOtChanged), findsOneWidget);
    expect(attendance.todayCalls, greaterThan(todayBefore));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('no shift today (NO_SHIFT_ASSIGNED, #115): the App\'s own text, '
      'not the server\'s English; the form stays and today is not read again',
      (tester) async {
    const serverEnglish =
        'Cannot clock in — no work shift is assigned to this employee. '
        'Ask HR to assign a shift first.';
    offsite.submitResult = const Result.success(
      OffsiteBlocked(
        rule: AttendanceRule.noShiftAssigned,
        message: serverEnglish,
      ),
    );
    await open(tester);
    await fillIn(tester);
    final todayBefore = attendance.todayCalls;

    await send(tester);

    expect(find.text(en.ruleNoShiftAssigned), findsOneWidget);
    expect(find.text(serverEnglish), findsNothing);
    expect(attendance.todayCalls, todayBefore);
    expect(find.text('HOME'), findsNothing);
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

  testWidgets('back while the send is on its way: no error, and today is '
      'still read again', (tester) async {
    await open(tester);
    await fillIn(tester);
    final todayBefore = attendance.todayCalls;
    final slow = Completer<void>();
    offsite.hold = slow;

    await tester.tap(find.text(en.offsiteSubmit));
    await tester.pump();
    router.pop();
    await tester.pumpAndSettle();
    slow.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(offsite.submitted, hasLength(1));
    expect(attendance.todayCalls, greaterThan(todayBefore));
  });

  testWidgets('while the position is still being read, Send waits (no '
      '"something went wrong")', (tester) async {
    final slowFix = Completer<void>();
    location.hold = slowFix;
    await open(tester, settle: false);
    await tester.enterText(find.byType(TextField), 'Client visit');

    expect(find.text(en.offsiteSubmit), findsNothing);
    await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
    await tester.pump();
    expect(find.text(en.genericError), findsNothing);
    expect(offsite.submitted, isEmpty);

    slowFix.complete();
    await tester.pumpAndSettle();
    expect(find.text(en.offsiteSubmit), findsOneWidget);
  });

  testWidgets('"View" on the "recorded" toast opens the new request (#42)',
      (tester) async {
    offsite.submitResult = const Result.success(
      OffsiteFiled(OffsiteSubmission(autoApproved: true, requestId: 'new-1')),
    );
    await open(tester);
    await fillIn(tester);

    await send(tester);
    await tester.tap(find.text(en.attView));
    await tester.pumpAndSettle();

    expect(find.text('DETAIL:new-1'), findsOneWidget);
  });
}
