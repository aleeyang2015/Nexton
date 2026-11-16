import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/domain/entities/uploaded_attachment.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_attachment_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_balances_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_history_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_state.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/leave_test_doubles.dart';

/// The form's attachment slot, already holding [initial] — so a test never
/// opens a file chooser or uploads anything.
class _FixedAttachment extends LeaveAttachmentNotifier {
  _FixedAttachment(this.initial);

  final UploadedAttachment? initial;

  @override
  FutureOr<UploadedAttachment?> build(String? arg) => initial;
}

const _uploaded = UploadedAttachment(
  url: 'https://files.nexton.work/a/medical.pdf',
  fileName: 'tenants/x/uploads/1_medical.pdf',
  originalName: 'medical.pdf',
);

void main() {
  late FakeLeaveRepository repository;

  setUp(() => repository = FakeLeaveRepository());

  /// A container with the repository faked and the attachment slot holding
  /// [attachment].
  ProviderContainer containerWith({UploadedAttachment? attachment}) {
    final container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        leaveAttachmentNotifierProvider.overrideWith(
          () => _FixedAttachment(attachment),
        ),
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

    test('removeDate drops that day only', () {
      final container = containerWith();
      formOf(container)
        ..setDates([DateTime(2026, 11, 18), DateTime(2026, 11, 19)])
        ..removeDate(DateTime(2026, 11, 18));

      expect(stateOf(container).dates, [DateTime(2026, 11, 19)]);
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
      expect(draft.attachment, isNull);
      expect(repository.updateCalls, isEmpty);
    });

    test('carries the file in the attachment slot', () async {
      final container = containerWith(attachment: _uploaded);
      // The slot resolves on a microtask; let it settle before it is read.
      await container.read(leaveAttachmentNotifierProvider(null).future);
      final form = formOf(container)
        ..setLeaveType('lt-sick')
        ..setDates([DateTime(2026, 11, 18)]);

      await form.submit();

      expect(repository.submitCalls.single.attachment, _uploaded);
    });

    test('resets the form and clears the attachment slot after success',
        () async {
      final container = containerWith(attachment: _uploaded);
      await container.read(leaveAttachmentNotifierProvider(null).future);
      final form = formOf(container)
        ..setLeaveType('lt-annual')
        ..setDates([DateTime(2026, 11, 18)])
        ..setReason('Trip');

      await form.submit();

      expect(stateOf(container), const LeaveRequestFormState());
      expect(
        container.read(leaveAttachmentNotifierProvider(null)).valueOrNull,
        isNull,
      );
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

    test('with no new file, the draft carries none', () async {
      final container = containerWith();
      final form = formOf(container, 'req-7')..seed(existing);

      await form.submit();

      expect(repository.updateCalls.single.draft.attachment, isNull);
    });
  });

  group('after a successful submit, history and balances are loaded again',
      () {
    Future<ProviderContainer> watched() async {
      final container = containerWith();
      // Both lists are on screen, as they are on the time-off page.
      container
        ..listen(leaveHistoryNotifierProvider, (_, _) {})
        ..listen(leaveBalancesNotifierProvider, (_, _) {});
      await container.read(leaveBalancesNotifierProvider.future);
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
      await container.read(leaveBalancesNotifierProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(repository.myRequestsCalls, hasLength(2));
      expect(repository.balancesCalls, hasLength(2));
    });

    test('an edit', () async {
      final container = await watched();

      final form = formOf(container, 'req-7')..seed(sampleLeaveRequest(id: 'req-7'));
      await form.submit();
      await container.read(leaveBalancesNotifierProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(repository.myRequestsCalls, hasLength(2));
      expect(repository.balancesCalls, hasLength(2));
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
}
