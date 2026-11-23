import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/upload/presentation/file_link_image.dart';
import 'package:next_on/core/widgets/image_viewer.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/file_link_test_doubles.dart';

/// A photo or file link from `POST /uploads` lives one hour; after that it
/// answers 403 `LINK_EXPIRED`, and the request has to be read again (#73).
void main() {
  final en = AppLocalizationsEn();
  setUp(resetExpiredLinkReports);

  group('isExpiredFileLink', () {
    final uri = Uri.parse('https://api.nexton.work/api/v1/files/x.jpg');

    test('an image refused with 403, or a download with LINK_EXPIRED', () {
      expect(
        isExpiredFileLink(NetworkImageLoadException(statusCode: 403, uri: uri)),
        isTrue,
      );
      expect(
        isExpiredFileLink(
          const Failure.validation(message: 'x', code: 'LINK_EXPIRED'),
        ),
        isTrue,
      );
    });

    test('anything else is not', () {
      expect(
        isExpiredFileLink(NetworkImageLoadException(statusCode: 404, uri: uri)),
        isFalse,
      );
      expect(
        isExpiredFileLink(
          const Failure.validation(message: 'x', code: 'FORBIDDEN'),
        ),
        isFalse,
      );
      expect(
        isExpiredFileLink(const Failure.network(message: 'offline')),
        isFalse,
      );
      expect(isExpiredFileLink(null), isFalse);
    });
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required int status,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [fileLinksFailWith(status)],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    ),
  );

  group('FileLinkImage', () {
    testWidgets('expired: the fallback, and the page is told once, after '
        'the frame', (tester) async {
      var told = 0;
      await pump(
        tester,
        FileLinkImage(
          url: 'https://f/a.jpg',
          fallback: const Text('FALLBACK'),
          onExpired: () => told++,
        ),
        status: 403,
      );
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.text('FALLBACK'), findsOneWidget);
      expect(told, 1);
    });

    testWidgets('a new link after an expired one starts afresh: the old '
        'error is not taken for the new link\'s', (tester) async {
      var told = 0;
      Widget image(String url) => ProviderScope(
        overrides: [
          fileLinksFailWith(403, failing: (u) => u.endsWith('old.jpg')),
        ],
        child: MaterialApp(
          home: FileLinkImage(
            url: url,
            fallback: const Text('FALLBACK'),
            onExpired: () => told++,
          ),
        ),
      );

      await tester.pumpWidget(image('https://f/old.jpg'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(image('https://f/new.jpg'));
      await tester.pumpAndSettle();
      await tester.pump();

      expect(told, 1);
    });

    test('the same file, a fresh link refused too (403 for another '
        'reason): not reloaded again for 30 seconds, then it may be', () {
      var now = DateTime(2026, 11, 20, 9);
      expiredLinkClock = () => now;
      addTearDown(() => expiredLinkClock = DateTime.now);
      var told = 0;
      void report(String sig) => reportExpiredNow(
        'https://api.nexton.work/files/t/uploads/a.jpg?exp=1&sig=$sig',
        () => told++,
      );

      report('a');
      report('b');
      expect(told, 1, reason: 'no loop on a link that keeps being refused');

      now = now.add(const Duration(seconds: 31));
      report('c');
      expect(told, 2, reason: 'a reload that failed is tried again later');
    });

    test('two different files: each may reload', () {
      var told = 0;
      reportExpiredNow('https://f/a.jpg?sig=1', () => told++);
      reportExpiredNow('https://f/b.jpg?sig=1', () => told++);
      expect(told, 2);
    });

    testWidgets('another failure: the fallback, nobody told', (tester) async {
      var told = 0;
      await pump(
        tester,
        FileLinkImage(
          url: 'https://f/b.jpg',
          fallback: const Text('FALLBACK'),
          onExpired: () => told++,
        ),
        status: 404,
      );
      await tester.pumpAndSettle();

      expect(find.text('FALLBACK'), findsOneWidget);
      expect(told, 0);
    });
  });

  group('the viewer', () {
    Widget opener({VoidCallback? onExpired}) => Builder(
      builder: (context) => TextButton(
        onPressed: () => showImageViewer(
          context,
          'https://f/c.jpg',
          errorText: 'COULD NOT OPEN',
          onExpired: onExpired,
        ),
        child: const Text('OPEN'),
      ),
    );

    testWidgets('expired: says so, and tells the page once', (tester) async {
      var told = 0;
      await pump(tester, opener(onExpired: () => told++), status: 403);
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.text(en.fileLinkExpired), findsOneWidget);
      expect(find.text('COULD NOT OPEN'), findsNothing);
      expect(told, 1);
    });

    testWidgets('expired, and nothing can read it again (a list): says to '
        'pull down to refresh', (tester) async {
      await pump(tester, opener(), status: 403);
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text(en.fileLinkExpiredRefresh), findsOneWidget);
      expect(find.text(en.fileLinkExpired), findsNothing);
    });

    testWidgets('another failure: the caller\'s words', (tester) async {
      await pump(tester, opener(), status: 404);
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('COULD NOT OPEN'), findsOneWidget);
      expect(find.text(en.fileLinkExpired), findsNothing);
    });
  });
}
