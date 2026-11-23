import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/domain/capture_policy.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_balance.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/features/time_off/presentation/providers/company_days_off_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_history_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_state.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_filter_chip.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_request_form.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/file_capture_test_doubles.dart';
import '../../support/leave_test_doubles.dart';
import '../../support/upload_test_doubles.dart';

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

  late FakeUploads uploads;
  late FakeFileCapture capture;

  setUp(() {
    uploads = FakeUploads();
    capture = FakeFileCapture()
      ..answer = const Captured(
        LocalFile(path: '/phone/cert.jpg', name: 'cert.jpg'),
      );
    repository = FakeLeaveRepository()
      ..leaveTypesResult = Result.success([switchedOff, annual, sick])
      ..balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 6),
      ]);
    container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        uploadRepositoryProvider.overrideWithValue(uploads),
        fileCaptureProvider.overrideWithValue(capture),
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

  /// The leave-type chips on screen. The two chips that switch between a
  /// date range and separate days are the same widget and are left out.
  List<String> chipLabels(WidgetTester tester) => [
    for (final chip in tester.widgetList<LeaveFilterChip>(
      find.byType(LeaveFilterChip),
    ))
      if (chip.label != en.leaveModeRange &&
          chip.label != en.leaveModeSeparateDays)
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

    testWidgets('every type switched off: the form says there is none, and '
        'cannot send', (tester) async {
      repository.leaveTypesResult = Result.success([switchedOff]);

      await pumpForm(tester);

      expect(chipLabels(tester), isEmpty);
      expect(find.text(en.leaveTypeSearchEmpty), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
    });

    testWidgets('a new request left on a type that is switched off goes back '
        'to the first type on offer', (tester) async {
      await pumpForm(tester);

      // The form finds itself on a type that is not on offer, as it would if
      // HR switched it off while the form was open.
      form().setLeaveType('lt-old');
      await tester.pump();
      await tester.pump();

      expect(
        container.read(leaveRequestFormNotifierProvider(null)).leaveTypeId,
        'lt-annual',
      );
    });

    group('the server refuses the type as switched off or gone', () {
      /// A new request on Sick Leave with a day and a reason, sent and
      /// refused; the leave types then answer [typesAfter].
      Future<void> refused(
        WidgetTester tester, {
        required Result<List<LeaveType>> typesAfter,
      }) async {
        repository.balancesByYear[2026] = Result.success([
          sampleLeaveBalance(remainingDays: 6),
          sampleLeaveBalance(
            leaveTypeId: 'lt-sick',
            leaveTypeName: 'Sick Leave',
            remainingDays: 6,
          ),
        ]);
        await pumpForm(tester);
        form()
          ..setLeaveType('lt-sick')
          ..setDates([DateTime(2026, 12, 22)])
          ..setReason('Fever');
        await tester.pump();
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);

        repository
          ..submitResult = const Result.failure(
            Failure.validation(message: 'leaveRuleTypeNotFound'),
          )
          ..leaveTypesResult = typesAfter;
        await tester.runAsync(() => form().submit());
        await tester.pump();
        await tester.pump();
        await tester.pump();
      }

      LeaveRequestFormState state() =>
          container.read(leaveRequestFormNotifierProvider(null));

      testWidgets('the form does not pick another type for the user: '
          'nothing can be sent until they pick', (tester) async {
        await refused(tester, typesAfter: Result.success([annual]));

        // The list is the new one, and the form did not move to it by itself.
        expect(chipLabels(tester), ['Annual Leave']);
        expect(state().leaveTypeId, 'lt-sick');
        expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
        // What was typed is still there.
        expect(state().reason, 'Fever');
        expect(state().dates, [DateTime(2026, 12, 22)]);

        await tester.tap(find.text('Annual Leave'));
        await tester.pump();

        expect(state().leaveTypeId, 'lt-annual');
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });

      testWidgets('the type is still in the list: it has to be picked again '
          'all the same', (tester) async {
        await refused(tester, typesAfter: Result.success([annual, sick]));

        expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
        expect(
          tester
              .widgetList<LeaveFilterChip>(find.byType(LeaveFilterChip))
              .where((chip) => chip.label == 'Sick Leave')
              .single
              .selected,
          isFalse,
        );

        await tester.tap(find.text('Sick Leave'));
        await tester.pump();

        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });

      testWidgets('the reload fails: the types stay on offer, not "could not '
          'load"', (tester) async {
        await refused(
          tester,
          typesAfter: const Result.failure(
            Failure.network(message: 'No internet connection'),
          ),
        );

        expect(chipLabels(tester), ['Annual Leave', 'Sick Leave']);
        expect(find.text(en.leaveTypeLoadFailed), findsNothing);
        expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);

        await tester.tap(find.text('Annual Leave'));
        await tester.pump();

        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });
    });

    testWidgets('the type list loads once for the form', (tester) async {
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

    testWidgets('while a newly picked year\'s balance is on its way the form '
        'waits: a dash, and no sending', (tester) async {
      repository.balancesByYear[2027] = Result.success([
        sampleLeaveBalance(year: 2027, remainingDays: 12, usedDays: 0),
      ]);
      await pumpForm(tester);

      form().setDates([DateTime(2027, 1, 5)]);
      // One frame: the form now watches 2027, which has not answered yet.
      await tester.pump();

      expect(find.text('-'), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);

      await tester.pump();

      expect(find.text('12 days'), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
    });

    testWidgets('a balance that failed to load does not block: the server '
        'has the last word', (tester) async {
      repository.balancesByYear[2026] = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await pumpForm(tester);

      form().setDates([DateTime(2026, 12, 22)]);
      await tester.pump();

      expect(find.text('-'), findsOneWidget);
      expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
    });

    group('a leave across the new year: each day is charged to its own '
        'year (Nexton-Backend#193)', () {
      /// 30 and 31 December 2026, then 4 and 5 January 2027: 2 days in each
      /// year.
      final acrossNewYear = [
        DateTime(2026, 12, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 4),
        DateTime(2027, 1, 5),
      ];

      testWidgets('both years\' balances are read', (tester) async {
        repository.balancesByYear[2027] = Result.success([
          sampleLeaveBalance(year: 2027, remainingDays: 12, usedDays: 0),
        ]);
        await pumpForm(tester);

        form().setDates(acrossNewYear);
        await tester.pump();
        await tester.pump();

        expect(repository.balancesCalls, containsAll([2026, 2027]));
      });

      testWidgets('enough days in both years: not blocked, and the card '
          'shows the first year', (tester) async {
        repository.balancesByYear[2027] = Result.success([
          sampleLeaveBalance(year: 2027, remainingDays: 12, usedDays: 0),
        ]);
        await pumpForm(tester);

        form().setDates(acrossNewYear);
        await tester.pump();
        await tester.pump();

        expect(find.text(en.leaveYearLabel(2026)), findsOneWidget);
        expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });

      testWidgets('4 days with 6 left this year, but none given for next '
          'year: blocked, and the card shows next year\'s 0', (tester) async {
        // The first year alone could pay for all 4; the 2 January days are
        // charged to 2027, where HR has given nothing yet.
        repository.balancesByYear[2027] = const Result.success(
          <LeaveBalance>[],
        );
        await pumpForm(tester);

        form().setDates(acrossNewYear);
        await tester.pump();
        await tester.pump();

        expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
        expect(find.text('0 days'), findsOneWidget);
        expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
        expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
      });

      testWidgets('not enough this year, plenty next year: blocked, and the '
          'card shows this year', (tester) async {
        repository
          ..balancesByYear[2026] = Result.success([
            sampleLeaveBalance(remainingDays: 1),
          ])
          ..balancesByYear[2027] = Result.success([
            sampleLeaveBalance(year: 2027, remainingDays: 12, usedDays: 0),
          ]);
        await pumpForm(tester);

        form().setDates(acrossNewYear);
        await tester.pump();
        await tester.pump();

        expect(find.text(en.leaveYearLabel(2026)), findsOneWidget);
        expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
        expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
      });

      testWidgets('each year is checked on its own days, not the whole '
          'count: 4 days fit with 2 left in each year', (tester) async {
        repository
          ..balancesByYear[2026] = Result.success([
            sampleLeaveBalance(remainingDays: 2),
          ])
          ..balancesByYear[2027] = Result.success([
            sampleLeaveBalance(year: 2027, remainingDays: 2, usedDays: 0),
          ]);
        await pumpForm(tester);

        form().setDates(acrossNewYear);
        await tester.pump();
        await tester.pump();

        expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });

      testWidgets('while the second year\'s balance is on its way the form '
          'waits', (tester) async {
        repository.balancesByYear[2027] = Result.success([
          sampleLeaveBalance(year: 2027, remainingDays: 12, usedDays: 0),
        ]);
        await pumpForm(tester);

        form().setDates(acrossNewYear);
        // One frame: 2027 is now watched and has not answered yet.
        await tester.pump();

        expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);

        await tester.pump();
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });

      testWidgets('the second year\'s balance failed to load: not blocked on '
          'it, the server decides', (tester) async {
        repository.balancesByYear[2027] = const Result.failure(
          Failure.network(message: 'offline'),
        );
        await pumpForm(tester);

        form().setDates(acrossNewYear);
        await tester.pump();
        await tester.pump();

        expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });
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

    testWidgets('an edit that switches to another leave type is checked '
        'against that type\'s balance, even with the same day count', (
      tester,
    ) async {
      // Annual has days; sick has none this year.
      repository.balancesByYear[2026] = Result.success([
        sampleLeaveBalance(remainingDays: 6),
      ]);
      form('req-7').seed(pendingOn(annual));
      await pumpForm(tester, requestId: 'req-7');
      expect(submitEnabled(tester, en.leaveEditAction), isTrue);

      form('req-7').setLeaveType('lt-sick');
      await tester.pump();

      expect(find.text('0 days'), findsOneWidget);
      expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
      expect(submitEnabled(tester, en.leaveEditAction), isFalse);
    });

    testWidgets('an edit that moves the days into another year is checked '
        'against that year\'s balance', (tester) async {
      repository
        ..balancesByYear[2026] = Result.success([
          sampleLeaveBalance(remainingDays: 6),
        ])
        ..balancesByYear[2027] = const Result.success(<LeaveBalance>[]);
      form('req-7').seed(pendingOn(annual));
      await pumpForm(tester, requestId: 'req-7');

      form('req-7').setDates([DateTime(2027, 1, 5), DateTime(2027, 1, 6)]);
      await tester.pump();
      await tester.pump();

      expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
      expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
      expect(submitEnabled(tester, en.leaveEditAction), isFalse);
    });

    group('the server refuses for a year the form could not check (#87)', () {
      /// 30 December to 2 January, asked for with the company's days off not
      /// loaded: the form cannot split the days by year, shows this year and
      /// leaves the count to the server. Then sent, and answered [refusal].
      Future<void> sentAndRefused(WidgetTester tester, Failure refusal) async {
        repository
          ..companyDaysOffResult = const Result.failure(
            Failure.network(message: 'offline'),
          )
          ..balancesByYear[2027] = const Result.success(<LeaveBalance>[])
          ..submitResult = Result.failure(refusal);
        await pumpForm(tester);
        form()
          ..setRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2))
          ..setReason('New year');
        await tester.pump();
        await tester.pump();
        expect(find.text(en.leaveYearLabel(2026)), findsOneWidget);
        expect(find.text('6 days'), findsOneWidget);
        expect(repository.balancesCalls, isNot(contains(2027)));
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);

        await tester.runAsync(() => form().submit());
        await tester.pump();
        await tester.pump();
        await tester.pump();
      }

      testWidgets('the card shows the year the server named, with what is '
          'left there', (tester) async {
        await sentAndRefused(
          tester,
          const Failure.validation(message: 'leaveBalanceShortIn|2027|0|2'),
        );

        expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
        expect(find.text(en.leaveYearLabel(2026)), findsNothing);
        expect(find.text('0 days'), findsOneWidget);
        expect(repository.balancesCalls, contains(2027));
        // What was asked for is still there, and can be changed and sent.
        expect(form().state.reason, 'New year');
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });

      testWidgets('this year\'s balance is read again too', (tester) async {
        await sentAndRefused(
          tester,
          const Failure.validation(message: 'leaveBalanceShortIn|2027|0|2'),
        );

        expect(repository.balancesCalls.where((y) => y == 2026).length, 2);
      });

      testWidgets('picking other days takes the card back to their own '
          'year', (tester) async {
        await sentAndRefused(
          tester,
          const Failure.validation(message: 'leaveBalanceShortIn|2027|0|2'),
        );

        form().setRange(DateTime(2026, 12, 28), DateTime(2026, 12, 30));
        await tester.pump();
        await tester.pump();

        expect(find.text(en.leaveYearLabel(2026)), findsOneWidget);
        expect(find.text(en.leaveYearLabel(2027)), findsNothing);
      });

      testWidgets('the named year\'s balance is slow to load: sending is not '
          'held up by it, since the form checks nothing on that year', (
        tester,
      ) async {
        final never = Completer<Result<List<LeaveBalance>>>();
        addTearDown(() => never.complete(const Result.success([])));
        repository.holdBalances[2027] = never;
        await sentAndRefused(
          tester,
          const Failure.validation(message: 'leaveBalanceShortIn|2027|0|2'),
        );

        expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
        expect(find.text('6 days'), findsNothing);
        expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
      });

      testWidgets('a refusal that names no year leaves the card on the '
          'year it showed', (tester) async {
        await sentAndRefused(
          tester,
          const Failure.validation(message: 'leaveInsufficientBalance'),
        );

        expect(find.text(en.leaveYearLabel(2026)), findsOneWidget);
        expect(repository.balancesCalls, isNot(contains(2027)));
      });
    });

    testWidgets('refused for a year the form had a figure for, and the '
        'reload fails: the card does not keep showing the old figure beside '
        'the server\'s answer (#87)', (tester) async {
      repository.balancesByYear[2027] = Result.success([
        sampleLeaveBalance(year: 2027, remainingDays: 5, usedDays: 0),
      ]);
      await pumpForm(tester);
      form()
        ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)])
        ..setReason('New year');
      await tester.pump();
      await tester.pump();
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);

      // The server counted differently, and the phone has no signal to read
      // the balances again.
      repository
        ..submitResult = const Result.failure(
          Failure.validation(message: 'leaveBalanceShortIn|2027|0|1'),
        )
        ..balancesByYear[2026] = const Result.failure(
          Failure.network(message: 'offline'),
        )
        ..balancesByYear[2027] = const Result.failure(
          Failure.network(message: 'offline'),
        );
      await tester.runAsync(() => form().submit());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
      expect(find.text('5 days'), findsNothing);
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
    group('an edit across the new year is checked year by year', () {
      /// One day in each year: 31 December 2026 and 4 January 2027.
      LeaveRequest pendingAcrossNewYear() => sampleLeaveRequest(
        id: 'req-7',
        leaveType: annual,
        requestDays: [DateTime(2026, 12, 31), DateTime(2027, 1, 4)],
        reason: 'Trip',
      );

      setUp(() {
        // Nothing left in either year: only the days the request already
        // has are covered.
        repository
          ..balancesByYear[2026] = Result.success([
            sampleLeaveBalance(remainingDays: 0),
          ])
          ..balancesByYear[2027] = Result.success([
            sampleLeaveBalance(year: 2027, remainingDays: 0, usedDays: 0),
          ]);
      });

      testWidgets('the same days in each year: allowed', (tester) async {
        form('req-7').seed(pendingAcrossNewYear());
        await pumpForm(tester, requestId: 'req-7');

        form('req-7').setReason('Family trip');
        await tester.pump();

        expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
        expect(submitEnabled(tester, en.leaveEditAction), isTrue);
      });

      testWidgets('the same day count, but a day moved from this year into '
          'next year: next year now has more than it had, and is checked', (
        tester,
      ) async {
        form('req-7').seed(pendingAcrossNewYear());
        await pumpForm(tester, requestId: 'req-7');

        form('req-7').setDates([DateTime(2027, 1, 4), DateTime(2027, 1, 5)]);
        await tester.pump();
        await tester.pump();

        expect(find.text(en.leaveYearLabel(2027)), findsOneWidget);
        expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
        expect(submitEnabled(tester, en.leaveEditAction), isFalse);
      });

      testWidgets('dropping next year\'s day is allowed', (tester) async {
        form('req-7').seed(pendingAcrossNewYear());
        await pumpForm(tester, requestId: 'req-7');

        form('req-7').setDates([DateTime(2026, 12, 31)]);
        await tester.pump();

        expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
        expect(submitEnabled(tester, en.leaveEditAction), isTrue);
      });
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

  group('a type with a limit of 0 (#104: no limit, as on the server)', () {
    final threeDays = [
      DateTime(2026, 12, 22),
      DateTime(2026, 12, 23),
      DateTime(2026, 12, 24),
    ];

    /// Any "at most N days" hint, whatever N it names (0, 0.0, 2…).
    Finder anyMaxDaysHint() =>
        find.textContaining(en.leaveMaxDaysHint('§').split('§').first);

    testWidgets('a 3-day request: no most-days hint at all, Submit on', (
      tester,
    ) async {
      repository.leaveTypesResult = Result.success([
        sampleLeaveType(maxDaysPerRequest: 0),
      ]);
      await pumpForm(tester);

      form().setDates(threeDays);
      await tester.pump();

      expect(anyMaxDaysHint(), findsNothing);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
    });

    testWidgets('from a 2-day type to a 0 type on the same 3 days: the hint '
        'goes, Submit turns on', (tester) async {
      repository
        ..leaveTypesResult = Result.success([
          sampleLeaveType(id: 'lt-short', maxDaysPerRequest: 2),
          sampleLeaveType(id: 'lt-open', code: 'open', maxDaysPerRequest: 0),
        ])
        // Both with days left, so only the limit can hold Submit back.
        ..balancesByYear[2026] = Result.success([
          sampleLeaveBalance(leaveTypeId: 'lt-short', remainingDays: 6),
          sampleLeaveBalance(leaveTypeId: 'lt-open', remainingDays: 6),
        ]);
      await pumpForm(tester);

      form()
        ..setLeaveType('lt-short')
        ..setDates(threeDays);
      await tester.pump();
      expect(find.text(en.leaveMaxDaysHint('2')), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);

      form().setLeaveType('lt-open');
      await tester.pump();
      expect(anyMaxDaysHint(), findsNothing);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
    });
  });

  group('company days off', () {
    // 2026-11-20 is a Friday; the 22nd a Sunday; the 23rd a Monday.
    final friday = DateTime(2026, 11, 20);
    final monday = DateTime(2026, 11, 23);

    testWidgets('a new request opens on a date range, with the switch above '
        'the dates', (tester) async {
      await pumpForm(tester);

      expect(find.text(en.leaveModeRange), findsOneWidget);
      expect(find.text(en.leaveModeSeparateDays), findsOneWidget);
      expect(
        container.read(leaveRequestFormNotifierProvider(null)).isRange,
        isTrue,
      );
    });

    testWidgets('a range Friday to Monday at a company closed on Sundays '
        'shows 3 days, and says days off are not counted', (tester) async {
      repository.companyDaysOffResult = const Result.success(sundaysOff);
      await pumpForm(tester);

      form().setRange(friday, monday);
      await tester.pump();

      expect(find.textContaining('3 days'), findsOneWidget);
      expect(find.text(en.leaveRangeSkipsDaysOff), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
    });

    testWidgets('a range made only of days off cannot be sent', (tester) async {
      repository.companyDaysOffResult = const Result.success(sundaysOff);
      await pumpForm(tester);

      form().setRange(DateTime(2026, 11, 22), DateTime(2026, 11, 22));
      await tester.pump();

      expect(find.text(en.leaveAllDaysOff), findsOneWidget);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isFalse);
    });

    testWidgets('when the days off cannot be loaded: a warning with Retry, '
        'the count is left to the server, and a range can still be sent', (
      tester,
    ) async {
      repository.companyDaysOffResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await pumpForm(tester);

      form().setRange(friday, monday);
      await tester.pump();

      expect(find.text(en.leaveDaysOffLoadFailed), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
      expect(find.text(en.leaveRangeCountByServer), findsOneWidget);
      // No count is shown, and nothing is blocked on one.
      expect(find.text('20 Nov 2026 – 23 Nov 2026'), findsOneWidget);
      expect(find.textContaining('20 Nov 2026 – 23 Nov 2026 ·'), findsNothing);
      expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);
      expect(submitEnabled(tester, en.leaveRequestSubmit), isTrue);
    });

    testWidgets('Retry loads the days off, and the count appears', (
      tester,
    ) async {
      repository.companyDaysOffResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await pumpForm(tester);
      form().setRange(friday, monday);
      await tester.pump();

      repository.companyDaysOffResult = const Result.success(sundaysOff);
      await tester.tap(find.text(en.retry));
      await tester.pump();
      await tester.pump();

      expect(find.text(en.leaveDaysOffLoadFailed), findsNothing);
      expect(find.textContaining('3 days'), findsOneWidget);
    });

    testWidgets('a range over the balance is blocked on the days it would '
        'be charged, not on its length', (tester) async {
      repository
        ..companyDaysOffResult = const Result.success(sundaysOff)
        ..balancesByYear[2026] = Result.success([
          sampleLeaveBalance(remainingDays: 3),
        ]);
      await pumpForm(tester);

      // Four days long, three charged: within the balance.
      form().setRange(friday, monday);
      await tester.pump();
      expect(find.text(en.leaveInsufficientBalanceHint), findsNothing);

      // One more working day: over it.
      form().setRange(friday, DateTime(2026, 11, 24));
      await tester.pump();
      expect(find.text(en.leaveInsufficientBalanceHint), findsOneWidget);
    });

    testWidgets('an edit opens on its own days, with the switch still '
        'there', (tester) async {
      form('req-7').seed(pendingOn(annual));
      await pumpForm(tester, requestId: 'req-7');

      expect(
        container.read(leaveRequestFormNotifierProvider('req-7')).mode,
        LeaveDaysMode.separateDays,
      );
      expect(find.text('18/11/2026'), findsOneWidget);
      expect(find.text('19/11/2026'), findsOneWidget);
    });

    testWidgets('a form opened for a new login starts with the days off '
        'unknown, not with the ones the draft was last told', (tester) async {
      // The draft outlives the screen; it was told the last company's rules.
      form().setDaysOff(sundaysOff);
      repository.companyDaysOffResult = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await pumpForm(tester);

      expect(
        container.read(leaveRequestFormNotifierProvider(null)).daysOff,
        isNull,
      );
    });

    testWidgets('days off that load after the range was picked are counted', (
      tester,
    ) async {
      repository.companyDaysOffResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await pumpForm(tester);
      form().setRange(friday, monday);
      await tester.pump();
      expect(find.text(en.leaveRangeCountByServer), findsOneWidget);

      repository.companyDaysOffResult = const Result.success(sundaysOff);
      container.invalidate(companyDaysOffNotifierProvider);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('3 days'), findsOneWidget);
    });
  });

  group('an edit the server refuses as out of date', () {
    testWidgets('the form itself does the closing when its Save is refused '
        'with INVALID_STATUS', (tester) async {
      repository.updateResult = const Result.failure(
        Failure.validation(message: 'leaveInvalidStatus'),
      );
      var closed = 0;
      form('req-7').seed(pendingOn(annual));
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
            home: Scaffold(
              body: LeaveRequestForm(
                requestId: 'req-7',
                onSubmitted: () => closed++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      final historyBefore = repository.myRequestsCalls.length;
      container.listen(leaveHistoryNotifierProvider, (_, _) {});
      await tester.pump();
      final loadedOnce = repository.myRequestsCalls.length;
      expect(loadedOnce, greaterThan(historyBefore));

      await tester.tap(find.text(en.leaveEditAction));
      await tester.pump();
      await tester.pump();

      expect(closed, 1);
      // The history was reloaded.
      expect(repository.myRequestsCalls.length, greaterThan(loadedOnce));

      // The next edit starts from the request as it now is.
      form('req-7').seed(
        sampleLeaveRequest(id: 'req-7', reason: 'as it is now'),
      );
      expect(
        container.read(leaveRequestFormNotifierProvider('req-7')).reason,
        'as it is now',
      );
    });

    testWidgets('a refusal that says nothing about the request being out '
        'of date keeps the page open', (tester) async {
      repository.updateResult = const Result.failure(
        Failure.validation(message: 'leaveInsufficientBalance'),
      );
      var closed = 0;
      form('req-7').seed(pendingOn(annual));
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
            home: Scaffold(
              body: LeaveRequestForm(
                requestId: 'req-7',
                onSubmitted: () => closed++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text(en.leaveEditAction));
      await tester.pump();
      await tester.pump();

      expect(closed, 0);
    });
  });

  group('files (#39)', () {
    testWidgets('attach: camera, photos or a file (PDF allowed); the file is '
        'uploaded and listed, and can be removed', (tester) async {
      await pumpForm(tester);
      final en = lookupAppLocalizations(const Locale('en'));

      await tester.ensureVisible(find.text(en.leaveChooseFileButton));
      await tester.tap(find.text(en.leaveChooseFileButton));
      await tester.pumpAndSettle();
      expect(find.text(en.uploadTakePhoto), findsOneWidget);
      expect(find.text(en.uploadPickPhoto), findsOneWidget);
      await tester.tap(find.text(en.uploadPickFile));
      await tester.pumpAndSettle();

      expect(capture.asked, ['file(pdf)']);
      expect(uploads.calls.single.folder, 'leave');
      expect(find.text('cert.jpg'), findsOneWidget);

      await tester.tap(find.byTooltip(en.leaveFileRemove));
      await tester.pumpAndSettle();
      expect(find.text('cert.jpg'), findsNothing);
      expect(form().state.files, isEmpty);
    });

    testWidgets('a failed upload says why under the files', (tester) async {
      uploads.answer = const Result.failure(
        Failure.validation(message: 'uploadFileTooLarge'),
      );
      await pumpForm(tester);
      final en = lookupAppLocalizations(const Locale('en'));

      await tester.ensureVisible(find.text(en.leaveChooseFileButton));
      await tester.tap(find.text(en.leaveChooseFileButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.uploadTakePhoto));
      await tester.pumpAndSettle();

      expect(find.text(en.uploadFileTooLarge), findsOneWidget);
    });
  });
}
