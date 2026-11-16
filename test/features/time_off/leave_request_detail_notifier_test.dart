import 'dart:async';

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

  group('cancel', () {
    final cancelled = sampleLeaveRequest(
      id: 'req-7',
      status: LeaveStatus.cancelled,
    );

    test('success shows the cancelled request the server sent back, with no '
        'reload to wait on', () async {
      await settle();
      repository
        ..cancelResult = Result.success(cancelled)
        // A reload would fail; it is not needed.
        ..requestDetailResult = const Result.failure(offline);

      final result = await container.read(provider.notifier).cancel();

      expect(result.isSuccess, isTrue);
      expect(repository.cancelCalls, ['req-7']);
      expect(repository.requestDetailCalls, hasLength(1));
      expect(state().value!.status, LeaveStatus.cancelled);
    });

    for (final token in const [
      'leaveChanged',
      'leaveInvalidStatus',
      'leaveStartedContactHr',
    ]) {
      test('$token returns the failure and reloads the request', () async {
        await settle();
        final failure = Failure.validation(message: token);
        repository
          ..cancelResult = Result.failure(failure)
          ..requestDetailResult = Result.success(approved);

        final result = await container.read(provider.notifier).cancel();

        expect(result.failureOrNull, failure);
        expect(repository.requestDetailCalls, hasLength(2));
        expect(state().value!.status, LeaveStatus.approved);
      });
    }

    test('refused because the request is gone: the page has nothing to show',
        () async {
      await settle();
      repository
        ..cancelResult = const Result.failure(gone)
        ..requestDetailResult = const Result.failure(gone);

      await container.read(provider.notifier).cancel();

      expect(state().error, gone);
    });

    test('no signal returns the failure and does not reload', () async {
      await settle();
      repository.cancelResult = const Result.failure(offline);

      final result = await container.read(provider.notifier).cancel();

      expect(result.failureOrNull, offline);
      expect(repository.requestDetailCalls, hasLength(1));
      expect(state().value, pending);
    });

    test('an older refresh answered after the cancel does not put "pending" '
        'back', () async {
      await settle();
      final slow = _HeldDetail(repository);
      final held = ProviderContainer(
        overrides: [leaveRepositoryProvider.overrideWithValue(slow)],
      );
      addTearDown(held.dispose);
      held.listen(provider, (_, _) {});
      slow.release(Result.success(pending));
      await held.read(provider.future);

      // A refresh goes out, and is still on its way when the cancel lands.
      final refresh = held.read(provider.notifier).refresh();
      repository.cancelResult = Result.success(cancelled);
      await held.read(provider.notifier).cancel();
      slow.release(Result.success(pending));
      await refresh;

      expect(held.read(provider).value!.status, LeaveStatus.cancelled);
    });
  });

  group('when the status on screen changes', () {
    test('the waiting-request check is asked again, so the banner goes',
        () async {
      repository.pendingRequestResult = Result.success(pending);
      container.listen(leavePendingRequestNotifierProvider, (_, _) {});
      await container.read(leavePendingRequestNotifierProvider.future);
      await settle();
      expect(repository.pendingRequestCalls, 1);

      // HR approved it; a pull to refresh shows that.
      repository
        ..requestDetailResult = Result.success(approved)
        ..pendingRequestResult = const Result.success(null);
      await container.read(provider.notifier).refresh();
      await container.read(leavePendingRequestNotifierProvider.future);

      expect(repository.pendingRequestCalls, 2);
      expect(container.read(leavePendingRequestNotifierProvider).value, isNull);
    });

    test('a refresh that shows the same status asks nothing else', () async {
      container.listen(leavePendingRequestNotifierProvider, (_, _) {});
      await container.read(leavePendingRequestNotifierProvider.future);
      await settle();

      await container.read(provider.notifier).refresh();

      expect(repository.pendingRequestCalls, 1);
      expect(repository.myRequestsCalls, isEmpty);
    });

    test('with no history list on screen, none is loaded', () async {
      await settle();
      repository.requestDetailResult = Result.success(approved);

      await container.read(provider.notifier).refresh();
      await Future<void>.delayed(Duration.zero);

      expect(repository.myRequestsCalls, isEmpty);
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

/// A repository whose by-id load waits until the test releases it, so two
/// answers can be made to arrive out of order.
class _HeldDetail extends FakeLeaveRepository {
  _HeldDetail(this._inner);

  final FakeLeaveRepository _inner;
  final _waiting = <Completer<Result<LeaveRequest>>>[];

  /// Answers the oldest load still waiting; if none is, the next one.
  void release(Result<LeaveRequest> result) {
    if (_waiting.isEmpty) {
      _next = result;
    } else {
      _waiting.removeAt(0).complete(result);
    }
  }

  Result<LeaveRequest>? _next;

  @override
  FutureResult<LeaveRequest> requestDetail(String id) {
    final next = _next;
    if (next != null) {
      _next = null;
      return Future.value(next);
    }
    final completer = Completer<Result<LeaveRequest>>();
    _waiting.add(completer);
    return completer.future;
  }

  @override
  FutureResult<LeaveRequest> cancel(String id) => _inner.cancel(id);
}
