import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/overtime/data/datasources/ot_error_code.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_ask_notifier.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_ask_state.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_list_notifier.dart';

import '../../support/overtime_test_doubles.dart';

/// The Ask OT form's state: what is sent, what the form warns about, and
/// what each answer does.
void main() {
  late FakeOtRepository repository;
  late ProviderContainer container;

  /// Wednesday 11 November 2026, 10:00.
  final now = DateTime(2026, 11, 11, 10);

  setUp(() {
    repository = FakeOtRepository();
    container = ProviderContainer(
      overrides: [
        otRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.listen(otAskNotifierProvider, (_, _) {});
  });

  OtAskState state() => container.read(otAskNotifierProvider);
  OtAskNotifier form() => container.read(otAskNotifierProvider.notifier);

  void fill({
    DateTime? date,
    (int, int) start = (18, 0),
    (int, int) end = (20, 0),
    String reason = '',
  }) {
    form()
      ..setDate(date ?? DateTime(2026, 11, 14))
      ..setStart(start.$1, start.$2)
      ..setEnd(end.$1, end.$2)
      ..setReason(reason);
  }

  group('the form', () {
    test('starts on today, with no times and nothing to send yet', () {
      expect(state().workDate, DateTime(2026, 11, 11));
      expect(state().startTime, isNull);
      expect(state().endTime, isNull);
      expect(state().canSend, isFalse);
    });

    test('both times picked: it can be sent; times are HH:MM', () {
      form()
        ..setStart(8, 5)
        ..setEnd(9, 0);

      expect(state().startTime, '08:05');
      expect(state().endTime, '09:00');
      expect(state().canSend, isTrue);
    });

    test('an end at or before the start ends the next day', () {
      fill(start: (22, 0), end: (2, 0));
      expect(state().endsNextDay, isTrue);

      fill(start: (18, 0), end: (20, 0));
      expect(state().endsNextDay, isFalse);

      // Equal is not "the next day": the server refuses it.
      fill(start: (18, 0), end: (18, 0));
      expect(state().endsNextDay, isFalse);
    });

    test('a date before today warns; today and later do not', () {
      form().setDate(DateTime(2026, 11, 10, 23, 59));
      expect(state().isPastDate, isTrue);

      form().setDate(DateTime(2026, 11, 11));
      expect(state().isPastDate, isFalse);

      form().setDate(DateTime(2026, 11, 14));
      expect(state().isPastDate, isFalse);
    });

    test('a date is kept as a day, with no time', () {
      form().setDate(DateTime(2026, 11, 14, 17, 30));

      expect(state().workDate, DateTime(2026, 11, 14));
    });

    test('changing a field clears the last refusal and the End error', () async {
      fill();
      repository.askAnswer = (_) => const Result.failure(
        Failure.validation(message: OtErrorCode.tokenOverlapsShift),
      );
      await form().submit();
      expect(state().refusal, isNotNull);

      form().setStart(17, 0);

      expect(state().refusal, isNull);
      expect(state().endError, isFalse);
    });
  });

  group('sending', () {
    test('sends the day, the times and the reason trimmed', () async {
      fill(reason: '  ນັບສະຕັອກ  ');

      await form().submit();

      final draft = repository.asked.single;
      expect(draft.workDate, DateTime(2026, 11, 14));
      expect(draft.startTime, '18:00');
      expect(draft.endTime, '20:00');
      expect(draft.reason, 'ນັບສະຕັອກ');
    });

    test('an empty reason is sent as none', () async {
      fill(reason: '   ');

      await form().submit();

      expect(repository.asked.single.reason, isNull);
    });

    test('a past date still sends: the warning is only a warning', () async {
      fill(date: DateTime(2026, 11, 9));

      final sent = await form().submit();

      expect(sent, isNotNull);
      expect(repository.asked, hasLength(1));
    });

    test('nothing is sent without both times', () async {
      form().setStart(18, 0);

      expect(await form().submit(), isNull);
      expect(repository.asked, isEmpty);
    });

    test('a double tap on Send creates one request', () async {
      fill();
      final hold = Completer<void>();
      repository.holdAsk = hold;

      final first = form().submit();
      expect(state().sending, isTrue);
      expect(state().canSend, isFalse);
      final second = await form().submit();
      hold.complete();
      await first;

      expect(second, isNull);
      expect(repository.asked, hasLength(1));
      expect(state().sending, isFalse);
    });

    test('201: the new request comes back, for the page to open', () async {
      fill();

      final sent = await form().submit();

      expect(sent?.id, 'ot-new');
      expect(state().refusal, isNull);
    });

    test('201 with the OT list open underneath: the list asks again, so the '
        'new request is in it on return', () async {
      container.listen(otListNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final before = repository.listCalls.length;
      fill();

      await form().submit();

      expect(repository.listCalls.length, before + 1);
      expect(repository.listCalls.last.page, 1);
    });
  });

  group('refusals keep what was typed', () {
    for (final token in [
      OtErrorCode.tokenDisabled,
      OtErrorCode.tokenNotEligible,
      OtErrorCode.tokenTooFarBack,
      OtErrorCode.tokenOverlap,
      OtErrorCode.tokenOverlapsShift,
      OtErrorCode.tokenEmployeeLeft,
    ]) {
      test('409 $token is the refusal, and the form stays', () async {
        fill(start: (16, 0), end: (19, 0), reason: 'stock');
        repository.askAnswer = (_) =>
            Result.failure(Failure.validation(message: token));

        final sent = await form().submit();

        expect(sent, isNull);
        expect(state().refusal?.message, token);
        expect(state().startTime, '16:00');
        expect(state().endTime, '19:00');
        expect(state().reason, 'stock');
        expect(state().sending, isFalse);
      });
    }

    test('422 on end_time: the End error, not a refusal', () async {
      fill(start: (18, 0), end: (18, 0));
      repository.askAnswer = (_) => const Result.failure(
        Failure.validation(
          message: 'end_time must differ',
          field: 'end_time',
          code: ApiErrorCodes.validationError,
        ),
      );

      await form().submit();

      expect(state().endError, isTrue);
      expect(state().refusal, isNull);
    });

    test('400 EMPLOYEE_NOT_FOUND, no signal, a server error: the refusal',
        () async {
      for (final failure in const [
        Failure.validation(
          message: 'employee not found',
          code: ApiErrorCodes.employeeNotFound,
        ),
        Failure.network(message: 'offline', errorCode: ApiErrorCodes.noInternet),
        Failure.server(message: 'boom', statusCode: 500),
      ]) {
        fill();
        repository.askAnswer = (_) => Result.failure(failure);

        await form().submit();

        expect(state().refusal, failure);
        expect(state().endError, isFalse);
      }
    });
  });
}
