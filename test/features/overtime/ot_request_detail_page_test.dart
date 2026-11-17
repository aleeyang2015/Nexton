import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_piece.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_list_page.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_request_detail_page.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/overtime_test_doubles.dart';

/// One OT request's page, opened by its id: what it shows for each field,
/// and what happens when there is no request to show.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();
  late FakeOtRepository repository;

  setUp(() => repository = FakeOtRepository());

  OtStep step(
    int no,
    OtStepRole role,
    OtStepStatus status, {
    String? approver,
    String? note,
  }) => OtStep(
    id: 's$no',
    stepNo: no,
    role: role,
    approverName: approver,
    status: status,
    note: note,
    actedAt: status == OtStepStatus.approved
        ? DateTime(2026, 11, 8, 9)
        : null,
  );

  /// Noy's OT of Saturday 7 November, 08:00–12:00.
  OtRequest ot({
    OtStatus status = OtStatus.pending,
    String? reason = 'Kitchen prep',
    List<OtStep>? steps,
    List<OtPiece> pieces = const [],
    String? agreementNote,
    bool hrOnly = false,
    bool didNotCome = false,
    DateTime? paidByHandAt,
    String? announcementId,
  }) => OtRequest(
    id: 'ot-7',
    employeeId: 'emp-noy',
    workDate: DateTime(2026, 11, 7),
    startTime: '08:00',
    endTime: '12:00',
    reason: reason,
    status: status,
    steps:
        steps ??
        [
          step(1, OtStepRole.deptHead, OtStepStatus.approved),
          step(2, OtStepRole.hr, OtStepStatus.pending),
        ],
    pieces: pieces,
    agreementNote: agreementNote,
    hrOnly: hrOnly,
    didNotCome: didNotCome,
    paidByHandAt: paidByHandAt,
    announcementId: announcementId,
  );

  void serve(OtRequest request) =>
      repository.requestAnswer = (_) => Result.success(request);

  /// Opens the page from the OT list, so going back has somewhere to go.
  Future<void> openPage(
    WidgetTester tester, {
    String locale = 'en',
    String id = 'ot-7',
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: AppRoutes.overtime,
      routes: overtimeRoutes,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [otRepositoryProvider.overrideWithValue(repository)],
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
    router.push(AppRoutes.otRequest(id));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  group('header', () {
    testWidgets('date, window and status', (tester) async {
      serve(ot(status: OtStatus.approved));

      await openPage(tester, locale: 'lo');

      expect(find.text('07/11/2026'), findsOneWidget);
      expect(find.text('08:00–12:00'), findsOneWidget);
      expect(find.text('ອະນຸມັດແລ້ວ'), findsOneWidget);
    });

    testWidgets('waiting for HR: ລໍຖ້າ: ຝ່າຍບຸກຄະລາກອນ', (tester) async {
      serve(ot());

      await openPage(tester, locale: 'lo');

      expect(find.text('ລໍຖ້າ: ຝ່າຍບຸກຄະລາກອນ'), findsOneWidget);
    });

    testWidgets('waiting for the head: ລໍຖ້າ: ຫົວໜ້າ', (tester) async {
      serve(
        ot(
          steps: [
            step(1, OtStepRole.deptHead, OtStepStatus.pending),
            step(2, OtStepRole.hr, OtStepStatus.waiting),
          ],
        ),
      );

      await openPage(tester, locale: 'lo');

      expect(find.text('ລໍຖ້າ: ຫົວໜ້າ'), findsOneWidget);
    });

    testWidgets('no "waiting for" once decided', (tester) async {
      serve(ot(status: OtStatus.approved));

      await openPage(tester);

      expect(find.textContaining('Waiting for'), findsNothing);
    });
  });

  group('reason and steps', () {
    testWidgets('no reason shows —', (tester) async {
      serve(ot(reason: null));

      await openPage(tester);

      expect(find.text(en.leaveRequestReasonLabel), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('the timeline names each role; a step with no approver shows '
        'its role', (tester) async {
      serve(ot());

      await openPage(tester, locale: 'lo');

      expect(find.text(lo.leaveStepSubmitted), findsOneWidget);
      expect(find.text(lo.leaveStepDeptHead), findsOneWidget);
      expect(find.text(lo.leaveStepHr), findsWidgets);
    });

    testWidgets('a step\'s note shows under the timeline, with its role', (
      tester,
    ) async {
      serve(
        ot(
          steps: [
            step(
              1,
              OtStepRole.deptHead,
              OtStepStatus.approved,
              note: 'Fine by me',
            ),
            step(2, OtStepRole.hr, OtStepStatus.pending),
          ],
        ),
      );

      await openPage(tester);

      expect(find.text('${en.leaveApproverNoteLabel}: Fine by me'), findsOneWidget);
    });

    testWidgets('who approved shows under the timeline: role • name', (
      tester,
    ) async {
      serve(
        ot(
          status: OtStatus.approved,
          steps: [
            step(
              1,
              OtStepRole.deptHead,
              OtStepStatus.approved,
              approver: 'Somchai K.',
            ),
            step(2, OtStepRole.hr, OtStepStatus.approved, approver: 'Noy HR'),
          ],
        ),
      );

      await openPage(tester);

      expect(find.text('${en.leaveStepDeptHead} • Somchai K.'), findsOneWidget);
      expect(find.text('${en.leaveStepHr} • Noy HR'), findsOneWidget);
    });

    testWidgets('a cancelled request ends the timeline in Cancelled', (
      tester,
    ) async {
      serve(ot(status: OtStatus.cancelled));

      await openPage(tester);

      // The pill and the timeline's end.
      expect(find.text(en.leaveStatusCancelled), findsNWidgets(2));
    });
  });

  group('pieces', () {
    testWidgets('approved: each piece with its window and pay', (tester) async {
      serve(
        ot(
          status: OtStatus.approved,
          pieces: [
            OtPiece(
              id: 'p1',
              pieceNo: 1,
              startsAt: DateTime(2026, 11, 7, 8),
              endsAt: DateTime(2026, 11, 7, 12),
              payType: OtPayType.percent,
              payValue: 200,
            ),
            OtPiece(
              id: 'p2',
              pieceNo: 2,
              startsAt: DateTime(2026, 11, 7, 12),
              endsAt: DateTime(2026, 11, 7, 13),
              payType: OtPayType.fixedPerHour,
              payValue: 20000,
            ),
          ],
        ),
      );

      await openPage(tester, locale: 'lo');

      expect(find.text('08:00–12:00 · 200%'), findsOneWidget);
      expect(find.text('12:00–13:00 · 20,000 ກີບ/ຊມ'), findsOneWidget);
      expect(find.text(lo.otPiecesSetOnApproval), findsNothing);
    });

    testWidgets('none yet while pending: HR sets the time and pay', (
      tester,
    ) async {
      serve(ot());

      await openPage(tester, locale: 'lo');

      expect(
        find.text('ຝ່າຍບຸກຄະລາກອນຈະກຳນົດເວລາ ແລະ ຄ່າຈ້າງ ຕອນອະນຸມັດ'),
        findsOneWidget,
      );
    });

    testWidgets('none on a rejected request: nothing said about pieces', (
      tester,
    ) async {
      serve(ot(status: OtStatus.rejected));

      await openPage(tester);

      expect(find.text(en.otPiecesSetOnApproval), findsNothing);
    });
  });

  group('notes, each only when its field is set', () {
    testWidgets('none on a plain request', (tester) async {
      serve(ot());

      await openPage(tester);

      for (final text in [
        en.otNoteDidNotCome,
        en.otNotePaidByHand,
        en.otNoteHrOnly,
        en.otNoteFromPost,
        en.otAgreementNoteLabel,
        en.otPaidOnPayslip,
      ]) {
        expect(find.text(text), findsNothing, reason: text);
      }
    });

    testWidgets('did not come, paid in cash, a leave day, from an HR post, '
        'HR\'s note', (tester) async {
      serve(
        ot(
          status: OtStatus.approved,
          didNotCome: true,
          paidByHandAt: DateTime(2026, 11, 9, 10),
          hrOnly: true,
          announcementId: 'post-1',
          agreementNote: 'Double pay agreed',
        ),
      );

      await openPage(tester, locale: 'lo');

      expect(find.text('ບໍ່ໄດ້ມາ: ບໍ່ມີເວລາສະແກນໃນຊ່ວງໂອທີ'), findsOneWidget);
      expect(
        find.text('ຝ່າຍບຸກຄະລາກອນຈ່າຍເປັນເງິນສົດແລ້ວ — ບໍ່ຢູ່ໃນໃບເງິນເດືອນ'),
        findsOneWidget,
      );
      expect(
        find.text('ວັນນີ້ເປັນວັນລາ: ຝ່າຍບຸກຄະລາກອນເປັນຜູ້ອະນຸມັດ'),
        findsOneWidget,
      );
      expect(find.text('ຈາກປະກາດຂອງຝ່າຍບຸກຄະລາກອນ'), findsOneWidget);
      expect(find.text('ໝາຍເຫດຈາກຝ່າຍບຸກຄະລາກອນ'), findsOneWidget);
      expect(find.text('Double pay agreed'), findsOneWidget);
    });

    testWidgets('approved: where the money is; never an amount', (
      tester,
    ) async {
      serve(ot(status: OtStatus.approved));

      await openPage(tester, locale: 'lo');

      expect(
        find.text('ຊົ່ວໂມງ ແລະ ເງິນທີ່ຈ່າຍຈິງ ຢູ່ໃນໃບເງິນເດືອນ'),
        findsOneWidget,
      );
      expect(find.textContaining('₭'), findsNothing);
    });
  });

  group('when there is no request to show', () {
    testWidgets('404: the toast, back to the list, which refreshes', (
      tester,
    ) async {
      repository.requestAnswer = (_) => const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );
      repository.myRequestsAnswer = (call) => const Result.success(
        OtPage(items: [], page: 1, totalPages: 1),
      );

      await openPage(tester, locale: 'lo', id: 'someone-elses');

      expect(find.text('ຄຳຂໍໂອທີນີ້ບໍ່ມີແລ້ວ'), findsOneWidget);
      expect(find.byType(OtRequestDetailPage), findsNothing);
      expect(find.byType(OtListPage), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('no signal: "could not load OT" with Retry, and Retry loads',
        (tester) async {
      repository.requestAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));

      await openPage(tester, locale: 'lo');
      expect(find.text('ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໂອທີໄດ້.'), findsOneWidget);

      serve(ot());
      await tester.tap(find.text(lo.retry));
      await tester.pumpAndSettle();

      expect(find.text('07/11/2026'), findsOneWidget);
    });

    testWidgets('no employee linked: #4\'s text, no Retry', (tester) async {
      repository.requestAnswer = (_) => const Result.failure(
        Failure.validation(
          message: 'employee not found',
          code: ApiErrorCodes.employeeNotFound,
        ),
      );

      await openPage(tester, locale: 'lo');

      expect(find.text(lo.ruleEmployeeNotFound), findsOneWidget);
      expect(find.text(lo.retry), findsNothing);
    });
  });

  testWidgets('a 404 with nothing underneath (opened as a push would) goes to '
      'the OT list', (tester) async {
    repository.requestAnswer = (_) => const Result.failure(
      Failure.network(message: 'not found', statusCode: 404),
    );
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [otRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.otRequest('ot-x'),
            routes: overtimeRoutes,
          ),
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OtListPage), findsOneWidget);
    expect(find.byType(OtRequestDetailPage), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Retry after a failed load shows the spinner while it loads', (
    tester,
  ) async {
    repository.requestAnswer = (_) =>
        const Result.failure(Failure.network(message: 'offline'));
    await openPage(tester);

    final hold = Completer<void>();
    repository
      ..holdRequest = hold
      ..requestAnswer = (_) => Result.success(ot());
    await tester.tap(find.text(en.retry));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(en.retry), findsNothing);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.text('07/11/2026'), findsOneWidget);
  });

  testWidgets('opened from the list, its row shows at once while the page '
      'loads its own copy', (tester) async {
    repository.myRequestsAnswer = (call) => Result.success(
      OtPage(items: [ot()], page: 1, totalPages: 1),
    );
    final hold = Completer<void>();
    repository
      ..holdRequest = hold
      ..requestAnswer = (_) => Result.success(ot(status: OtStatus.approved));

    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [otRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.overtime,
            routes: overtimeRoutes,
          ),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('07/11/2026'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OtRequestDetailPage), findsOneWidget);
    expect(find.text(en.leaveStatusPending), findsWidgets);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.text(en.leaveStatusApproved), findsWidgets);
  });
}
