import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/overtime/data/datasources/ot_error_code.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_list_notifier.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_posts_notifier.dart';

import '../../support/overtime_test_doubles.dart';

/// HR's open posts for the user's department, and joining one.
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

  OtPostsNotifier posts() => container.read(otPostsNotifierProvider.notifier);
  List<String> ids() =>
      container
          .read(otPostsNotifierProvider)
          .posts
          .valueOrNull
          ?.items
          .map((p) => p.id)
          .toList() ??
      [];

  Future<void> settle() async {
    container.listen(otPostsNotifierProvider, (_, _) {});
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// [total] posts, 20 a page.
  void serveMany(int total) => repository.postsAnswer = (page) {
    final pages = (total / 20).ceil();
    final from = (page - 1) * 20;
    final to = (from + 20).clamp(0, total);
    return Result.success(
      OtPage(
        items: [for (var i = from; i < to; i++) samplePost('post-$i')],
        page: page,
        totalPages: pages,
      ),
    );
  };

  group('the list', () {
    test('asks for page 1 and keeps the server\'s order', () async {
      repository.postsAnswer = (page) => Result.success(
        OtPage(
          items: [samplePost('soon'), samplePost('later')],
          page: page,
          totalPages: 1,
        ),
      );

      await settle();

      expect(repository.postPages, [1]);
      expect(ids(), ['soon', 'later']);
    });

    test('load more by page number, then it stops', () async {
      serveMany(45);
      await settle();

      await posts().loadMore();
      await posts().loadMore();
      await posts().loadMore();

      expect(repository.postPages, [1, 2, 3]);
      expect(ids(), hasLength(45));
    });

    test('refresh asks for page 1 again; a failed one keeps the posts', () async {
      serveMany(25);
      await settle();
      await posts().loadMore();

      repository.postsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      expect(await posts().refresh(), isFalse);
      expect(ids(), hasLength(25));

      serveMany(3);
      expect(await posts().refresh(), isTrue);
      expect(ids(), hasLength(3));
    });

    test('a reload that fails while a next page was on its way leaves the '
        'list ready to load more, not spinning', () async {
      serveMany(40);
      await settle();
      final hold = Completer<void>();
      repository.holdPosts = hold;
      final more = posts().loadMore();
      await Future<void>.delayed(Duration.zero);

      repository.postsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      expect(await posts().refresh(), isFalse);
      hold.complete();
      await more;

      final list = container.read(otPostsNotifierProvider).posts.valueOrNull!;
      expect(list.loadingMore, isFalse);
      expect(list.canLoadMore, isTrue);
    });

    test('a failed first page is the error; retry loads it', () async {
      repository.postsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      await settle();
      expect(container.read(otPostsNotifierProvider).posts.hasError, isTrue);

      serveMany(1);
      posts().retry();
      await settle();

      expect(ids(), ['post-0']);
    });
  });

  group('join', () {
    test('201: the posts reload, so the card shows the join', () async {
      serveMany(1);
      await settle();
      repository.postsAnswer = (page) => Result.success(
        OtPage(
          items: [
            samplePost('post-0', myJoin: sampleOt('ot-j', status: OtStatus.pending)),
          ],
          page: page,
          totalPages: 1,
        ),
      );

      final result = await posts().join('post-0');

      expect(result?.isSuccess, isTrue);
      expect(repository.joins, ['post-0']);
      expect(repository.postPages, [1, 1]);
      expect(
        container.read(otPostsNotifierProvider).posts.valueOrNull?.items.single.myJoin?.status,
        OtStatus.pending,
      );
    });

    test('201 with the OT list open: it reloads too, so the join is there',
        () async {
      container.listen(otListNotifierProvider, (_, _) {});
      serveMany(1);
      await settle();
      final before = repository.listCalls.length;

      await posts().join('post-0');

      expect(repository.listCalls.length, before + 1);
    });

    for (final (label, failure) in [
      ('OT_FULL', const Failure.validation(message: OtErrorCode.tokenFull)),
      (
        'OT_JOIN_CLOSED',
        const Failure.validation(message: OtErrorCode.tokenJoinClosed),
      ),
      ('404', const Failure.network(message: 'not found', statusCode: 404)),
    ]) {
      test('$label: the refusal comes back, and the posts reload', () async {
        serveMany(1);
        await settle();
        repository.joinAnswer = (_) => Result.failure(failure);

        final result = await posts().join('post-0');

        expect(result?.failureOrNull, failure);
        expect(repository.postPages, [1, 1]);
      });
    }

    test('an ask refusal (overlap, OT off), or a lost answer: the refusal, '
        'and the posts reload (the card may have changed, or the join been '
        'made)', () async {
      serveMany(1);
      await settle();
      for (final failure in const [
        Failure.validation(message: OtErrorCode.tokenOverlap),
        Failure.validation(message: OtErrorCode.tokenDisabled),
        Failure.network(message: 'timeout'),
      ]) {
        repository.joinAnswer = (_) => Result.failure(failure);
        final before = repository.postPages.length;

        final result = await posts().join('post-0');

        expect(result?.failureOrNull, failure);
        expect(repository.postPages.length, before + 1);
      }
    });

    test('a post the card no longer offers Join for sends nothing', () async {
      repository.postsAnswer = (page) => Result.success(
        OtPage(
          items: [samplePost('post-0', full: true)],
          page: page,
          totalPages: 1,
        ),
      );
      await settle();

      expect(await posts().join('post-0'), isNull);
      expect(repository.joins, isEmpty);
    });

    test('the page closed while a join was on its way: the OT list still '
        'learns of it', () async {
      final list = container.listen(otListNotifierProvider, (_, _) {});
      addTearDown(list.close);
      serveMany(1);
      final page = container.listen(otPostsNotifierProvider, (_, _) {});
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final before = repository.listCalls.length;
      final hold = Completer<void>();
      repository.holdJoin = hold;

      final pending = container.read(otPostsNotifierProvider.notifier).join('post-0');
      page.close();
      await Future<void>.delayed(Duration.zero);
      hold.complete();
      await pending;

      expect(repository.joins, ['post-0']);
      expect(repository.listCalls.length, before + 1);
    });

    test('one join at a time, across cards: a second tap sends nothing',
        () async {
      serveMany(2);
      await settle();
      final hold = Completer<void>();
      repository.holdJoin = hold;

      final first = posts().join('post-0');
      expect(container.read(otPostsNotifierProvider).joiningId, 'post-0');
      expect(await posts().join('post-0'), isNull);
      expect(await posts().join('post-1'), isNull);
      hold.complete();
      await first;

      expect(repository.joins, ['post-0']);
      expect(container.read(otPostsNotifierProvider).joiningId, isNull);
    });
  });
}
