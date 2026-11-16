import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_balance.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_attachment_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_notifier.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_filter_chip.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_request_form.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  late FakeLeaveRepository repository;
  late ProviderContainer container;

  /// 20 December 2026: next January is next year.
  final now = DateTime(2026, 12, 20);
  final en = lookupAppLocalizations(const Locale('en'));

  final annual = sampleLeaveType();
  final sick = sampleLeaveType(
    id: 'lt-sick',
    code: 'sick',
    name: 'Sick Leave',
    nameLo: 'ລາປ່ວຍ',
  );
  final switchedOff = sampleLeaveType(
    id: 'lt-old',
    code: 'annual-2025',
    name: 'Annual leave 2025',
    nameLo: 'ລາພັກປະຈຳປີ 2025',
    isActive: false,
  );

  setUp(() {
    repository = FakeLeaveRepository()
      ..leaveTypesResult = Result.success([switchedOff, annual, sick])
      ..balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 6),
      ]);
    container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        leaveAttachmentNotifierProvider.overrideWith(
          () => FixedLeaveAttachment(null),
        ),
      ],
    );
    addTearDown(() async {
      await Future<void>.delayed(Duration.zero);
      container.dispose();
    });
  });

  Future<void> pumpForm(WidgetTester tester, {String? requestId}) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: LeaveRequestForm(requestId: requestId)),
        ),
      ),
    );
    // Types and balances load, then the default type is applied a frame later.
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  LeaveRequestFormNotifier form([String? id]) =>
      container.read(leaveRequestFormNotifierProvider(id).notifier);

  List<String> chipLabels(WidgetTester tester) => [
    for (final chip in tester.widgetList<LeaveFilterChip>(
      find.byType(LeaveFilterChip),
    ))
      chip.label,
  ];

  bool submitEnabled(WidgetTester tester, String label) =>
      tester
          .widget<ElevatedButton>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(ElevatedButton),
            ),
          )
          .onPressed !=
      null;

  /// A pending request on [type] asking for the 18th and 19th of November.
  LeaveRequest pendingOn(LeaveType type) => sampleLeaveRequest(
    id: 'req-7',
    leaveType: type,
    requestDays: [DateTime(2026, 11, 18), DateTime(2026, 11, 19)],
    reason: 'Trip',
  );

  group('leave types', () {
    testWidgets('a type HR switched off is not offered', (tester) async {
      await pumpForm(tester);

      expect(chipLabels(tester), ['Annual Leave', 'Sick Leave']);
      expect(find.text('Annual leave 2025'), findsNothing);
    });

    testWidgets('the default is the first type that is switched on, not the '
        'first in the list', (tester) async {
      await pumpForm(tester);

      expect(
        container.read(leaveRequestFormNotifierProvider(null)).leaveTypeId,
        'lt-annual',
      );
    });

    testWidgets('editing a request on a switched-off type still offers that '
        'type, so the request can be saved', (tester) async {
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(leaveTypeId: 'lt-old', remainingDays: 6),
      ]);
      form('req-7').seed(pendingOn(switchedOff));

      await pumpForm(tester, requestId: 'req-7');

      // The chips sit in a sideways list that builds only what fits, so the
      // ones on screen are what is checked.
      expect(chipLabels(tester).first, 'Annual leave 2025');
      expect(chipLabels(tester), contains('Annual Leave'));
      expect(submitEnabled(tester, en.leaveEditAction), isTrue);
    });

    testWidgets('the request\'s own type stays offered after the user picks '
        'another one', (tester) async {
      form('req-7').seed(pendingOn(switchedOff));
      await pumpForm(tester, requestId: 'req-7');

      form('req-7').setLeaveType('lt-annual');
      await tester.pump();

      expect(chipLabels(tester), contains('Annual leave 2025'));
    });

    testWidgets('asks for all the types, 100 a page', (tester) async {
      await pumpForm(tester);

      expect(repository.leaveTypesCalls, 1);
    });
  });

  group('the balance card', () {
    testWidgets('shows this year\'s balance before any day is picked', (
      tester,
    ) async {
      await pumpForm(tester);

      expect(find.text(en.leaveYearLabel(2026)), findsOneWidget);
      expect(find.text('6 days'), findsOneWidget);
      expect(repository.balancesCalls, [2026]);
    });

    testWidgets('follows the year of the first picked day: a day next '
        'January shows next year\'s balance', (tester) async {
      repository.balancesByYear[2027] = Result.success([
        sampleLeaveBalance(year: 2027, remainingDays: 12, usedDays: 0),
      ]);
      await pumpForm(tester);

      form().setDates([DateTime(2027, 1, 6), DateTime(2027, 1, 5)]);
      await tester.pump();
      await tester.pump();

      expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
      expect(find.text('12 days'), findsOneWidget);
      expect(find.text('6 days'), findsNothing);
      expect(repository.balancesCalls, contains(2027));
    });

    testWidgets('a leave across the new year is checked against its first '
        'year', (tester) async {
      await pumpForm(tester);

      form().setDates([DateTime(2026, 12, 31), DateTime(2027, 1, 2)]);
      await tester.pump();
      await tester.pump();

      expect(find.text(en.leaveYearLabel(2026)), findsOneWidget);
      expect(repository.balancesCalls, isNot(contains(2027)));
    });

    testWidgets('no balance for that year shows 0 and blocks', (tester) async {
      // HR has not given a 2027 balance yet: no row at all.
      repository.balancesByYear[2027] = const Result.success(<LeaveBalance>[]);
      await pumpForm(tester);

      form().setDates([DateTime(2027, 1, 5)]);
      await tester.pump();
      await tester.pump();

      expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
      expect(find.text('0 days'), findsOneWidget);
      expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
    });

    testWidgets('a type that may go negative is not blocked by having no '
        'balance', (tester) async {
      repository
        ..leaveTypesResult = Result.success([
          sampleLeaveType(allowNegativeBalance: true),
        ])
        ..balancesByYear[2027] = const Result.success(<LeaveBalance>[]);
      await pumpForm(tester);

      form().setDates([DateTime(2027, 1, 5)]);
      await tester.pump();
      await tester.pump();

      expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
    });

    testWidgets('shows half days as they are: 7.5, not 8', (tester) async {
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(usedDays: 4.5, remainingDays: 7.5),
      ]);

      await pumpForm(tester);

      expect(find.text('7.5 days'), findsOneWidget);
      expect(find.text('Used 4.5 days'), findsOneWidget);
    });
  });

  group('the balance check', () {
    testWidgets('a new request for more days than are left is blocked', (
      tester,
    ) async {
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 1),
      ]);
      await pumpForm(tester);

      form().setDates([DateTime(2026, 12, 22), DateTime(2026, 12, 23)]);
      await tester.pump();

      expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
    });

    testWidgets('an edit that does not ask for more days is allowed, even '
        'over the balance: Bee fixes her reason', (tester) async {
      // She asked for 2 while she had 5; HR has since cut her to 1 left.
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 1),
      ]);
      form('req-7').seed(pendingOn(annual));
      await pumpForm(tester, requestId: 'req-7');

      form('req-7').setReason('Family trip');
      await tester.pump();

      expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
      expect(submitEnabled(tester, en.leaveEditAction), isTrue);
    });

    testWidgets('an edit to fewer days is allowed too', (tester) async {
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 0),
      ]);
      form('req-7').seed(pendingOn(annual));
      await pumpForm(tester, requestId: 'req-7');

      form('req-7').setDates([DateTime(2026, 11, 18)]);
      await tester.pump();

      expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
      expect(submitEnabled(tester, en.leaveEditAction), isTrue);
    });

    testWidgets('an edit that asks for more days, over the balance, is '
        'blocked', (tester) async {
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 1),
      ]);
      form('req-7').seed(pendingOn(annual));
      await pumpForm(tester, requestId: 'req-7');

      form('req-7').setDates([
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 20),
      ]);
      await tester.pump();

      expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
      expect(submitEnabled(tester, en.leaveEditAction), isFalse);
    });

    testWidgets('an edit that asks for more days the balance can cover is '
        'allowed', (tester) async {
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 5),
      ]);
      form('req-7').seed(pendingOn(annual));
      await pumpForm(tester, requestId: 'req-7');

      form('req-7').setDates([
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 20),
      ]);
      await tester.pump();

      expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
      expect(submitEnabled(tester, en.leaveEditAction), isTrue);
    });
  });

  group('a type with a decimal limit', () {
    testWidgets('the hint names the limit as it is: 2.5 days', (tester) async {
      repository.leaveTypesResult = Result.success([
        sampleLeaveType(maxDaysPerRequest: 2.5),
      ]);
      await pumpForm(tester);

      form().setDates([
        DateTime(2026, 12, 22),
        DateTime(2026, 12, 23),
        DateTime(2026, 12, 24),
      ]);
      await tester.pump();

      expect(find.text(en.leaveMaxDaysHint('2.5')), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
    });
  });
}
