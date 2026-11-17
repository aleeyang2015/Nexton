import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_list_notifier.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_list_state.dart';

import '../../support/overtime_test_doubles.dart';

/// The OT list's state: which requests to ask for, page after page, and
/// which answers count.
void main() {
  late FakeOtRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeOtRepository();
    container = ProviderContainer(
      overrides: [otRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  OtListState state() => container.read(otListNotifierProvider);
  OtListNotifier notifier() => container.read(otListNotifierProvider.notifier);

  Future<void> settle() async {
    container.listen(otListNotifierProvider, (_, _) {});
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  List<String> ids() =>
      state().requests.valueOrNull?.items.map((r) => r.id).toList() ?? [];

  group('the first page', () {
    test('asks for all statuses and every month, page 1', () async {
      await settle();

      expect(repository.listCalls.single, (
        status: null,
        month: null,
        page: 1,
        perPage: OtPage.defaultPerPage,
      ));
    });

    test('keeps the server\'s order (newest asked first)', () async {
      repository.myRequestsAnswer = (_) => Result.success(
        OtPage(
          items: [sampleOt('ot-new'), sampleOt('ot-old')],
          page: 1,
          totalPages: 1,
        ),
      );

      await settle();

      expect(ids(), ['ot-new', 'ot-old']);
    });

    test('loading until it answers', () async {
      repository.holdMyRequests = Completer<void>();

      await settle();
      expect(state().requests.isLoading, isTrue);
    });
  });

  group('filters', () {
    test('each chip asks again with its status, from page 1', () async {
      await settle();

      for (final status in [
        OtStatus.pending,
        OtStatus.approved,
        OtStatus.rejected,
        OtStatus.cancelled,
      ]) {
        notifier().setStatus(status);
        await settle();
        expect(repository.listCalls.last.status, status);
        expect(repository.listCalls.last.page, 1);
        expect(state().status, status);
      }

      notifier().setStatus(null);
      await settle();
      expect(repository.listCalls.last.status, isNull);
    });

    test('a month asks for that month; cleared asks for every month',
        () async {
      await settle();

      notifier().setMonth(DateTime(2026, 3, 17));
      await settle();
      expect(repository.listCalls.last.month, DateTime(2026, 3));
      expect(state().month, DateTime(2026, 3));

      notifier().setMonth(null);
      await settle();
      expect(repository.listCalls.last.month, isNull);
      expect(state().month, isNull);
    });

    test('choosing the filter already on asks for nothing', () async {
      await settle();

      notifier().setStatus(null);
      notifier().setMonth(null);
      await settle();

      expect(repository.listCalls, hasLength(1));
    });

    test('a fast chip change does not mix rows of two filters', () async {
      await settle();
      final slow = Completer<void>();
      repository
        ..holdMyRequests = slow
        ..myRequestsAnswer = (call) => Result.success(
          OtPage(
            items: [sampleOt('ot-${call.status?.name ?? 'all'}')],
            page: 1,
            totalPages: 1,
          ),
        );

      notifier().setStatus(OtStatus.pending);
      await settle();
      notifier().setStatus(OtStatus.approved);
      await settle();
      slow.complete();
      await settle();

      expect(state().status, OtStatus.approved);
      expect(ids(), ['ot-approved']);
    });
  });

  group('load more, by page number', () {
    test('45 requests at 20 a page: page 2, then page 3, then it stops',
        () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();
      expect(ids(), hasLength(20));

      await notifier().loadMore();
      expect(ids(), hasLength(40));
      await notifier().loadMore();
      expect(ids(), hasLength(45));
      await notifier().loadMore();

      expect(repository.listCalls.map((c) => c.page), [1, 2, 3]);
      expect(ids().first, 'ot-0');
      expect(ids().last, 'ot-44');
      expect(state().requests.valueOrNull!.hasMore, isFalse);
    });

    test('load more keeps the filters', () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();
      notifier().setStatus(OtStatus.approved);
      notifier().setMonth(DateTime(2026, 11));
      await settle();

      await notifier().loadMore();

      expect(repository.listCalls.last, (
        status: OtStatus.approved,
        month: DateTime(2026, 11),
        page: 2,
        perPage: OtPage.defaultPerPage,
      ));
    });

    test('one page at a time: a second call while one is on its way does '
        'nothing', () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();
      final hold = Completer<void>();
      repository.holdMyRequests = hold;

      final first = notifier().loadMore();
      await notifier().loadMore();
      hold.complete();
      await first;

      expect(repository.listCalls.map((c) => c.page), [1, 2]);
    });

    test('a page that fails keeps the rows and waits for Retry, which asks '
        'for the same page', () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();

      repository.myRequestsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      await notifier().loadMore();
      expect(ids(), hasLength(20));
      expect(state().requests.valueOrNull!.loadMoreError, isNotNull);

      // Scrolling to the end again asks for nothing until Retry.
      await notifier().loadMore();
      expect(repository.listCalls, hasLength(2));

      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await notifier().retryLoadMore();

      expect(repository.listCalls.map((c) => c.page), [1, 2, 2]);
      expect(ids(), hasLength(40));
    });

    test('a next page for a filter the user has left is dropped', () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();
      final slow = Completer<void>();
      repository.holdMyRequests = slow;

      final more = notifier().loadMore();
      await Future<void>.delayed(Duration.zero);
      repository.myRequestsAnswer = (_) => Result.success(
        OtPage(items: [sampleOt('ot-cancelled')], page: 1, totalPages: 1),
      );
      notifier().setStatus(OtStatus.cancelled);
      await settle();
      slow.complete();
      await more;

      expect(ids(), ['ot-cancelled']);
    });
  });

  group('refresh', () {
    test('asks for page 1 again with the same filters, and keeps the rows '
        'on screen meanwhile', () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();
      notifier().setStatus(OtStatus.pending);
      await settle();
      await notifier().loadMore();
      final hold = Completer<void>();
      repository.holdMyRequests = hold;

      final done = notifier().refresh();
      await Future<void>.delayed(Duration.zero);
      expect(ids(), hasLength(40));
      hold.complete();
      await done;

      expect(repository.listCalls.last, (
        status: OtStatus.pending,
        month: null,
        page: 1,
        perPage: OtPage.defaultPerPage,
      ));
      expect(ids(), hasLength(20));
    });
  });

  group('refresh that fails, retry twice, rows repeated', () {
    test('a refresh that fails keeps the rows on screen and says so', () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();
      await notifier().loadMore();

      repository.myRequestsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      final loaded = await notifier().refresh();

      expect(loaded, isFalse);
      expect(state().requests.hasError, isFalse);
      expect(ids(), hasLength(40));
    });

    test('a refresh that fails while a next page was on its way leaves the '
        'list ready to load more, not spinning', () async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      await settle();
      final hold = Completer<void>();
      repository.holdMyRequests = hold;
      final more = notifier().loadMore();
      await Future<void>.delayed(Duration.zero);

      repository.myRequestsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      expect(await notifier().refresh(), isFalse);
      hold.complete();
      await more;

      final list = state().requests.valueOrNull!;
      expect(list.loadingMore, isFalse);
      expect(list.canLoadMore, isTrue);
    });

    test('a refresh that works says so', () async {
      await settle();

      expect(await notifier().refresh(), isTrue);
    });

    test('Retry tapped twice asks once', () async {
      repository.myRequestsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      await settle();
      repository.holdMyRequests = Completer<void>();

      notifier().retry();
      notifier().retry();

      expect(repository.listCalls, hasLength(2));
    });

    test('a row repeated on the next page (one added at the top meanwhile) '
        'is shown once', () async {
      repository.myRequestsAnswer = (call) => Result.success(
        OtPage(
          items: call.page == 1
              ? [sampleOt('ot-c'), sampleOt('ot-b')]
              : [sampleOt('ot-b'), sampleOt('ot-a')],
          page: call.page,
          totalPages: 2,
        ),
      );
      await settle();

      await notifier().loadMore();

      expect(ids(), ['ot-c', 'ot-b', 'ot-a']);
    });
  });

  group('when the list cannot load', () {
    test('no employee linked: the failure keeps its code', () async {
      repository.myRequestsAnswer = (_) => const Result.failure(
        Failure.validation(
          message: 'employee not found',
          code: ApiErrorCodes.employeeNotFound,
        ),
      );

      await settle();

      final error = state().requests.error;
      expect(error, isA<ValidationFailure>());
      expect((error as ValidationFailure).code, ApiErrorCodes.employeeNotFound);
      expect(state().requests.isLoading, isFalse);
    });

    test('no signal, then retry loads it', () async {
      repository.myRequestsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      await settle();
      expect(state().requests.hasError, isTrue);

      repository.myRequestsAnswer = (_) => Result.success(
        OtPage(items: [sampleOt('ot-1')], page: 1, totalPages: 1),
      );
      notifier().retry();
      await settle();

      expect(ids(), ['ot-1']);
    });
  });
}
