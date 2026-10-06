import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_detail.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/presentation/pages/offsite_history_page.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';

void main() {
  OffsiteRequestDetail scan({
    String id = 'offsite-1',
    OffsiteMethod method = OffsiteMethod.checkIn,
    TimeCorrectionStatus status = TimeCorrectionStatus.pending,
    double? latitude = 17.9757,
    double? longitude = 102.6331,
  }) => OffsiteRequestDetail(
    id: id,
    employee: const TimeCorrectionEmployee(name: 'Noy Phommachanh'),
    method: method,
    latitude: latitude,
    longitude: longitude,
    scanTimestamp: DateTime(2026, 10, 2, 8, 15),
    scanDate: DateTime(2026, 10, 2),
    sessionOrder: 1,
    shift: null,
    attachmentUrl: 'https://cdn.nexton.work/uploads/abc.jpg',
    reason: 'With a customer',
    status: status,
    currentStepNo: 1,
    attendanceRecordId: null,
    steps: const [],
    submittedAt: DateTime(2026, 10, 2, 8, 15),
  );

  /// Mounts the page with [requests] queued behind the repository, and the
  /// request form stubbed at its real route so the banner's hop can be
  /// observed. English, so the assertions read as the copy they check.
  ///
  /// The surface is made tall enough for two whole cards, so a button near the
  /// bottom of one can be tapped without scrolling first.
  Future<FakeOffsiteRepository> pumpPage(
    WidgetTester tester,
    Result<List<OffsiteRequestDetail>> requests,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeOffsiteRepository()..mineResult = requests;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          // AppToast resolves its messenger through this key.
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          routerConfig: GoRouter(
            initialLocation: AppRoutes.offsiteHistory,
            routes: [
              GoRoute(
                path: AppRoutes.offsiteHistory,
                builder: (_, __) => const OffsiteHistoryPage(),
              ),
              GoRoute(
                path: AppRoutes.offsiteRequest,
                builder: (_, __) => const Scaffold(body: Text('FORM')),
              ),
            ],
          ),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  group('OffsiteHistoryPage', () {
    testWidgets('shows the scans already filed, with their status', (
      tester,
    ) async {
      await pumpPage(tester, Result.success([scan()]));

      expect(find.text('Clock in'), findsOneWidget);
      expect(find.text('02/10/2026'), findsOneWidget);
      expect(find.text('08:15'), findsOneWidget);
      expect(find.text('17.97570, 102.63310'), findsOneWidget);
      expect(find.textContaining('With a customer'), findsOneWidget);
      expect(find.text('Awaiting approval'), findsOneWidget);
      // The employee's own list carries no approve/reject buttons.
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('counts the statuses off the one list it fetched', (
      tester,
    ) async {
      final repository = await pumpPage(
        tester,
        Result.success([
          scan(),
          scan(id: 'offsite-2', status: TimeCorrectionStatus.approved),
          scan(id: 'offsite-3', status: TimeCorrectionStatus.approved),
        ]),
      );

      // One fetch, not one per status: `…/my` answers with each request's own
      // status, so the buckets are read locally.
      expect(repository.mineCalls, 1);
      expect(find.text('All (3)'), findsOneWidget);
    });

    testWidgets('the status filter narrows the list to the picked status', (
      tester,
    ) async {
      await pumpPage(
        tester,
        Result.success([
          scan(),
          scan(
            id: 'offsite-2',
            method: OffsiteMethod.checkOut,
            status: TimeCorrectionStatus.approved,
          ),
        ]),
      );

      await tester.tap(find.text('All (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approved (1)').last);
      await tester.pumpAndSettle();

      expect(find.text('Clock out'), findsOneWidget);
      expect(find.text('Clock in'), findsNothing);
    });

    testWidgets(
      'the banner opens the request form and reloads on the way back',
      (tester) async {
        final repository = await pumpPage(tester, Result.success([scan()]));
        expect(repository.mineCalls, 1);

        await tester.tap(find.text('New off-site scan'));
        await tester.pumpAndSettle();
        expect(find.text('FORM'), findsOneWidget);

        // Back out of the form: a scan just filed has to show up.
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        expect(find.text('FORM'), findsNothing);
        expect(repository.mineCalls, 2);
      },
    );

    testWidgets('only a pending request offers to be withdrawn', (
      tester,
    ) async {
      await pumpPage(
        tester,
        Result.success([
          scan(),
          scan(id: 'offsite-2', status: TimeCorrectionStatus.approved),
        ]),
      );

      // Two cards, one button: §9 allows withdrawing only a pending request.
      expect(find.text('Cancel request'), findsOneWidget);
    });

    testWidgets('withdrawing asks first, then reloads the list', (
      tester,
    ) async {
      final repository = await pumpPage(tester, Result.success([scan()]));

      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();

      // Backing out of the dialog leaves the request alone.
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(repository.cancelled, isEmpty);
      expect(repository.mineCalls, 1);

      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel request').last);
      await tester.pumpAndSettle();

      expect(repository.cancelled, ['offsite-1']);
      // Refetched, so the card shows the request as withdrawn.
      expect(repository.mineCalls, 2);
      expect(find.text('Request withdrawn'), findsOneWidget);
    });

    testWidgets('a request decided since it loaded says so, and reloads', (
      tester,
    ) async {
      final repository = await pumpPage(tester, Result.success([scan()]));
      // What §9 answers when the card has gone stale.
      repository.cancelResult = const Result.failure(
        Failure.validation(message: OffsiteErrorCode.tokenCannotCancel),
      );
      repository.mineResult = Result.success([
        scan(status: TimeCorrectionStatus.approved),
      ]);

      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel request').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This request can no longer be withdrawn — it has already been '
          'decided.',
        ),
        findsOneWidget,
      );
      // The list was refetched, so the card now reads as decided and offers
      // no withdrawal.
      expect(repository.mineCalls, 2);
      expect(find.text('Cancel request'), findsNothing);
    });

    testWidgets('an empty list reads as empty, not as a failure', (
      tester,
    ) async {
      await pumpPage(tester, const Result.success([]));

      expect(find.text('No off-site scan requests'), findsOneWidget);
      expect(
        find.text('Could not load your off-site scan requests.'),
        findsNothing,
      );
    });

    testWidgets('a failed load offers a retry', (tester) async {
      final repository = await pumpPage(
        tester,
        const Result.failure(Failure.network(message: 'offline')),
      );

      expect(
        find.text('Could not load your off-site scan requests.'),
        findsOneWidget,
      );

      repository.mineResult = Result.success([scan()]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Clock in'), findsOneWidget);
    });
  });
}
