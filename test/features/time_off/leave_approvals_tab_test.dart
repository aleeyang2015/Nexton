import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approvals_tab.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/leave_test_doubles.dart';

/// What the approvals tab tells a department head when a decision is
/// refused, and what is left on screen afterwards.
void main() {
  final en = AppLocalizationsEn();
  late FakeLeaveRepository repository;

  setUp(() {
    repository = FakeLeaveRepository()
      ..pendingApprovalsResult = Result.success([pendingApproval()]);
  });

  Future<void> pumpTab(WidgetTester tester, {String locale = 'en'}) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          // Toasts are raised through this key, as in the App.
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const Scaffold(body: LeaveApprovalsTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Taps Approve with the server set to answer [failure], and lets the
  /// reload and the toast land.
  Future<void> approveRefusedWith(
    WidgetTester tester,
    Failure failure, {
    String approveLabel = 'Approve',
  }) async {
    repository.approveResult = Result.failure(failure);
    await tester.tap(find.text(approveLabel));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the employee cancelled it meanwhile: "no longer waiting", and '
      'the card is gone', (tester) async {
    await pumpTab(tester);
    expect(find.text('Approve'), findsOneWidget);

    // The reload after the refusal no longer has it.
    repository.pendingApprovalsResult = const Result.success([]);
    await approveRefusedWith(
      tester,
      const Failure.validation(message: 'leaveInvalidStatus'),
    );

    expect(find.text(en.leaveApprovalNoLongerWaiting), findsOneWidget);
    // Not the wording an owner gets on an edit.
    expect(find.text(en.leaveInvalidStatus), findsNothing);
    expect(find.text('Approve'), findsNothing);
  });

  final reloadedText = {
    'leaveStepChanged': en.leaveStepChanged,
    'leaveChanged': en.leaveChanged,
    'leaveNotApprover': en.leaveNotApprover,
    'leaveRequestGone': en.leaveRequestGone,
  };

  for (final MapEntry(key: token, value: text) in reloadedText.entries) {
    testWidgets('$token shows its own text and reloads the lists', (
      tester,
    ) async {
      await pumpTab(tester);
      final before = repository.myApprovalsCalls.length;

      await approveRefusedWith(tester, Failure.validation(message: token));

      expect(find.text(text), findsOneWidget);
      expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
      expect(repository.myApprovalsCalls, hasLength(before + 2));
    });
  }

  testWidgets('a refusal with a code the App does not know shows the '
      'server\'s message, not "could not decide", and the card stays', (
    tester,
  ) async {
    await pumpTab(tester);
    final before = repository.myApprovalsCalls.length;

    await approveRefusedWith(
      tester,
      const Failure.validation(
        message: 'A leave request can run at most 1 year',
        code: 'LEAVE_SPAN_TOO_LONG',
      ),
    );

    expect(find.text('A leave request can run at most 1 year'), findsOneWidget);
    expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
    expect(find.text('Approve'), findsOneWidget);
    expect(repository.myApprovalsCalls, hasLength(before));
  });

  testWidgets('no signal shows the network text, and the card stays', (
    tester,
  ) async {
    await pumpTab(tester);

    await approveRefusedWith(tester, const Failure.network(message: 'offline'));

    expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
  });

  testWidgets('on a slow network the reason is still shown, though the '
      'reload has taken the card away by then', (tester) async {
    final slow = _SlowApprovals()
      ..pendingApprovalsResult = Result.success([pendingApproval()]);
    repository = slow;
    await pumpTab(tester);
    expect(find.text('Approve'), findsOneWidget);

    slow
      ..delay = const Duration(milliseconds: 300)
      ..pendingApprovalsResult = const Result.success([])
      ..approveResult = const Result.failure(
        Failure.validation(message: 'leaveInvalidStatus'),
      );
    await tester.tap(find.text('Approve'));
    // The refusal is in, the reload is under way: the card is gone, and
    // nothing has been said yet.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Approve'), findsNothing);
    expect(find.text(en.leaveApprovalNoLongerWaiting), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text(en.leaveApprovalNoLongerWaiting), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
  });

  testWidgets('a decision that goes through shows no refusal', (tester) async {
    await pumpTab(tester);

    await tester.tap(find.text('Approve'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('in Lao the refusal is in Lao', (tester) async {
    final lo = AppLocalizationsLo();
    await pumpTab(tester, locale: 'lo');

    await approveRefusedWith(
      tester,
      const Failure.validation(message: 'leaveInvalidStatus'),
      approveLabel: lo.leaveApprovalApproveAction,
    );

    expect(
      find.text('ຄຳຮ້ອງນີ້ບໍ່ໄດ້ລໍຖ້າການອະນຸມັດແລ້ວ (ມີຄົນຕັດສິນແລ້ວ ຫຼື ຖືກຍົກເລີກ).'),
      findsOneWidget,
    );
  });
}

/// Answers the approvals lists after [delay], as a real network does, so a
/// frame is drawn while the lists are loading.
class _SlowApprovals extends FakeLeaveRepository {
  Duration delay = Duration.zero;

  @override
  FutureResult<List<LeaveRequest>> myApprovals({LeaveStatus? status}) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return super.myApprovals(status: status);
  }
}
