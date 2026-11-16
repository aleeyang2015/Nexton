import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_history_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_history_state.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  late FakeLeaveRepository repository;
  late ProviderContainer container;

  final pending = sampleLeaveRequest(id: 'req-1');

  setUp(() {
    repository = FakeLeaveRepository()
      ..myRequestsResult = Result.success([pending]);
    container = ProviderContainer(
      overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  LeaveHistoryState state() => container.read(leaveHistoryNotifierProvider);

  LeaveHistoryNotifier notifier() =>
      container.read(leaveHistoryNotifierProvider.notifier);

  /// Starts the notifier, keeps it alive, and lets its first load finish.
  Future<void> settle() async {
    container.listen(leaveHistoryNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('cancel', () {
    test('success returns the request and reloads the list', () async {
      await settle();
      final before = repository.myRequestsCalls.length;

      final result = await notifier().cancel('req-1');

      expect(result.isSuccess, isTrue);
      expect(repository.cancelCalls, ['req-1']);
      expect(repository.myRequestsCalls, hasLength(before + 1));
      expect(state().cancellingIds, isEmpty);
    });

    test('marks the request as cancelling while the call is in flight',
        () async {
      await settle();

      final call = notifier().cancel('req-1');

      expect(state().cancellingIds, {'req-1'});
      await call;
      expect(state().cancellingIds, isEmpty);
    });

    for (final token in const [
      'leaveChanged',
      'leaveInvalidStatus',
      'leaveRequestGone',
    ]) {
      test('$token returns the failure and reloads the list, so it shows the '
          'request as it now is', () async {
        final failure = Failure.validation(message: token);
        repository.cancelResult = Result.failure(failure);
        await settle();
        final before = repository.myRequestsCalls.length;
        // HR approved it meanwhile.
        repository.myRequestsResult = Result.success([
          sampleLeaveRequest(id: 'req-1', status: LeaveStatus.approved),
        ]);

        final result = await notifier().cancel('req-1');

        expect(result.failureOrNull, failure);
        expect(repository.myRequestsCalls, hasLength(before + 1));
        expect(
          state().requests.valueOrNull!.single.status,
          LeaveStatus.approved,
        );
        expect(state().cancellingIds, isEmpty);
      });
    }

    test('any other failure returns the failure and leaves the list alone',
        () async {
      for (final failure in const [
        Failure.network(message: 'offline'),
        Failure.server(message: 'boom', statusCode: 500),
        Failure.validation(message: 'Not allowed', code: 'SOMETHING_NEW'),
        Failure.validation(message: 'leaveNotApprover'),
      ]) {
        repository.cancelResult = Result.failure(failure);
        await settle();
        final before = repository.myRequestsCalls.length;

        final result = await notifier().cancel('req-1');

        expect(result.failureOrNull, failure, reason: '$failure');
        expect(repository.myRequestsCalls, hasLength(before));
        expect(state().cancellingIds, isEmpty);
      }
    });
  });
}
