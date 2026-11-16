import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_pending_request_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_detail_notifier.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  late FakeLeaveRepository repository;
  late ProviderContainer container;

  final pending = sampleLeaveRequest(id: 'req-7');
  final approved = sampleLeaveRequest(
    id: 'req-7',
    status: LeaveStatus.approved,
  );
  const gone = Failure.validation(message: 'leaveRequestGone');
  const offline = Failure.network(message: 'offline');

  setUp(() {
    repository = FakeLeaveRepository()
      ..requestDetailResult = Result.success(pending);
    container = ProviderContainer(
      overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  final provider = leaveRequestDetailNotifierProvider('req-7');

  /// Starts the load, keeps the auto-dispose provider alive, and waits for
  /// the first answer.
  Future<void> settle() async {
    container.listen(provider, (_, _) {});
    await container.read(provider.future).then((_) {}, onError: (_) {});
  }

  AsyncValue<LeaveRequest> state() => container.read(provider);

  group('loading by id', () {
    test('asks for that id and holds the request', () async {
      await settle();

      expect(repository.requestDetailCalls, ['req-7']);
      expect(state().value, pending);
    });

    test('each id is its own load', () async {
      await settle();
      container.listen(leaveRequestDetailNotifierProvider('req-8'), (_, _) {});
      await container.read(
        leaveRequestDetailNotifierProvider('req-8').future,
      );

      expect(repository.requestDetailCalls, ['req-7', 'req-8']);
    });

    test('a 404 is kept as "the request is gone"', () async {
      repository.requestDetailResult = const Result.failure(gone);

      await settle();

      expect(state().hasError, isTrue);
      expect(state().error, gone);
      expect(state().hasValue, isFalse);
    });

    test('no signal is kept as the failure, to be retried', () async {
      repository.requestDetailResult = const Result.failure(offline);

      await settle();

      expect(state().error, offline);
    });
  });

  group('refresh', () {
    test('loads again and shows the request as it now is', () async {
      await settle();
      repository.requestDetailResult = Result.success(approved);

      final failure = await container.read(provider.notifier).refresh();

      expect(failure, isNull);
      expect(repository.requestDetailCalls, hasLength(2));
      expect(state().value!.status, LeaveStatus.approved);
    });

    test('the request on screen stays while the new one is on its way', () async {
      await settle();
      final seen = <AsyncValue<LeaveRequest>>[];
      container.listen(provider, (_, next) => seen.add(next));

      await container.read(provider.notifier).refresh();

      expect(seen.where((value) => !value.hasValue), isEmpty);
    });

    test('a reload with no signal keeps the request already shown, and '
        'returns the failure', () async {
      await settle();
      repository.requestDetailResult = const Result.failure(offline);

      final failure = await container.read(provider.notifier).refresh();

      expect(failure, offline);
      expect(state().value, pending);
      expect(state().hasError, isFalse);
    });

    test('a reload that says the request is gone replaces it', () async {
      await settle();
      repository.requestDetailResult = const Result.failure(gone);

      final failure = await container.read(provider.notifier).refresh();

      expect(failure, gone);
      expect(state().error, gone);
    });

    test('after a failed first load, a refresh that works shows the request',
        () async {
      repository.requestDetailResult = const Result.failure(offline);
      await settle();
      repository.requestDetailResult = Result.success(pending);

      await container.read(provider.notifier).refresh();

      expect(state().value, pending);
    });

    test('a refresh answered after the page closed sets nothing', () async {
      final sub = container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      final call = notifier.refresh();
      sub.close();
      await container.pump();

      expect(await call, isNull);
    });
  });

  group('the waiting request', () {
    final waiting = leavePendingRequestNotifierProvider;

    test('holds the pending request when there is one', () async {
      repository.pendingRequestResult = Result.success(pending);
      container.listen(waiting, (_, _) {});

      expect(await container.read(waiting.future), pending);
      expect(repository.pendingRequestCalls, 1);
    });

    test('is null when there is none', () async {
      container.listen(waiting, (_, _) {});

      expect(await container.read(waiting.future), isNull);
    });

    test('a failed check reads as none: no banner, the server still refuses',
        () async {
      repository.pendingRequestResult = const Result.failure(offline);
      container.listen(waiting, (_, _) {});

      expect(await container.read(waiting.future), isNull);
      expect(container.read(waiting).hasError, isFalse);
    });
  });
}
