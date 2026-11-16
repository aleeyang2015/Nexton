import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/pages/leave_request_detail_page.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/leave_test_doubles.dart';

/// Answers the by-id load after [delay], so a frame is drawn while it runs.
class _SlowDetail extends FakeLeaveRepository {
  Duration delay = Duration.zero;

  @override
  FutureResult<LeaveRequest> requestDetail(String id) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return super.requestDetail(id);
  }
}

void main() {
  final en = AppLocalizationsEn();
  late _SlowDetail repository;

  // The sample leave is 18–19 November 2026.
  final dayBefore = DateTime(2026, 11, 17, 9);
  final firstDay = DateTime(2026, 11, 18, 9);

  final pending = sampleLeaveRequest(id: 'req-7', reason: 'Family trip');
  final approved = sampleLeaveRequest(
    id: 'req-7',
    reason: 'Family trip',
    status: LeaveStatus.approved,
  );

  setUp(() {
    repository = _SlowDetail()..requestDetailResult = Result.success(pending);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    LeaveRequest? initial,
    DateTime? now,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaveRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now ?? dayBefore),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LeaveRequestDetailPage(requestId: 'req-7', initial: initial),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> confirmCancel(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, en.leaveCancelAction));
    await tester.pumpAndSettle();
    // The dialog's own confirm button carries the same words.
    await tester.tap(find.text(en.leaveCancelAction).last);
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  group('loading', () {
    testWidgets('the copy handed in shows first, then the loaded one', (
      tester,
    ) async {
      repository
        ..delay = const Duration(milliseconds: 300)
        // HR approved it since the list was loaded.
        ..requestDetailResult = Result.success(approved);

      await pumpPage(tester, initial: pending);

      expect(find.text(en.leaveStatusPending), findsWidgets);
      expect(find.text(en.leaveEditAction), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text(en.leaveStatusApproved), findsWidgets);
      expect(find.text(en.leaveEditAction), findsNothing);
    });

    testWidgets('with nothing handed in it loads by id and shows the '
        'request', (tester) async {
      await pumpPage(tester);

      expect(repository.requestDetailCalls, ['req-7']);
      expect(find.text('Family trip'), findsOneWidget);
    });

    testWidgets('a request that is gone, or someone else\'s, shows "not '
        'available" with no Retry, even over a copy handed in', (
      tester,
    ) async {
      repository.requestDetailResult = const Result.failure(
        Failure.validation(message: 'leaveRequestGone'),
      );

      await pumpPage(tester, initial: pending);

      expect(find.text(en.leaveRequestGone), findsOneWidget);
      expect(find.text(en.retry), findsNothing);
      expect(find.text('Family trip'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('no signal with nothing to show offers Retry, and Retry '
        'loads', (tester) async {
      repository.requestDetailResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await pumpPage(tester);
      expect(find.text(en.retry), findsOneWidget);

      repository.requestDetailResult = Result.success(pending);
      await tester.tap(find.text(en.retry));
      await tester.pump();
      await tester.pump();

      expect(find.text('Family trip'), findsOneWidget);
    });

    testWidgets('no signal over a copy handed in keeps showing that copy', (
      tester,
    ) async {
      repository.requestDetailResult = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await pumpPage(tester, initial: pending);

      expect(find.text('Family trip'), findsOneWidget);
    });

    testWidgets('a login with no staff record is told so, with no Retry', (
      tester,
    ) async {
      repository.requestDetailResult = const Result.failure(
        Failure.validation(message: 'leaveEmployeeNotFound'),
      );

      await pumpPage(tester);

      expect(find.text(en.leaveEmployeeNotFound), findsOneWidget);
      expect(find.text(en.retry), findsNothing);
    });
  });

  testWidgets('a pull to refresh shows the request as it now is: approved, '
      'and Edit is gone', (tester) async {
    await pumpPage(tester);
    expect(find.text(en.leaveEditAction), findsOneWidget);

    repository.requestDetailResult = Result.success(approved);
    await tester.fling(find.text('Family trip'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repository.requestDetailCalls, hasLength(2));
    expect(find.text(en.leaveStatusApproved), findsWidgets);
    expect(find.text(en.leaveEditAction), findsNothing);
  });

  group('who may cancel', () {
    Finder cancelButton() =>
        find.widgetWithText(OutlinedButton, en.leaveCancelAction);

    testWidgets('a pending request offers Edit and Cancel, on any date', (
      tester,
    ) async {
      await pumpPage(tester, now: DateTime(2026, 12, 1));

      expect(find.text(en.leaveEditAction), findsOneWidget);
      expect(cancelButton(), findsOneWidget);
      expect(find.text(en.leaveStartedContactHr), findsNothing);
    });

    testWidgets('an approved leave starting tomorrow offers Cancel, with '
        'the approved wording', (tester) async {
      repository.requestDetailResult = Result.success(approved);
      await pumpPage(tester, now: dayBefore);

      expect(cancelButton(), findsOneWidget);
      expect(find.text(en.leaveEditAction), findsNothing);

      await tester.tap(cancelButton());
      await tester.pumpAndSettle();

      expect(find.text(en.leaveCancelApprovedConfirm), findsOneWidget);
      expect(find.text(en.leaveCancelConfirm), findsNothing);
    });

    testWidgets('a pending request keeps the plain question', (tester) async {
      await pumpPage(tester);

      await tester.tap(cancelButton());
      await tester.pumpAndSettle();

      expect(find.text(en.leaveCancelConfirm), findsOneWidget);
      expect(find.text(en.leaveCancelApprovedConfirm), findsNothing);
    });

    testWidgets('an approved leave that started today has no Cancel, and '
        'says to contact HR', (tester) async {
      repository.requestDetailResult = Result.success(approved);
      await pumpPage(tester, now: firstDay);

      expect(cancelButton(), findsNothing);
      expect(find.text(en.leaveStartedContactHr), findsOneWidget);
    });

    testWidgets('a cancelled or rejected request offers nothing', (
      tester,
    ) async {
      repository.requestDetailResult = Result.success(
        sampleLeaveRequest(id: 'req-7', status: LeaveStatus.cancelled),
      );
      await pumpPage(tester);

      expect(cancelButton(), findsNothing);
      expect(find.text(en.leaveEditAction), findsNothing);
      expect(find.text(en.leaveStartedContactHr), findsNothing);
    });
  });

  group('cancelling', () {
    testWidgets('success stays on the page and shows it as cancelled', (
      tester,
    ) async {
      await pumpPage(tester);
      repository.requestDetailResult = Result.success(
        sampleLeaveRequest(id: 'req-7', status: LeaveStatus.cancelled),
      );

      await confirmCancel(tester);

      expect(repository.cancelCalls, ['req-7']);
      expect(find.byType(LeaveRequestDetailPage), findsOneWidget);
      expect(find.text(en.leaveRequestCancelled), findsOneWidget);
      expect(find.text(en.leaveStatusCancelled), findsWidgets);
      expect(
        find.widgetWithText(OutlinedButton, en.leaveCancelAction),
        findsNothing,
      );
    });

    testWidgets('refused because it changed: says so and reloads in place', (
      tester,
    ) async {
      await pumpPage(tester);
      repository
        ..cancelResult = const Result.failure(
          Failure.validation(message: 'leaveChanged'),
        )
        ..requestDetailResult = Result.success(approved);

      await confirmCancel(tester);

      expect(find.text(en.leaveChanged), findsOneWidget);
      expect(find.byType(LeaveRequestDetailPage), findsOneWidget);
      expect(repository.requestDetailCalls, hasLength(2));
      expect(find.text(en.leaveStatusApproved), findsWidgets);
    });

    testWidgets('refused because the leave has started: says to ask HR, and '
        'reloads', (tester) async {
      repository.requestDetailResult = Result.success(approved);
      await pumpPage(tester, now: dayBefore);
      repository.cancelResult = const Result.failure(
        Failure.validation(message: 'leaveStartedContactHr'),
      );

      await confirmCancel(tester);

      expect(find.text(en.leaveStartedContactHr), findsWidgets);
      expect(repository.requestDetailCalls, hasLength(2));
    });

    testWidgets('no signal: says so and does not reload', (tester) async {
      await pumpPage(tester);
      repository.cancelResult = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await confirmCancel(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(repository.requestDetailCalls, hasLength(1));
      expect(
        find.widgetWithText(OutlinedButton, en.leaveCancelAction),
        findsOneWidget,
      );
    });
  });
}
