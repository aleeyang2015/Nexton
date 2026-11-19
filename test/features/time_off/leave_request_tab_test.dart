import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/pages/leave_request_detail_page.dart';
import 'package:next_on/features/time_off/presentation/pages/leave_request_edit_page.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_notifier.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_request_tab.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/leave_test_doubles.dart';

/// The new-request tab while a request is already waiting, and the edit page
/// opened by id alone.
void main() {
  final en = AppLocalizationsEn();
  late FakeLeaveRepository repository;
  late ProviderContainer container;

  final waiting = sampleLeaveRequest(id: 'req-waiting', reason: 'Family trip');

  setUp(() {
    repository = FakeLeaveRepository()
      ..leaveTypesResult = Result.success([sampleLeaveType()])
      ..balancesByYear[2026] = Result.success([sampleLeaveBalance()])
      ..requestDetailResult = Result.success(waiting);
    container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 10, 9)),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: LeaveRequestTab()),
        ),
        ...leaveRequestRoutes,
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  bool submitEnabled(WidgetTester tester) => tester
      .widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, en.leaveRequestSubmit),
      )
      .enabled;

  void fillForm() {
    container.read(leaveRequestFormNotifierProvider(null).notifier)
      ..setLeaveType('lt-annual')
      ..setDates([DateTime(2026, 11, 18)]);
  }

  group('the new-request tab', () {
    testWidgets('with no request waiting: no banner, and a filled form can '
        'be sent', (tester) async {
      await pumpAt(tester, '/');
      fillForm();
      await tester.pump();

      expect(find.text(en.leaveRequestPendingBanner), findsNothing);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('with a request waiting: the banner shows and Submit is off, '
        'however the form is filled', (tester) async {
      repository.pendingRequestResult = Result.success(waiting);

      await pumpAt(tester, '/');
      fillForm();
      await tester.pump();

      expect(find.text(en.leaveRequestPendingBanner), findsOneWidget);
      expect(find.text(en.leaveViewRequest), findsOneWidget);
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('the link opens that request', (tester) async {
      repository.pendingRequestResult = Result.success(waiting);
      await pumpAt(tester, '/');

      await tester.tap(find.text(en.leaveViewRequest));
      await tester.pumpAndSettle();

      final page = tester.widget<LeaveRequestDetailPage>(
        find.byType(LeaveRequestDetailPage),
      );
      expect(page.requestId, 'req-waiting');
      expect(find.text('Family trip'), findsOneWidget);
    });

    testWidgets('when the check fails there is no banner and Submit stays '
        'on: the server still refuses', (tester) async {
      repository.pendingRequestResult = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await pumpAt(tester, '/');
      fillForm();
      await tester.pump();

      expect(find.text(en.leaveRequestPendingBanner), findsNothing);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('sending a request asks again who is waiting, and the '
        'banner appears', (tester) async {
      await pumpAt(tester, '/');
      fillForm();
      await tester.pump();
      expect(repository.pendingRequestCalls, 1);

      repository.pendingRequestResult = Result.success(waiting);
      await tester.tap(
        find.widgetWithText(ElevatedButton, en.leaveRequestSubmit),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(repository.submitCalls, hasLength(1));
      expect(repository.pendingRequestCalls, 2);
      expect(find.text(en.leaveRequestPendingBanner), findsOneWidget);
    });
  });

  group('the edit page opened by id alone', () {
    testWidgets('loads the request and fills the form from it, once', (
      tester,
    ) async {
      await pumpAt(tester, '/time-off/request/req-waiting/edit');
      await tester.pump();

      expect(find.byType(LeaveRequestEditPage), findsOneWidget);
      expect(repository.requestDetailCalls, ['req-waiting']);
      final state = container.read(
        leaveRequestFormNotifierProvider('req-waiting'),
      );
      expect(state.isEditing, isTrue);
      expect(state.reason, 'Family trip');
      // An edit shows no "you already have one waiting" banner: it is the
      // one waiting.
      expect(find.text(en.leaveRequestPendingBanner), findsNothing);
    });

    testWidgets('a request that is gone shows "not available", not a form', (
      tester,
    ) async {
      repository.requestDetailResult = const Result.failure(
        Failure.validation(message: 'leaveRequestGone'),
      );

      await pumpAt(tester, '/time-off/request/req-waiting/edit');
      await tester.pump();

      expect(find.text(en.pushItemUnavailable), findsOneWidget);
      expect(find.text(en.leaveEditAction), findsOneWidget); // the title only
    });

    testWidgets('a request that is no longer pending cannot be edited', (
      tester,
    ) async {
      repository.requestDetailResult = Result.success(
        sampleLeaveRequest(
          id: 'req-waiting',
          status: LeaveStatus.approved,
        ),
      );

      await pumpAt(tester, '/time-off/request/req-waiting/edit');
      await tester.pump();

      expect(find.text(en.leaveInvalidStatus), findsOneWidget);
      expect(
        container.read(leaveRequestFormNotifierProvider('req-waiting')).isEditing,
        isFalse,
      );
    });
  });
}
