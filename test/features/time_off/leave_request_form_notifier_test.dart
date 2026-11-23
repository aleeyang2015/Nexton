import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/features/time_off/domain/entities/leave_attachment.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_balances_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_form_rules.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_history_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_state.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_types_notifier.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/leave_test_doubles.dart';
import '../../support/upload_test_doubles.dart';

void main() {
  late FakeLeaveRepository repository;
  late FakeUploads uploads;

  setUp(() {
    repository = FakeLeaveRepository();
    uploads = FakeUploads();
  });

  /// A container with the repository and the uploads faked.
  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        uploadRepositoryProvider.overrideWithValue(uploads),
      ],
    );
    // A successful submit invalidates the history list, whose reload starts on
    // a microtask. Let it run before the container goes away.
    addTearDown(() async {
      await Future<void>.delayed(Duration.zero);
      container.dispose();
    });
    return container;
  }

  LeaveRequestFormNotifier formOf(ProviderContainer c, [String? id]) =>
      c.read(leaveRequestFormNotifierProvider(id).notifier);

  LeaveRequestFormState stateOf(ProviderContainer c, [String? id]) =>
      c.read(leaveRequestFormNotifierProvider(id));

  group('setDates', () {
    test('normalises each date to midnight, drops duplicates and sorts', () {
      final container = containerWith();

      formOf(container).setDates([
        DateTime(2026, 11, 20, 14, 30),
        DateTime(2026, 11, 18, 9),
        DateTime(2026, 11, 20, 8),
        DateTime(2026, 11, 19),
      ]);

      expect(stateOf(container).dates, [
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 20),
      ]);
      expect(stateOf(container).totalDays, 3);
    });

    test('a half day keeps only the earliest date', () {
      final container = containerWith();
      formOf(container)
        ..setDurationType(LeaveDurationType.firstHalf)
        ..setDates([DateTime(2026, 11, 20), DateTime(2026, 11, 18)]);

      expect(stateOf(container).dates, [DateTime(2026, 11, 18)]);
      expect(stateOf(container).totalDays, 0.5);
    });

    test('switching to a half day trims the dates already picked to the '
        'earliest', () {
      final container = containerWith();
      formOf(container)
        ..setDates([DateTime(2026, 11, 20), DateTime(2026, 11, 18)])
        ..setDurationType(LeaveDurationType.secondHalf);

      expect(stateOf(container).dates, [DateTime(2026, 11, 18)]);
      expect(stateOf(container).durationType, LeaveDurationType.secondHalf);
    });

    test('a half day that cuts the days picked forgets the return date '
        'picked by hand for them (#14)', () {
      final container = containerWith();
      formOf(container)
        ..setDates([DateTime(2026, 11, 18), DateTime(2026, 11, 19)])
        ..setReturnToWorkDate(DateTime(2026, 11, 20))
        ..setDurationType(LeaveDurationType.firstHalf);

      expect(stateOf(container).dates, [DateTime(2026, 11, 18)]);
      expect(stateOf(container).returnToWorkOverride, isNull);
    });

    test('a half day on the one day already picked keeps the return date '
        'picked by hand (#14)', () {
      final container = containerWith();
      formOf(container)
        ..setDates([DateTime(2026, 11, 18)])
        ..setReturnToWorkDate(DateTime(2026, 11, 20))
        ..setDurationType(LeaveDurationType.firstHalf);

      expect(stateOf(container).returnToWorkOverride, DateTime(2026, 11, 20));
    });

    test('removeDate drops that day only', () {
      final container = containerWith();
      formOf(container)
        ..setDates([DateTime(2026, 11, 18), DateTime(2026, 11, 19)])
        ..removeDate(DateTime(2026, 11, 18));

      expect(stateOf(container).dates, [DateTime(2026, 11, 19)]);
    });
  });

  group('setLeaveType', () {
    /// A container whose type list has loaded: annual takes whole days only,
    /// personal and sick take half days.
    Future<ProviderContainer> withTypes() async {
      repository.leaveTypesResult = Result.success([
        sampleLeaveType(),
        sampleLeaveType(id: 'lt-personal', allowHalfDay: true),
        sampleLeaveType(id: 'lt-sick', allowHalfDay: true),
      ]);
      final container = containerWith();
      await container.read(leaveTypesNotifierProvider.future);
      return container;
    }

    test('a type that takes whole days only resets a half day to a full day, '
        'in the same step', () async {
      final container = await withTypes();
      formOf(container)
        ..setLeaveType('lt-personal')
        ..setDurationType(LeaveDurationType.firstHalf)
        ..setDates([DateTime(2026, 11, 18)]);
      expect(stateOf(container).durationType, LeaveDurationType.firstHalf);

      formOf(container).setLeaveType('lt-annual');

      final state = stateOf(container);
      expect(state.leaveTypeId, 'lt-annual');
      expect(state.durationType, LeaveDurationType.fullDay);
      expect(state.totalDays, 1);
    });

    test('a type that takes half days keeps the half day', () async {
      final container = await withTypes();
      formOf(container)
        ..setLeaveType('lt-personal')
        ..setDurationType(LeaveDurationType.secondHalf)
        ..setLeaveType('lt-sick');

      expect(stateOf(container).durationType, LeaveDurationType.secondHalf);
    });

    test('after the reset, what is sent is full_day', () async {
      final container = await withTypes();
      final form = formOf(container)
        ..setLeaveType('lt-personal')
        ..setDurationType(LeaveDurationType.firstHalf)
        ..setDates([DateTime(2026, 11, 18)])
        ..setLeaveType('lt-annual');

      await form.submit();

      expect(
        repository.submitCalls.single.durationType,
        LeaveDurationType.fullDay,
      );
    });

    test('a type that is not in the loaded list changes the selection and '
        'nothing else', () async {
      final container = await withTypes();
      formOf(container)
        ..setLeaveType('lt-personal')
        ..setDurationType(LeaveDurationType.firstHalf)
        ..setLeaveType('lt-unknown');

      expect(stateOf(container).leaveTypeId, 'lt-unknown');
      expect(stateOf(container).durationType, LeaveDurationType.firstHalf);
    });
  });

  group('the return-to-work date', () {
    test('defaults to the day after the last leave day', () {
      final container = containerWith();
      formOf(
        container,
      ).setDates([DateTime(2026, 11, 18), DateTime(2026, 11, 20)]);

      expect(stateOf(container).lastLeaveDate, DateTime(2026, 11, 20));
      expect(stateOf(container).returnToWorkDate, DateTime(2026, 11, 21));
      expect(stateOf(container).hasValidReturnToWorkDate, isTrue);
    });

    test('is absent, and nothing is invalid, before any day is picked', () {
      final state = stateOf(containerWith());

      expect(state.returnToWorkDate, isNull);
      expect(state.hasValidReturnToWorkDate, isTrue);
      expect(state.hasValidShape, isFalse);
    });

    test('a later date the user picked is kept', () {
      final container = containerWith();
      formOf(container)
        ..setDates([DateTime(2026, 11, 18)])
        ..setReturnToWorkDate(DateTime(2026, 11, 23));

      expect(stateOf(container).returnToWorkDate, DateTime(2026, 11, 23));
      expect(stateOf(container).hasValidReturnToWorkDate, isTrue);
    });

    test('a return date on or before the last leave day is invalid, and the '
        'form will not send', () async {
      final container = containerWith();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18), DateTime(2026, 11, 20)]);

      for (final returnDate in [DateTime(2026, 11, 20), DateTime(2026, 11, 19)]) {
        form.setReturnToWorkDate(returnDate);

        expect(stateOf(container).hasValidReturnToWorkDate, isFalse);
        expect(stateOf(container).hasValidShape, isFalse);
        expect(await form.submit(), isFalse);
      }
      expect(repository.submitCalls, isEmpty);
    });
  });

  group('submit, a new request', () {
    test('sends the draft: type, sorted dates, duration, return date and '
        'reason', () async {
      final container = containerWith();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 20), DateTime(2026, 11, 18)])
        ..setReason('Family trip');

      expect(await form.submit(), isTrue);

      final draft = repository.submitCalls.single;
      expect(draft.leaveTypeId, 'lt-annual');
      expect(draft.dates, [DateTime(2026, 11, 18), DateTime(2026, 11, 20)]);
      expect(draft.durationType, LeaveDurationType.fullDay);
      expect(draft.returnDate, DateTime(2026, 11, 21));
      expect(draft.reason, 'Family trip');
      expect(draft.attachments, isNull);
      expect(repository.updateCalls, isEmpty);
    });

    test('carries the files attached, each as the server kept it', () async {
      final container = containerWith();
      final form = formOf(container)
        ..setLeaveType('lt-sick')
        ..setDates([DateTime(2026, 11, 18)]);
      await form.addFile(_photo);

      await form.submit();

      expect(repository.submitCalls.single.attachments, [
        const LeaveAttachment(
          url: 'https://files.nexton.work/uploads/cert.jpg',
          fileName: 'uploads/cert.jpg',
          originalName: 'cert.jpg',
          contentType: 'image/jpeg',
          size: 1234,
        ),
      ]);
      expect(uploads.calls.single.folder, 'leave');
    });

    test('resets the form, files too, after success', () async {
      final container = containerWith();
      final form = formOf(container);
      await form.addFile(_photo);
      form
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)])
        ..setReason('Trip');

      await form.submit();

      // Back to an empty form; the company's days off it knows stay known.
      final reset = stateOf(container);
      expect(reset, LeaveRequestFormState(daysOff: reset.daysOff));
      expect(reset.leaveTypeId, isNull);
      expect(reset.hasDays, isFalse);
      expect(reset.reason, isEmpty);
      expect(reset.files, isEmpty);
    });

    group('refused for the balance of a year the server names (#87)', () {
      const refused = Failure.validation(
        message: 'leaveBalanceShortIn|2027|0|2',
        code: 'INSUFFICIENT_BALANCE',
      );

      test('the year is kept for the card, and the balances are read '
          'again', () async {
        repository.submitResult = const Result.failure(refused);
        final container = containerWith();
        container.listen(leaveBalancesNotifierProvider(2026), (_, _) {});
        await container.read(leaveBalancesNotifierProvider(2026).future);
        expect(repository.balancesCalls, [2026]);
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)])
          ..setReason('Trip');

        expect(await form.submit(), isFalse);
        await container.read(leaveBalancesNotifierProvider(2026).future);

        final state = stateOf(container);
        expect(state.balanceRefusedYear, 2027);
        expect(state.submission.error, refused);
        expect(state.reason, 'Trip');
        expect(repository.balancesCalls, [2026, 2026]);
      });

      test('an edit keeps the year too, and its page stays open', () async {
        repository.updateResult = const Result.failure(refused);
        final container = containerWith();
        final form = formOf(container, 'req-7')
          ..seed(sampleLeaveRequest(id: 'req-7'))
          ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)]);

        expect(await form.submit(), isFalse);

        expect(stateOf(container, 'req-7').balanceRefusedYear, 2027);
      });

      test('any change to what is asked for forgets the year: the refusal '
          'was about the request as it was sent', () async {
        final changes = <String, void Function(LeaveRequestFormNotifier)>{
          'other days': (f) => f.setDates([DateTime(2026, 12, 30)]),
          'a day removed': (f) => f.removeDate(DateTime(2027, 1, 4)),
          'a range': (f) =>
              f.setRange(DateTime(2026, 12, 28), DateTime(2026, 12, 30)),
          'the other way of picking': (f) => f.setMode(LeaveDaysMode.range),
          'another type': (f) => f.setLeaveType('lt-sick'),
          'a half day': (f) => f.setDurationType(LeaveDurationType.firstHalf),
        };
        for (final MapEntry(key: what, value: change) in changes.entries) {
          repository = FakeLeaveRepository()
            ..submitResult = const Result.failure(refused);
          final container = containerWith();
          final form = formOf(container)
            ..setLeaveType('lt-annual')
            ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)]);
          await form.submit();
          expect(stateOf(container).balanceRefusedYear, 2027, reason: what);

          change(form);

          expect(stateOf(container).balanceRefusedYear, isNull, reason: what);
        }
      });

      test('typing a reason does not forget it', () async {
        repository.submitResult = const Result.failure(refused);
        final container = containerWith();
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)]);
        await form.submit();

        form.setReason('a longer reason');

        expect(stateOf(container).balanceRefusedYear, 2027);
      });

      test('sending the same again and failing for another reason keeps the '
          'year: nothing about the request changed', () async {
        repository.submitResult = const Result.failure(refused);
        final container = containerWith();
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)]);
        await form.submit();

        final hold = Completer<void>();
        repository
          ..holdSubmit = hold
          ..submitResult = const Result.failure(
            Failure.network(message: 'offline'),
          );
        final resend = form.submit();
        // On its way: the card must not flip back meanwhile.
        expect(stateOf(container).balanceRefusedYear, 2027);
        hold.complete();
        expect(await resend, isFalse);

        expect(stateOf(container).balanceRefusedYear, 2027);
      });

      test('a request that is then accepted leaves no year: new or '
          'edited', () async {
        repository.submitResult = const Result.failure(refused);
        final container = containerWith();
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)]);
        await form.submit();
        repository.submitResult = Result.success(sampleLeaveRequest());
        expect(await form.submit(), isTrue);
        expect(stateOf(container).balanceRefusedYear, isNull);

        repository.updateResult = const Result.failure(refused);
        final edit = formOf(container, 'req-7')
          ..seed(sampleLeaveRequest(id: 'req-7'))
          ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)]);
        await edit.submit();
        expect(stateOf(container, 'req-7').balanceRefusedYear, 2027);
        repository.updateResult = Result.success(
          sampleLeaveRequest(id: 'req-7'),
        );
        expect(await edit.submit(), isTrue);
        expect(stateOf(container, 'req-7').balanceRefusedYear, isNull);
      });

      test('a refusal that lands after the days were changed is about the '
          'old request: no year is kept, the balances are still read '
          'again', () async {
        final hold = Completer<void>();
        repository
          ..holdSubmit = hold
          ..submitResult = const Result.failure(refused);
        final container = containerWith();
        container.listen(leaveBalancesNotifierProvider(2026), (_, _) {});
        await container.read(leaveBalancesNotifierProvider(2026).future);
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 12, 30), DateTime(2027, 1, 4)]);

        final sending = form.submit();
        form.setDates([DateTime(2026, 12, 30)]);
        hold.complete();
        expect(await sending, isFalse);
        await container.read(leaveBalancesNotifierProvider(2026).future);

        expect(stateOf(container).balanceRefusedYear, isNull);
        expect(stateOf(container).dates, [DateTime(2026, 12, 30)]);
        expect(repository.balancesCalls, [2026, 2026]);
      });

      test('a year the request has no day in is not kept for the card', () async {
        for (final year in [2001, 2025, 2028]) {
          repository = FakeLeaveRepository()
            ..submitResult = Result.failure(
              Failure.validation(message: 'leaveBalanceShortIn|$year|0|2'),
            );
          final container = containerWith();
          final form = formOf(container)
            ..setLeaveType('lt-annual')
            ..setRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2));

          expect(await form.submit(), isFalse);

          expect(stateOf(container).balanceRefusedYear, isNull, reason: '$year');
        }
      });

      test('a refusal with no year (the plain text) keeps none, and reads '
          'the balances again all the same', () async {
        repository.submitResult = const Result.failure(
          Failure.validation(message: 'leaveInsufficientBalance'),
        );
        final container = containerWith();
        container.listen(leaveBalancesNotifierProvider(2026), (_, _) {});
        await container.read(leaveBalancesNotifierProvider(2026).future);
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 12, 30)]);

        expect(await form.submit(), isFalse);
        await container.read(leaveBalancesNotifierProvider(2026).future);

        expect(stateOf(container).balanceRefusedYear, isNull);
        expect(repository.balancesCalls, [2026, 2026]);
      });
    });

    test('a failure keeps what was typed and surfaces the failure', () async {
      const refused = Failure.validation(message: 'leaveInsufficientBalance');
      repository.submitResult = const Result.failure(refused);
      final container = containerWith();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)])
        ..setReason('Trip');

      expect(await form.submit(), isFalse);

      final state = stateOf(container);
      expect(state.submission.error, refused);
      expect(state.leaveTypeId, 'lt-annual');
      expect(state.dates, [DateTime(2026, 11, 18)]);
      expect(state.reason, 'Trip');
    });

    test('will not send without a leave type or without a day', () async {
      final container = containerWith();

      expect(await formOf(container).submit(), isFalse);

      formOf(container).setLeaveType('lt-annual');
      expect(await formOf(container).submit(), isFalse);

      expect(repository.submitCalls, isEmpty);
    });
  });

  group('submit, an edit', () {
    final withFiles = sampleLeaveRequest(
      id: 'req-7',
      attachments: const [_cert, _noUrl],
    );
    final existing = sampleLeaveRequest(
      id: 'req-7',
      requestDays: [DateTime(2026, 11, 20), DateTime(2026, 11, 18)],
      returnDate: DateTime(2026, 11, 23),
      reason: 'Trip',
    );

    test('seed fills the form from the request, days sorted', () {
      final container = containerWith();

      formOf(container, 'req-7').seed(existing);

      final state = stateOf(container, 'req-7');
      expect(state.isEditing, isTrue);
      expect(state.editingRequestId, 'req-7');
      expect(state.leaveTypeId, existing.leaveType.id);
      expect(state.dates, [DateTime(2026, 11, 18), DateTime(2026, 11, 20)]);
      expect(state.returnToWorkDate, DateTime(2026, 11, 23));
      expect(state.reason, 'Trip');
    });

    test('seed records the type and the days the request had in each year',
        () {
      final container = containerWith();

      formOf(container, 'req-7').seed(existing);

      final state = stateOf(container, 'req-7');
      expect(state.originalLeaveTypeId, existing.leaveType.id);
      expect(state.originalDaysByYear, {2026: 2});
      expect(state.coveredDays(2026), 2);
      expect(state.coveredDays(2027), 0);
    });

    test('seed splits a request across the new year by the year of each day, '
        'whatever order the days came in', () {
      final container = containerWith();

      formOf(container, 'req-8').seed(
        sampleLeaveRequest(
          id: 'req-8',
          requestDays: [
            DateTime(2027, 1, 4),
            DateTime(2026, 12, 30),
            DateTime(2026, 12, 31),
          ],
        ),
      );

      expect(stateOf(container, 'req-8').originalDaysByYear, {
        2026: 2,
        2027: 1,
      });
    });

    test('seed counts a half-day request as half a day in its year', () {
      final container = containerWith();

      formOf(container, 'req-9').seed(
        sampleLeaveRequest(
          id: 'req-9',
          requestDays: [DateTime(2026, 11, 18)],
          totalDays: 0.5,
          durationType: LeaveDurationType.firstHalf,
        ),
      );

      expect(stateOf(container, 'req-9').originalDaysByYear, {2026: 0.5});
    });

    test('an edit moved to another type no longer has any days covered; '
        'moved back, it has them again', () {
      final container = containerWith();
      final form = formOf(container, 'req-7')..seed(existing);

      form.setLeaveType('lt-sick');
      expect(stateOf(container, 'req-7').coveredDays(2026), 0);

      form.setLeaveType(existing.leaveType.id);
      expect(stateOf(container, 'req-7').coveredDays(2026), 2);
    });

    test('a new request has no original type and no days covered', () {
      final state = stateOf(containerWith());

      expect(state.originalLeaveTypeId, isNull);
      expect(state.originalDaysByYear, isEmpty);
      expect(state.coveredDays(2026), 0);
    });

    test('the years the balance is checked in are those of the leave days, '
        'or this year before any is picked', () {
      final container = containerWith();
      final now = DateTime(2026, 12, 20);

      expect(LeaveFormRules.balanceYears(stateOf(container), now), [2026]);

      formOf(
        container,
      ).setDates([DateTime(2027, 1, 6), DateTime(2027, 1, 5)]);
      expect(LeaveFormRules.balanceYears(stateOf(container), now), [2027]);

      // Across the new year: both years, earliest first.
      formOf(
        container,
      ).setDates([DateTime(2027, 1, 2), DateTime(2026, 12, 31)]);
      expect(LeaveFormRules.balanceYears(stateOf(container), now), [
        2026,
        2027,
      ]);
      expect(stateOf(container).daysByYear, {2026: 1, 2027: 1});
    });

    group('the year that is short', () {
      final annual = sampleLeaveType();

      int? shortYear(
        ProviderContainer container,
        Map<int, double?> remainingByYear, {
        LeaveType? type,
        String? id,
      }) => LeaveFormRules.shortYear(
        state: stateOf(container, id),
        type: type ?? annual,
        remainingByYear: remainingByYear,
      );

      test('is the earliest year that cannot pay for its own days', () {
        final container = containerWith();
        formOf(container).setDates([
          DateTime(2026, 12, 30),
          DateTime(2026, 12, 31),
          DateTime(2027, 1, 4),
        ]);

        expect(shortYear(container, {2026: 2, 2027: 1}), isNull);
        expect(shortYear(container, {2026: 6, 2027: 0}), 2027);
        expect(shortYear(container, {2026: 1, 2027: 12}), 2026);
        expect(shortYear(container, {2026: 1, 2027: 0}), 2026);
      });

      test('the card shows the short year, else the first year', () {
        final container = containerWith();
        formOf(
          container,
        ).setDates([DateTime(2026, 12, 31), DateTime(2027, 1, 4)]);

        int cardYear(Map<int, double?> remainingByYear) =>
            LeaveFormRules.cardYear(
              state: stateOf(container),
              type: annual,
              years: const [2026, 2027],
              remainingByYear: remainingByYear,
            );

        expect(cardYear({2026: 6, 2027: 6}), 2026);
        expect(cardYear({2026: 6, 2027: 0}), 2027);
        expect(cardYear({2026: 6, 2027: null}), 2026);
      });

      test('a year whose balance is not known is not checked', () {
        final container = containerWith();
        formOf(
          container,
        ).setDates([DateTime(2026, 12, 31), DateTime(2027, 1, 4)]);

        expect(shortYear(container, {2026: 6, 2027: null}), isNull);
        expect(shortYear(container, {2026: 6}), isNull);
        expect(shortYear(container, {2026: 0, 2027: null}), 2026);
      });

      test('a type that may go negative is never short', () {
        final container = containerWith();
        formOf(container).setDates([DateTime(2027, 1, 4)]);

        expect(
          shortYear(
            container,
            {2027: 0},
            type: sampleLeaveType(allowNegativeBalance: true),
          ),
          isNull,
        );
      });

      test('a half day asks for half a day of its year', () {
        final container = containerWith();
        formOf(container)
          ..setDates([DateTime(2027, 1, 4)])
          ..setDurationType(LeaveDurationType.firstHalf);

        expect(stateOf(container).daysByYear, {2027: 0.5});
        expect(shortYear(container, {2027: 0.5}), isNull);
        expect(shortYear(container, {2027: 0}), 2027);
      });

      test('an edit is checked in a year only when it asks for more days '
          'there than the request had', () {
        final container = containerWith();
        final form = formOf(container, 'req-7')..seed(existing);

        // The 2 days it had in 2026, with nothing left: allowed.
        expect(shortYear(container, {2026: 0}, id: 'req-7'), isNull);

        // One of them moved to 2027, where it had none.
        form.setDates([DateTime(2026, 11, 18), DateTime(2027, 1, 4)]);
        expect(shortYear(container, {2026: 0, 2027: 0}, id: 'req-7'), 2027);
        expect(shortYear(container, {2026: 0, 2027: 1}, id: 'req-7'), isNull);

        // A third day in 2026: more than it had there.
        form.setDates([
          DateTime(2026, 11, 18),
          DateTime(2026, 11, 19),
          DateTime(2026, 11, 20),
        ]);
        expect(shortYear(container, {2026: 2}, id: 'req-7'), 2026);
        expect(shortYear(container, {2026: 3}, id: 'req-7'), isNull);
      });
    });

    test('seed runs once: a second call does not undo the user\'s edits', () {
      final container = containerWith();
      formOf(container, 'req-7')
        ..seed(existing)
        ..setReason('Changed')
        ..seed(existing);

      expect(stateOf(container, 'req-7').reason, 'Changed');
    });

    test('updates that request instead of sending a new one', () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')
        ..seed(existing)
        ..setReason('Longer trip');

      expect(await form.submit(), isTrue);

      expect(repository.submitCalls, isEmpty);
      final call = repository.updateCalls.single;
      expect(call.id, 'req-7');
      expect(call.draft.reason, 'Longer trip');
      expect(call.draft.dates, [
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 20),
      ]);
    });

    test('does not reset the form after success: the edit page still shows '
        'it', () async {
      final updated = sampleLeaveRequest(id: 'req-7', reason: 'Longer trip');
      repository.updateResult = Result.success(updated);
      final container = containerWith();
      final form = formOf(container, 'req-7')
        ..seed(existing)
        ..setReason('Longer trip');

      await form.submit();

      final state = stateOf(container, 'req-7');
      expect(state.isEditing, isTrue);
      expect(state.reason, 'Longer trip');
      expect(state.submission.value, updated);
    });

    test('files not touched: no attachments sent, the request keeps its own',
        () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')..seed(withFiles);
      expect(stateOf(container, 'req-7').files, [_cert, _noUrl]);

      await form.submit();

      expect(repository.updateCalls.single.draft.attachments, isNull);
    });

    test('a file removed: the whole remaining list is sent', () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')..seed(withFiles);

      form.removeFile(0);
      await form.submit();

      // The url-less one goes back too, or the edit would drop it.
      expect(repository.updateCalls.single.draft.attachments, [_noUrl]);
    });

    test('every file removed: [] is sent, so the server removes them',
        () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')..seed(withFiles);

      form
        ..removeFile(1)
        ..removeFile(0);
      await form.submit();

      expect(repository.updateCalls.single.draft.attachments, isEmpty);
    });

    test('a file added: the kept ones and the new one are sent', () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')..seed(withFiles);

      await form.addFile(_photo);
      await form.submit();

      final sent = repository.updateCalls.single.draft.attachments!;
      expect(sent.take(2), [_cert, _noUrl]);
      expect(sent.last.originalName, 'cert.jpg');
    });
  });

  group('after a successful submit, history and balances are loaded again',
      () {
    Future<ProviderContainer> watched() async {
      final container = containerWith();
      // Both lists are on screen, as they are on the time-off page.
      container
        ..listen(leaveHistoryNotifierProvider, (_, _) {})
        ..listen(leaveBalancesNotifierProvider(2026), (_, _) {});
      await container.read(leaveBalancesNotifierProvider(2026).future);
      await Future<void>.delayed(Duration.zero);
      return container;
    }

    test('a new request', () async {
      final container = await watched();
      expect(repository.myRequestsCalls, hasLength(1));
      expect(repository.balancesCalls, hasLength(1));

      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)]);
      await form.submit();
      await container.read(leaveBalancesNotifierProvider(2026).future);
      await Future<void>.delayed(Duration.zero);

      expect(repository.myRequestsCalls, hasLength(2));
      expect(repository.balancesCalls, hasLength(2));
    });

    test('an edit', () async {
      final container = await watched();

      final form = formOf(container, 'req-7')..seed(sampleLeaveRequest(id: 'req-7'));
      await form.submit();
      await container.read(leaveBalancesNotifierProvider(2026).future);
      await Future<void>.delayed(Duration.zero);

      expect(repository.myRequestsCalls, hasLength(2));
      expect(repository.balancesCalls, hasLength(2));
    });

    test('every year\'s balances on screen are loaded again, not only one',
        () async {
      final container = await watched();
      container.listen(leaveBalancesNotifierProvider(2027), (_, _) {});
      await container.read(leaveBalancesNotifierProvider(2027).future);
      expect(repository.balancesCalls, [2026, 2027]);

      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)]);
      await form.submit();
      await container.read(leaveBalancesNotifierProvider(2026).future);
      await container.read(leaveBalancesNotifierProvider(2027).future);

      expect(repository.balancesCalls, unorderedEquals([2026, 2027, 2026, 2027]));
    });

    test('a failed submit loads neither again', () async {
      repository.submitResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      final container = await watched();

      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)]);
      await form.submit();
      await Future<void>.delayed(Duration.zero);

      expect(repository.myRequestsCalls, hasLength(1));
      expect(repository.balancesCalls, hasLength(1));
    });
  });

  group('company days off and the two ways to pick days', () {
    // 2026-11-20 is a Friday, the 21st a Saturday, the 22nd a Sunday, the
    // 23rd a Monday.
    final friday = DateTime(2026, 11, 20);
    final saturday = DateTime(2026, 11, 21);
    final sunday = DateTime(2026, 11, 22);
    final monday = DateTime(2026, 11, 23);

    /// A container whose form has been told the company is closed on
    /// Sundays, as the form on screen tells it.
    Future<ProviderContainer> closedOnSundays() async {
      final container = containerWith();
      formOf(container).setDaysOff(sundaysOff);
      formOf(container, 'req-7').setDaysOff(sundaysOff);
      return container;
    }

    test('a new request opens on a date range', () {
      final state = stateOf(containerWith());

      expect(state.mode, LeaveDaysMode.range);
      expect(state.hasDays, isFalse);
      expect(state.totalDays, 0);
    });

    test('the preview count of a range leaves out the days off: Friday to '
        'Monday is 3 days', () async {
      final container = await closedOnSundays();

      formOf(container).setRange(friday, monday);

      final state = stateOf(container);
      expect(state.totalDays, 3);
      expect(state.chargedDays, [friday, saturday, monday]);
      expect(state.firstLeaveDate, friday);
      expect(state.lastLeaveDate, monday);
    });

    test('a range is put in order, whichever end was given first', () async {
      final container = await closedOnSundays();

      formOf(container).setRange(monday, friday);

      expect(stateOf(container).rangeStart, friday);
      expect(stateOf(container).rangeEnd, monday);
    });

    test('while the days off are not known the count is unknown, not a '
        'guess', () {
      repository.companyDaysOffResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      final container = containerWith();

      formOf(container).setRange(friday, monday);

      final state = stateOf(container);
      expect(state.daysOff, isNull);
      expect(state.totalDays, isNull);
      expect(state.chargedDays, isNull);
      // The range's own ends stand in for the first and last leave day.
      expect(state.firstLeaveDate, friday);
      expect(state.lastLeaveDate, monday);
      expect(state.hasValidShape, isFalse, reason: 'no leave type yet');
    });

    test('a range of days off only is all days off', () async {
      final container = await closedOnSundays();

      formOf(container).setRange(sunday, sunday);

      expect(stateOf(container).totalDays, 0);
      expect(stateOf(container).isAllDaysOff, isTrue);
    });

    test('a range of days off only is not sent', () async {
      final container = await closedOnSundays();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setRange(sunday, sunday);

      expect(await form.submit(), isFalse);
      expect(repository.submitCalls, isEmpty);
    });

    test('the default return date skips days off: after a Saturday-only '
        'leave it is Monday, not Sunday', () async {
      final container = await closedOnSundays();

      formOf(container).setRange(saturday, saturday);

      expect(stateOf(container).returnToWorkDate, monday);
      expect(stateOf(container).hasValidReturnToWorkDate, isTrue);
    });

    test(
      'the default return date skips days off for separate days too',
      () async {
        final container = await closedOnSundays();

        formOf(container).setDates([friday, saturday]);

        expect(stateOf(container).returnToWorkDate, monday);
      },
    );

    test('with the days off unknown the default return date is the next '
        'day', () {
      repository.companyDaysOffResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      final container = containerWith();

      formOf(container).setRange(saturday, saturday);

      expect(stateOf(container).returnToWorkDate, sunday);
    });

    test('a return date the user chose is kept, day off or not', () async {
      final container = await closedOnSundays();
      formOf(container)
        ..setRange(saturday, saturday)
        ..setReturnToWorkDate(sunday);

      expect(stateOf(container).returnToWorkDate, sunday);
    });

    test('a return date inside the range is not valid, even on a day off '
        'at its end', () async {
      final container = await closedOnSundays();
      formOf(container)
        ..setRange(friday, sunday)
        ..setReturnToWorkDate(sunday);

      expect(stateOf(container).earliestReturnToWorkDate, monday);
      expect(stateOf(container).hasValidReturnToWorkDate, isFalse);
    });

    test('a range ending on a day off defaults its return to the next '
        'working day', () async {
      final container = await closedOnSundays();

      formOf(container).setRange(friday, sunday);

      expect(stateOf(container).returnToWorkDate, monday);
      expect(stateOf(container).hasValidReturnToWorkDate, isTrue);
    });

    test('a range is sent as its two ends, with no dates', () async {
      final container = await closedOnSundays();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setRange(friday, monday);

      expect(await form.submit(), isTrue);

      final draft = repository.submitCalls.single;
      expect(draft.isRange, isTrue);
      expect(draft.startDate, friday);
      expect(draft.endDate, monday);
      expect(draft.dates, isEmpty);
      expect(draft.returnDate, DateTime(2026, 11, 24));
    });

    test('separate days are sent one by one, with no range', () async {
      final container = await closedOnSundays();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 2), DateTime(2026, 11, 16)]);

      await form.submit();

      final draft = repository.submitCalls.single;
      expect(draft.isRange, isFalse);
      expect(draft.dates, [DateTime(2026, 11, 2), DateTime(2026, 11, 16)]);
      expect(draft.startDate, isNull);
    });

    test(
      'a half day forces separate days, on the first day of the range',
      () async {
        final container = await closedOnSundays();
        formOf(container)
          ..setRange(friday, monday)
          ..setDurationType(LeaveDurationType.firstHalf);

        final state = stateOf(container);
        expect(state.mode, LeaveDaysMode.separateDays);
        expect(state.dates, [friday]);
        expect(state.rangeStart, isNull);
        expect(state.totalDays, 0.5);
      },
    );

    test('a half day cannot be switched to a range', () async {
      final container = await closedOnSundays();
      formOf(container)
        ..setDates([friday])
        ..setDurationType(LeaveDurationType.firstHalf)
        ..setMode(LeaveDaysMode.range);

      expect(stateOf(container).mode, LeaveDaysMode.separateDays);
    });

    test(
      'an edit opens on separate days, with the request\'s own days',
      () async {
        final container = await closedOnSundays();

        formOf(
          container,
          'req-7',
        ).seed(sampleLeaveRequest(id: 'req-7', requestDays: [friday, monday]));

        final state = stateOf(container, 'req-7');
        expect(state.mode, LeaveDaysMode.separateDays);
        expect(state.dates, [friday, monday]);
        expect(state.totalDays, 2);
      },
    );

    test('switching to separate days keeps the range\'s working days; '
        'switching back makes a range of the first and last', () async {
      final container = await closedOnSundays();
      final form = formOf(container)..setRange(friday, monday);

      form.setMode(LeaveDaysMode.separateDays);
      expect(stateOf(container).dates, [friday, saturday, monday]);
      expect(stateOf(container).rangeStart, isNull);

      form.setMode(LeaveDaysMode.range);
      expect(stateOf(container).rangeStart, friday);
      expect(stateOf(container).rangeEnd, monday);
      expect(stateOf(container).dates, isEmpty);
    });

    test(
      'the balance years of a range are those of its charged days',
      () async {
        final container = await closedOnSundays();

        formOf(
          container,
        ).setRange(DateTime(2026, 12, 30), DateTime(2027, 1, 4));

        // Sunday 3 January is a day off: 30 and 31 December, then 1, 2 and
        // 4 January.
        expect(
          LeaveFormRules.balanceYears(
            stateOf(container),
            DateTime(2026, 12, 1),
          ),
          [2026, 2027],
        );
        expect(stateOf(container).daysByYear, {2026: 2, 2027: 3});
      },
    );

    test('the days off the form was told are kept across a reset', () async {
      final container = await closedOnSundays();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setRange(friday, monday);

      await form.submit();

      expect(stateOf(container).daysOff, sundaysOff);
    });

    test('the notifier does not hold the days-off list alive itself, so a '
        'sign-out drops it', () async {
      final container = containerWith();
      container.listen(leaveRequestFormNotifierProvider(null), (_, _) {});
      formOf(container).setRange(friday, monday);
      await Future<void>.delayed(Duration.zero);

      // Nothing on screen asked for the list, so nothing fetched it.
      expect(repository.companyDaysOffCalls, 0);
      expect(stateOf(container).daysOff, isNull);
    });

    test('a half day on a range of days off only picks no day, never the '
        'day off', () async {
      final container = await closedOnSundays();
      formOf(container)
        ..setRange(sunday, sunday)
        ..setDurationType(LeaveDurationType.firstHalf);

      expect(stateOf(container).dates, isEmpty);
      expect(stateOf(container).hasValidShape, isFalse);
    });

    test('a half day on a range that starts on a day off takes its first '
        'working day', () async {
      final container = await closedOnSundays();
      formOf(container)
        ..setRange(sunday, monday)
        ..setDurationType(LeaveDurationType.firstHalf);

      expect(stateOf(container).dates, [monday]);
    });
  });

  group('an edit the server called out of date', () {
    final asOpened = sampleLeaveRequest(id: 'req-7', reason: 'as opened');
    final asItIsNow = sampleLeaveRequest(id: 'req-7', reason: 'as it is now');

    test('seeding twice from the same request keeps the form: the second '
        'seed changes nothing', () {
      final container = containerWith();
      formOf(container, 'req-7')
        ..seed(asOpened)
        ..setReason('typed by the user')
        ..seed(sampleLeaveRequest(id: 'req-7', reason: 'as opened'));

      expect(stateOf(container, 'req-7').reason, 'typed by the user');
    });

    test('a request that has changed since the form was filled fills it '
        'again: a draft on the old days is not kept', () {
      final container = containerWith();
      formOf(container, 'req-7')
        ..seed(asOpened)
        ..setReason('typed by the user')
        ..seed(
          sampleLeaveRequest(
            id: 'req-7',
            reason: 'as opened',
            requestDays: [DateTime(2026, 11, 25)],
          ),
        );

      final state = stateOf(container, 'req-7');
      expect(state.reason, 'as opened');
      expect(state.dates, [DateTime(2026, 11, 25)]);
    });

    test('a refusal that is not about the request being out of date keeps '
        'the form for the next seed', () async {
      final container = containerWith();
      repository.updateResult = const Result.failure(
        Failure.validation(message: 'leaveInsufficientBalance'),
      );
      final form = formOf(container, 'req-7')
        ..seed(asOpened)
        ..setReason('typed by the user');
      await form.submit();

      form.seed(asOpened);

      expect(stateOf(container, 'req-7').reason, 'typed by the user');
    });

    group('a type the server says is switched off or gone', () {
      const refusals = [
        Failure.validation(message: 'leaveRuleTypeInactive'),
        Failure.validation(message: 'leaveRuleTypeNotFound'),
      ];

      /// A container whose leave types are loaded and listened to, as the
      /// form on screen keeps them.
      Future<ProviderContainer> withTypes() async {
        final container = containerWith();
        container.listen(leaveTypesNotifierProvider, (_, _) {});
        await container.read(leaveTypesNotifierProvider.future);
        return container;
      }

      test('a new request: the types are asked for again, the user must '
          'pick again, and what was typed stays', () async {
        for (final failure in refusals) {
          repository = FakeLeaveRepository()
            ..submitResult = Result.failure(failure);
          final container = await withTypes();
          expect(repository.leaveTypesCalls, 1);
          final form = formOf(container)
            ..setLeaveType('lt-annual')
            ..setDates([DateTime(2026, 11, 18)])
            ..setReason('kept');

          expect(await form.submit(), isFalse);
          await Future<void>.delayed(Duration.zero);

          expect(repository.leaveTypesCalls, 2, reason: '$failure');
          expect(stateOf(container).typeRefused, isTrue);
          expect(stateOf(container).reason, 'kept');
          expect(stateOf(container).dates, [DateTime(2026, 11, 18)]);

          // Picking a type (the same one or another) is the answer.
          form.setLeaveType('lt-annual');
          expect(stateOf(container).typeRefused, isFalse);
        }
      });

      test('an edit too', () async {
        repository.updateResult = Result.failure(refusals.first);
        final container = await withTypes();
        final form = formOf(container, 'req-7')
          ..seed(asOpened)
          ..setReason('typed by the user');

        expect(await form.submit(), isFalse);
        await Future<void>.delayed(Duration.zero);

        expect(repository.leaveTypesCalls, 2);
        expect(stateOf(container, 'req-7').typeRefused, isTrue);
        expect(stateOf(container, 'req-7').reason, 'typed by the user');
      });

      test('the reload fails: the list on screen is kept, not lost to an '
          'error', () async {
        repository.submitResult = Result.failure(refusals.first);
        final container = await withTypes();
        final before = container.read(leaveTypesNotifierProvider).value;
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 11, 18)])
          ..setReason('kept');
        repository.leaveTypesResult = const Result.failure(
          Failure.network(message: 'No internet connection'),
        );

        await form.submit();
        await Future<void>.delayed(Duration.zero);

        final types = container.read(leaveTypesNotifierProvider);
        expect(repository.leaveTypesCalls, 2);
        expect(types.hasError, isFalse);
        expect(types.value, before);
      });

      test('the reload answers a new list: the form gets it', () async {
        repository.submitResult = Result.failure(refusals.first);
        final container = await withTypes();
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 11, 18)])
          ..setReason('kept');
        repository.leaveTypesResult = const Result.success([]);

        await form.submit();
        await Future<void>.delayed(Duration.zero);

        expect(container.read(leaveTypesNotifierProvider).value, isEmpty);
      });
    });

    test('a half day the server refuses for the type: the types are asked '
        'for again, so the form learns the type takes whole days only; the '
        'type need not be picked again (#14)', () async {
      repository = FakeLeaveRepository()
        ..submitResult = const Result.failure(
          Failure.validation(message: 'leaveRuleHalfDayNotAllowed'),
        );
      final container = containerWith();
      container.listen(leaveTypesNotifierProvider, (_, _) {});
      await container.read(leaveTypesNotifierProvider.future);
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)])
        ..setReason('kept');

      expect(await form.submit(), isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(repository.leaveTypesCalls, 2);
      expect(stateOf(container).typeRefused, isFalse);
      expect(stateOf(container).reason, 'kept');
    });

    test('another refusal (too long, or an unrelated VALIDATION_ERROR) does '
        'not ask for the leave types again, and nothing has to be picked',
        () async {
      for (final failure in const [
        Failure.validation(message: 'leaveRuleTooLong|5'),
        Failure.validation(
          message: 'reason is required',
          code: 'VALIDATION_ERROR',
        ),
      ]) {
        repository = FakeLeaveRepository()
          ..submitResult = Result.failure(failure);
        final container = containerWith();
        container.listen(leaveTypesNotifierProvider, (_, _) {});
        await container.read(leaveTypesNotifierProvider.future);
        final form = formOf(container)
          ..setLeaveType('lt-annual')
          ..setDates([DateTime(2026, 11, 18)])
          ..setReason('kept');

        expect(await form.submit(), isFalse);
        await Future<void>.delayed(Duration.zero);

        expect(repository.leaveTypesCalls, 1, reason: '$failure');
        expect(stateOf(container).typeRefused, isFalse);
      }
    });

    test('a new request refused with the same code is not an edit: nothing '
        'is marked', () async {
      final container = containerWith();
      repository.submitResult = const Result.failure(
        Failure.validation(message: 'leaveInvalidStatus'),
      );
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)])
        ..setReason('kept');
      await form.submit();

      expect(stateOf(container).reason, 'kept');
    });

    test('once the server calls the edit out of date, the next seed starts '
        'from the request as it now is', () async {
      final container = containerWith();
      repository.updateResult = const Result.failure(
        Failure.validation(message: 'leaveChanged'),
      );
      final form = formOf(container, 'req-7')
        ..seed(asOpened)
        ..setReason('typed by the user');
      expect(await form.submit(), isFalse);

      // Still what the user sees while the page closes.
      expect(stateOf(container, 'req-7').reason, 'typed by the user');

      formOf(container, 'req-7').seed(asItIsNow);
      expect(stateOf(container, 'req-7').reason, 'as it is now');
      expect(stateOf(container, 'req-7').submission.hasError, isFalse);

      // And only that once.
      formOf(container, 'req-7')
        ..setReason('typed again')
        ..seed(asItIsNow);
      expect(stateOf(container, 'req-7').reason, 'typed again');
    });
  });

  group('files (#39)', () {
    test('an upload on its way: nothing can be sent', () async {
      final container = containerWith();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)]);
      final slow = Completer<void>();
      uploads.hold = slow;

      final adding = form.addFile(_photo);
      expect(stateOf(container).uploadingFiles, 1);
      expect(stateOf(container).hasValidShape, isFalse);
      slow.complete();
      await adding;

      expect(stateOf(container).hasValidShape, isTrue);
      expect(stateOf(container).files, hasLength(1));
    });

    test('a failed upload is kept to show; the files stay as they were',
        () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')
        ..seed(sampleLeaveRequest(id: 'req-7', attachments: const [_cert]));
      uploads.answer = const Result.failure(
        Failure.validation(message: 'uploadFileTooLarge'),
      );

      await form.addFile(_photo);

      final state = stateOf(container, 'req-7');
      expect(state.files, [_cert]);
      expect(state.filesChanged, isFalse);
      expect(state.uploadingFiles, 0);
      expect(state.fileFailure, isNotNull);
    });

    test('an upload that answers after the form was filled again is dropped',
        () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')
        ..seed(sampleLeaveRequest(id: 'req-7', reason: 'one'));
      final slow = Completer<void>();
      uploads.hold = slow;

      final adding = form.addFile(_photo);
      form.seed(sampleLeaveRequest(id: 'req-7', reason: 'two'));
      slow.complete();
      await adding;

      expect(stateOf(container, 'req-7').files, isEmpty);
    });

    test('while the request is being sent: no file is added or removed, so '
        'nothing lands after the save went out without it', () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')
        ..seed(sampleLeaveRequest(id: 'req-7', attachments: const [_cert]));
      final slow = Completer<void>();
      repository.holdUpdate = slow;

      final saving = form.submit();
      await form.addFile(_photo);
      form.removeFile(0);
      slow.complete();
      await saving;

      expect(uploads.calls, isEmpty);
      expect(repository.updateCalls.single.draft.attachments, isNull);
      expect(stateOf(container, 'req-7').files, [_cert]);
    });

    test('an upload on its way: submit sends nothing', () async {
      final container = containerWith();
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)]);
      final slow = Completer<void>();
      uploads.hold = slow;

      final adding = form.addFile(_photo);
      expect(await form.submit(), isFalse);
      slow.complete();
      await adding;

      expect(repository.submitCalls, isEmpty);
    });

    test('the block: a type that needs a file, until one is attached',
        () async {
      final container = containerWith();
      final form = formOf(container)..setDates([DateTime(2026, 11, 18)]);
      final needsFile = sampleLeaveType(id: 'lt-sick', requiresAttachment: true);

      LeaveFormBlock? block() => LeaveFormRules.block(
        state: stateOf(container),
        type: needsFile,
        remainingByYear: const {},
      );

      expect(block(), LeaveFormBlock.attachmentRequired);
      await form.addFile(_photo);
      expect(block(), isNull);
      form.removeFile(0);
      expect(block(), LeaveFormBlock.attachmentRequired);
    });
  });

  group('the most days a request may ask for (#104)', () {
    // Tuesday to Thursday: three working days.
    final threeDays = [
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 18),
      DateTime(2026, 11, 19),
    ];

    LeaveFormBlock? blockFor(double? max) {
      final container = containerWith();
      formOf(container).setDates(threeDays);
      expect(stateOf(container).totalDays, 3);
      return LeaveFormRules.block(
        state: stateOf(container),
        type: sampleLeaveType(maxDaysPerRequest: max),
        remainingByYear: const {},
      );
    }

    test('0 is no limit, as on the server: a 3-day request is not blocked',
        () {
      expect(blockFor(0), isNull);
    });

    test('a real limit still blocks: 2 days, 3 asked', () {
      expect(blockFor(2), LeaveFormBlock.maxDays);
    });

    test('no limit sent, or one below 0: not blocked', () {
      expect(blockFor(null), isNull);
      expect(blockFor(-1), isNull);
    });
  });
}

const _photo = LocalFile(path: '/phone/cert.jpg', name: 'cert.jpg');

const _cert = LeaveAttachment(
  id: 'att-1',
  url: 'https://files.nexton.work/a/medical.pdf',
  fileName: 'tenants/x/uploads/1_medical.pdf',
  originalName: 'medical.pdf',
  contentType: 'application/pdf',
);

/// A file the server kept by its storage key alone.
const _noUrl = LeaveAttachment(
  id: 'att-2',
  fileName: 'tenants/x/uploads/2_old.pdf',
  originalName: 'old.pdf',
);
