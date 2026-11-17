import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/overtime/data/datasources/ot_error_code.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_post.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_posts_page.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_request_detail_page.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/overtime_test_doubles.dart';
import '../../support/profile_test_doubles.dart';

/// HR's OT posts page: the cards, joining, and what it says otherwise.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();
  late FakeOtRepository repository;

  setUp(() => repository = FakeOtRepository());

  void serve(List<OtPost> posts) => repository.postsAnswer = (page) =>
      Result.success(OtPage(items: posts, page: page, totalPages: 1));

  Future<void> openPosts(WidgetTester tester, {String locale = 'en'}) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.overtime,
      routes: overtimeRoutes,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          otRepositoryProvider.overrideWithValue(repository),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          otOwnEmployeeIdProvider.overrideWithValue('emp-noy'),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push(AppRoutes.otPosts);
    await tester.pumpAndSettle();
  }

  Finder button(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );

  group('a card', () {
    testWidgets('day, window, piece and pay, places left, closing time and '
        'reason, in Lao', (tester) async {
      serve([samplePost('post-1')]);

      await openPosts(tester, locale: 'lo');

      expect(find.text('ປະກາດໂອທີ'), findsOneWidget);
      expect(find.text('07/11/2026'), findsOneWidget);
      expect(find.text('08:00–12:00'), findsOneWidget);
      expect(find.text('08:00–12:00 · 200%'), findsOneWidget);
      expect(find.text('ຍັງເຫຼືອ 3 ບ່ອນ'), findsOneWidget);
      expect(find.text('ປິດຮັບ 06/11 17:00'), findsOneWidget);
      expect(find.text('Banquet prep'), findsOneWidget);
      expect(button('ເຂົ້າຮ່ວມ'), findsOneWidget);
    });

    testWidgets('no limit; and no deadline closes at the start', (
      tester,
    ) async {
      serve([samplePost('post-1', seats: null, noDeadline: true)]);

      await openPosts(tester, locale: 'lo');

      expect(find.text('ບໍ່ຈຳກັດຈຳນວນ'), findsOneWidget);
      expect(find.text('ປິດຮັບ 07/11 08:00'), findsOneWidget);
    });

    testWidgets('more accepted than places never reads below 0', (
      tester,
    ) async {
      serve([samplePost('post-1', seats: 2, accepted: 3, full: true)]);

      await openPosts(tester);

      expect(find.text(en.otPostPlacesLeft(0)), findsOneWidget);
      expect(button(en.otPostFull), findsOneWidget);
    });

    testWidgets('closed to joining: "Cannot join now", not tappable', (
      tester,
    ) async {
      serve([samplePost('post-1', joinOpen: false)]);

      await openPosts(tester);

      final b = tester.widget<ButtonStyleButton>(button(en.otPostCannotJoin));
      expect(b.onPressed, isNull);
    });
  });

  group('join', () {
    testWidgets('Join → confirm → "Waiting for HR", with the toast', (
      tester,
    ) async {
      serve([samplePost('post-1')]);
      await openPosts(tester, locale: 'lo');
      serve([
        samplePost('post-1', myJoin: sampleOt('ot-j', status: OtStatus.pending)),
      ]);

      await tester.tap(button('ເຂົ້າຮ່ວມ'));
      await tester.pumpAndSettle();
      expect(find.text('ຂໍເຂົ້າຮ່ວມໂອທີນີ້ບໍ?'), findsOneWidget);
      await tester.tap(find.text('ເຂົ້າຮ່ວມ').last);
      await tester.pumpAndSettle();

      expect(repository.joins, ['post-1']);
      expect(find.text('ສົ່ງຄຳຂໍເຂົ້າຮ່ວມແລ້ວ, ລໍຖ້າຝ່າຍບຸກຄະລາກອນ'), findsOneWidget);
      expect(button('ລໍຖ້າຝ່າຍບຸກຄະລາກອນ'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('"Back" in the question sends nothing', (tester) async {
      serve([samplePost('post-1')]);
      await openPosts(tester);

      await tester.tap(button(en.otPostJoin));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.back));
      await tester.pumpAndSettle();

      expect(repository.joins, isEmpty);
    });

    testWidgets('OT_FULL: the Lao text, and the list reloads', (tester) async {
      serve([samplePost('post-1')]);
      await openPosts(tester, locale: 'lo');
      repository.joinAnswer = (_) => const Result.failure(
        Failure.validation(message: OtErrorCode.tokenFull),
      );
      serve([samplePost('post-1', full: true, accepted: 5)]);

      await tester.tap(button('ເຂົ້າຮ່ວມ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ເຂົ້າຮ່ວມ').last);
      await tester.pumpAndSettle();

      expect(find.text('ບ່ອນເຕັມແລ້ວ.'), findsOneWidget);
      expect(repository.postPages, [1, 1]);
      expect(button('ເຕັມແລ້ວ'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a post gone or of another department: its own text', (
      tester,
    ) async {
      serve([samplePost('post-1')]);
      await openPosts(tester, locale: 'lo');
      repository.joinAnswer = (_) => const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );

      await tester.tap(button('ເຂົ້າຮ່ວມ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ເຂົ້າຮ່ວມ').last);
      await tester.pumpAndSettle();

      expect(find.text(lo.otPostGone), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('while a join is on its way, every Join waits: one join', (
      tester,
    ) async {
      serve([samplePost('post-1'), samplePost('post-2')]);
      await openPosts(tester);
      final hold = Completer<void>();
      repository.holdJoin = hold;

      await tester.tap(button(en.otPostJoin).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.otPostJoin).last);
      await tester.pump();

      for (final b in tester.widgetList<ButtonStyleButton>(
        find.byWidgetPredicate((w) => w is FilledButton),
      )) {
        expect(b.onPressed, isNull);
      }
      hold.complete();
      await tester.pumpAndSettle();
      expect(repository.joins, ['post-1']);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('"Waiting for HR" opens my join\'s request', (tester) async {
      serve([
        samplePost('post-1', myJoin: sampleOt('ot-j', status: OtStatus.pending)),
      ]);
      await openPosts(tester);

      await tester.tap(button(en.otPostWaitingHr));
      await tester.pumpAndSettle();

      expect(find.byType(OtRequestDetailPage), findsOneWidget);
      expect(repository.requestIds, ['ot-j']);
    });
  });

  group('nothing to show', () {
    testWidgets('no posts: ບໍ່ມີປະກາດໂອທີສຳລັບພະແນກຂອງທ່ານ', (tester) async {
      await openPosts(tester, locale: 'lo');

      expect(find.text('ບໍ່ມີປະກາດໂອທີສຳລັບພະແນກຂອງທ່ານ'), findsOneWidget);
    });

    testWidgets('no signal: could not load, with Retry', (tester) async {
      repository.postsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      await openPosts(tester);

      expect(find.text(en.otListLoadFailed), findsOneWidget);
      serve([samplePost('post-1')]);
      await tester.tap(find.text(en.retry));
      await tester.pumpAndSettle();

      expect(find.text('07/11/2026'), findsOneWidget);
    });
  });

  testWidgets('the OT list\'s ປະກາດໂອທີ entry opens the posts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          otRepositoryProvider.overrideWithValue(repository),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.overtime,
            routes: overtimeRoutes,
          ),
          locale: const Locale('lo'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ປະກາດໂອທີ'));
    await tester.pumpAndSettle();

    expect(find.byType(OtPostsPage), findsOneWidget);
  });
}
