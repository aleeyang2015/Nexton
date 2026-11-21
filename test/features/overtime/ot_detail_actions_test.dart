import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/overtime/data/datasources/ot_error_code.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_ask_page.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_request_detail_page.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_ask_notifier.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/overtime_test_doubles.dart';
import '../../support/profile_test_doubles.dart';

/// Edit and Cancel on the OT request page: which show, and what each does.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();
  late FakeOtRepository repository;

  setUp(() => repository = FakeOtRepository());

  OtStep step(int no, OtStepStatus status) => OtStep(
    id: 's$no',
    stepNo: no,
    role: no == 1 ? OtStepRole.deptHead : OtStepRole.hr,
    status: status,
  );

  /// Noy's waiting request: nothing approved yet.
  OtRequest waiting({
    OtStatus status = OtStatus.pending,
    List<OtStep>? steps,
    String? announcementId,
    String employeeId = 'emp-noy',
  }) => sampleOt(
    'ot-7',
    status: status,
    announcementId: announcementId,
    employeeId: employeeId,
    reason: 'Stock count',
    steps:
        steps ??
        [step(1, OtStepStatus.pending), step(2, OtStepStatus.waiting)],
  );

  /// Opens the request's page from the OT list, signed in as [me].
  Future<void> openRequest(
    WidgetTester tester, {
    String locale = 'en',
    String? me = 'emp-noy',
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository.myRequestsAnswer = (call) =>
        const Result.success(OtPage(items: [], page: 1, totalPages: 1));

    final router = GoRouter(
      initialLocation: AppRoutes.overtime,
      routes: overtimeRoutes,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          otRepositoryProvider.overrideWithValue(repository),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          otOwnEmployeeIdProvider.overrideWithValue(me),
          ...extra,
        ],
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push(AppRoutes.otRequest('ot-7'));
    await tester.pumpAndSettle();
  }

  void serve(OtRequest request) =>
      repository.requestAnswer = (_) => Result.success(request);

  /// A button (outlined or filled) that says [label].
  Finder button(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );

  group('which buttons show', () {
    testWidgets('waiting, nothing approved: ແກ້ໄຂ and ຍົກເລີກ', (tester) async {
      serve(waiting());

      await openRequest(tester, locale: 'lo');

      expect(button('ແກ້ໄຂ'), findsOneWidget);
      expect(button('ຍົກເລີກ'), findsOneWidget);
    });

    testWidgets('a step approved: Cancel only', (tester) async {
      serve(
        waiting(
          steps: [step(1, OtStepStatus.approved), step(2, OtStepStatus.pending)],
        ),
      );

      await openRequest(tester);

      expect(button(en.otEditAction), findsNothing);
      expect(button(en.otCancelAction), findsOneWidget);
    });

    testWidgets('a join: Cancel, no Edit', (tester) async {
      serve(waiting(announcementId: 'post-1'));

      await openRequest(tester);

      expect(button(en.otEditAction), findsNothing);
      expect(button(en.otCancelAction), findsOneWidget);
    });

    testWidgets('approved: no buttons, and the "ask your approver" line', (
      tester,
    ) async {
      serve(waiting(status: OtStatus.approved));

      await openRequest(tester, locale: 'lo');

      expect(button(lo.otEditAction), findsNothing);
      expect(button(lo.otCancelAction), findsNothing);
      expect(
        find.text('ຢາກປ່ຽນ ຫຼື ຍົກເລີກ? ກະລຸນາຖາມຜູ້ອະນຸມັດ ຫຼື ຝ່າຍບຸກຄະລາກອນ.'),
        findsOneWidget,
      );
    });

    testWidgets('a head opening his team member\'s request: nothing', (
      tester,
    ) async {
      serve(waiting(employeeId: 'emp-other'));

      await openRequest(tester, me: 'emp-head');

      expect(button(en.otEditAction), findsNothing);
      expect(button(en.otCancelAction), findsNothing);
      expect(find.text(en.otAskApproverToChange), findsNothing);
    });
  });

  group('cancel', () {
    testWidgets('confirm, then the request shows cancelled, with the toast; '
        'the buttons go', (tester) async {
      serve(waiting());
      await openRequest(tester, locale: 'lo');

      await tester.tap(button('ຍົກເລີກ'));
      await tester.pumpAndSettle();
      expect(find.text('ຍົກເລີກຄຳຂໍໂອທີນີ້ບໍ?'), findsOneWidget);
      // The two buttons do not say the same word.
      expect(find.text(lo.back), findsOneWidget);

      await tester.tap(find.text('ຍົກເລີກ').last);
      await tester.pumpAndSettle();

      expect(repository.cancels, ['ot-7']);
      expect(find.text('ຍົກເລີກຄຳຂໍໂອທີແລ້ວ'), findsOneWidget);
      expect(find.text(lo.leaveStatusCancelled), findsWidgets);
      expect(button('ແກ້ໄຂ'), findsNothing);
      expect(button('ຍົກເລີກ'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('"Back" in the question sends nothing', (tester) async {
      serve(waiting());
      await openRequest(tester);

      await tester.tap(button(en.otCancelAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.back));
      await tester.pumpAndSettle();

      expect(repository.cancels, isEmpty);
      expect(button(en.otCancelAction), findsOneWidget);
    });

    testWidgets('a double tap asks once and sends once', (tester) async {
      serve(waiting());
      await openRequest(tester);
      final hold = Completer<void>();
      repository.holdCancel = hold;

      await tester.tap(button(en.otCancelAction));
      await tester.tap(button(en.otCancelAction), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(en.otCancelConfirm), findsOneWidget);

      await tester.tap(find.text(en.otCancelAction).last);
      await tester.pump();
      hold.complete();
      await tester.pumpAndSettle();

      expect(repository.cancels, hasLength(1));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('decided meanwhile: the Lao text, and the page reloads '
        'without the buttons', (tester) async {
      serve(waiting());
      await openRequest(tester, locale: 'lo');
      repository.cancelAnswer = (_) => const Result.failure(
        Failure.validation(message: OtErrorCode.tokenAlreadyDecided),
      );
      serve(waiting(status: OtStatus.approved));

      await tester.tap(button('ຍົກເລີກ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ຍົກເລີກ').last);
      await tester.pumpAndSettle();

      expect(find.text(lo.otAlreadyDecided), findsOneWidget);
      expect(button('ຍົກເລີກ'), findsNothing);
      expect(find.text(lo.otAskApproverToChange), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('edit', () {
    testWidgets('Edit opens the form filled in, with the note; Save goes '
        'back to the request with its new times, and "Saved"', (tester) async {
      serve(waiting());
      await openRequest(tester, locale: 'lo');

      await tester.tap(button('ແກ້ໄຂ'));
      await tester.pumpAndSettle();

      expect(find.byType(OtAskPage), findsOneWidget);
      expect(find.text('ເມື່ອບັນທຶກ, ຄຳຂໍຈະເລີ່ມອະນຸມັດໃໝ່ຕັ້ງແຕ່ຕົ້ນ.'), findsOneWidget);
      expect(find.text('14/11/2026'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('Stock count'), findsOneWidget);
      expect(find.text(lo.otSaveAction), findsOneWidget);

      final page = tester.widget<OtAskPage>(find.byType(OtAskPage));
      ProviderScope.containerOf(tester.element(find.byType(OtAskPage)))
          .read(otAskNotifierProvider(page.editing).notifier)
        ..setStart(19, 0)
        ..setEnd(21, 0);
      await tester.pump();
      await tester.tap(find.text(lo.otSaveAction));
      await tester.pumpAndSettle();

      expect(repository.edits.single.id, 'ot-7');
      expect(find.byType(OtAskPage), findsNothing);
      expect(find.byType(OtRequestDetailPage), findsOneWidget);
      expect(find.text('19:00–21:00'), findsOneWidget);
      expect(find.text('ບັນທຶກແລ້ວ'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('her head approved meanwhile: Save shows OT_ALREADY_DECIDED in '
        'Lao, and the request page reloads without the buttons', (
      tester,
    ) async {
      serve(waiting());
      await openRequest(tester, locale: 'lo');
      await tester.tap(button('ແກ້ໄຂ'));
      await tester.pumpAndSettle();

      repository.editAnswer = (_, _) => const Result.failure(
        Failure.validation(message: OtErrorCode.tokenAlreadyDecided),
      );
      serve(
        waiting(
          steps: [step(1, OtStepStatus.approved), step(2, OtStepStatus.pending)],
        ),
      );
      await tester.tap(find.text(lo.otSaveAction));
      await tester.pumpAndSettle();

      expect(find.text(lo.otAlreadyDecided), findsOneWidget);
      expect(find.byType(OtAskPage), findsNothing);
      expect(button('ແກ້ໄຂ'), findsNothing);
      expect(button('ຍົກເລີກ'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('an overlap on Save stays on the form, with the Lao text', (
      tester,
    ) async {
      serve(waiting());
      await openRequest(tester, locale: 'lo');
      await tester.tap(button('ແກ້ໄຂ'));
      await tester.pumpAndSettle();
      repository.editAnswer = (_, _) => const Result.failure(
        Failure.validation(message: OtErrorCode.tokenOverlapsShift),
      );

      await tester.tap(find.text(lo.otSaveAction));
      await tester.pumpAndSettle();

      expect(find.byType(OtAskPage), findsOneWidget);
      expect(find.text(lo.otOverlapsShift), findsOneWidget);
    });
  });

  group('the edit route', () {
    testWidgets('a double tap on Edit opens one form, and Save sends once', (
      tester,
    ) async {
      serve(waiting());
      await openRequest(tester);

      await tester.tap(button(en.otEditAction));
      await tester.tap(button(en.otEditAction), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(OtAskPage, skipOffstage: false), findsOneWidget);
      await tester.tap(find.text(en.otSaveAction));
      await tester.pumpAndSettle();

      expect(repository.edits, hasLength(1));
      expect(find.byType(OtAskPage, skipOffstage: false), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    Future<void> openLink(WidgetTester tester, String location) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.myRequestsAnswer = (call) =>
          const Result.success(OtPage(items: [], page: 1, totalPages: 1));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            otRepositoryProvider.overrideWithValue(repository),
            profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
            otOwnEmployeeIdProvider.overrideWithValue('emp-noy'),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: location,
              routes: overtimeRoutes,
            ),
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a link to edit a request that is gone: "not available", '
        'and the list; no endless spinner', (tester) async {
      repository.requestAnswer = (_) => const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );

      await openLink(tester, AppRoutes.otRequestEditOf('ot-7'));

      expect(find.text(en.otRequestGone), findsOneWidget);
      expect(find.byType(OtAskPage), findsNothing);
      expect(find.byType(OtRequestDetailPage), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a link to edit an approved request shows the request, not '
        'a form the server would refuse', (tester) async {
      serve(waiting(status: OtStatus.approved));

      await openLink(tester, AppRoutes.otRequestEditOf('ot-7'));

      expect(find.byType(OtAskPage), findsNothing);
      expect(find.byType(OtRequestDetailPage), findsOneWidget);
      expect(find.text(en.otAskApproverToChange), findsOneWidget);
    });

    testWidgets('a link to edit my waiting request opens the form', (
      tester,
    ) async {
      serve(waiting());

      await openLink(tester, AppRoutes.otRequestEditOf('ot-7'));

      expect(find.byType(OtAskPage), findsOneWidget);
      expect(find.text('Stock count'), findsOneWidget);
    });
  });

  group('a head cancels an OT they approved (#49)', () {
    testWidgets('the toast says the OT is cancelled, not "the OT request" '
        '(that is the employee\'s own cancel, #32)', (tester) async {
      final startsAt = DateTime(2026, 11, 20, 18);
      serve(
        OtRequest(
          id: 'ot-7',
          employeeId: 'emp-noy',
          startTime: '18:00',
          endTime: '20:00',
          startsAt: startsAt,
          status: OtStatus.approved,
          steps: const [
            OtStep(
              id: 's1',
              stepNo: 1,
              role: OtStepRole.deptHead,
              approverId: 'emp-bounmy',
              status: OtStepStatus.approved,
            ),
          ],
        ),
      );

      await openRequest(
        tester,
        locale: 'lo',
        me: 'emp-bounmy',
        extra: [
          signedInAs(approverTestUser(employeeId: 'emp-bounmy')),
          clockProvider.overrideWithValue(
            () => startsAt.subtract(const Duration(hours: 2)),
          ),
        ],
      );
      await tester.tap(button(lo.otCancelApprovedAction));
      await tester.pumpAndSettle();
      expect(find.text(lo.otCancelApprovedConfirm), findsOneWidget);
      await tester.tap(find.text(lo.otCancelApprovedAction).last);
      await tester.pumpAndSettle();

      expect(repository.cancels, ['ot-7']);
      expect(find.text('ຍົກເລີກໂອທີແລ້ວ'), findsOneWidget);
      expect(find.text('ຍົກເລີກຄຳຂໍໂອທີແລ້ວ'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
