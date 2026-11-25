import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/upload/presentation/file_link_image.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/home/presentation/widgets/home_header.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/file_link_test_doubles.dart';
import '../../support/profile_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

void main() {
  late FakeProfileRepository profiles;

  setUp(() => profiles = FakeProfileRepository());

  Future<void> pumpHeader(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(390, 200),
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(profiles),
          ...overrides,
        ],
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: HomeHeader()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the name and the role when the profile loads', (
    tester,
  ) async {
    await pumpHeader(tester);

    expect(find.text('Somphone Vilaysone'), findsOneWidget);
    expect(find.text('Cashier'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a login with no employee record is told so, with no Retry', (
    tester,
  ) async {
    profiles.profile = const Result.failure(
      Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      ),
    );

    await pumpHeader(tester);

    expect(
      find.text(
        'Your account is not linked to an employee record. '
        'Please contact HR.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 500 says "could not load your profile" with a Retry, and '
      'tapping it loads the profile again', (tester) async {
    profiles.profile = const Result.failure(
      Failure.server(message: 'boom', statusCode: 500),
    );

    await pumpHeader(tester);

    expect(find.text('Could not load your profile.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(profiles.calls, 1);

    profiles.profile = const Result.success(EmployeeProfileStub.somphone);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(profiles.calls, 2);
    expect(find.text('Somphone Vilaysone'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('an unreadable answer (a Wi-Fi sign-in page) can be retried '
      'and shows no parser text', (tester) async {
    profiles.profile = const Result.failure(
      Failure.validation(message: 'Expected a JSON object response'),
    );

    await pumpHeader(tester);

    expect(find.text('Could not load your profile.'), findsOneWidget);
    expect(find.text('Expected a JSON object response'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the long not-linked text fits a narrow phone in Lao without '
      'overflowing', (tester) async {
    profiles.profile = const Result.failure(
      Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      ),
    );

    await pumpHeader(
      tester,
      locale: const Locale('lo'),
      size: const Size(320, 200),
    );

    expect(find.textContaining('ກະລຸນາຕິດຕໍ່ HR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the message and its Retry fit a narrow phone in Lao', (
    tester,
  ) async {
    profiles.profile = const Result.failure(
      Failure.network(message: 'No internet connection', errorCode: 'NO_INTERNET'),
    );

    await pumpHeader(
      tester,
      locale: const Locale('lo'),
      size: const Size(320, 200),
    );

    expect(find.text('ບໍ່ສາມາດໂຫຼດໂປຣຟາຍໄດ້.'), findsOneWidget);
    expect(find.text('ລອງໃໝ່'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // #118: a profile photo's link expires after an hour, like every file link.
  group('the photo\'s link has expired', () {
    const photo = 'https://api.nexton.work/api/v1/files/tenants/demo/p.jpg';
    Result<EmployeeProfile> withPhoto(String sig) => Result.success(
      EmployeeProfile(
        id: 'emp-1',
        fullName: 'Somphone Vilaysone',
        positionTitle: 'Cashier',
        avatarUrl: '$photo?exp=1&sig=$sig',
      ),
    );

    setUp(resetExpiredLinkReports);

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
    }

    testWidgets('a 403: the profile is read again once, quietly, and the new '
        'link is drawn', (tester) async {
      profiles.answers = [withPhoto('old'), withPhoto('new')];
      await pumpHeader(
        tester,
        overrides: [fileLinksFailWith(403, failing: (u) => u.endsWith('old'))],
      );
      await settle(tester);

      expect(profiles.calls, 2);
      expect(
        find.byKey(const ValueKey('$photo?exp=1&sig=new')),
        findsOneWidget,
      );
      expect(find.text('Somphone Vilaysone'), findsOneWidget);
    });

    testWidgets('the fresh link refused too, within 30 s: not read again', (
      tester,
    ) async {
      profiles.answers = [withPhoto('old'), withPhoto('new')];
      await pumpHeader(tester, overrides: [fileLinksFailWith(403)]);
      await settle(tester);

      expect(profiles.calls, 2);
      expect(
        find.byKey(const ValueKey('$photo?exp=1&sig=new')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('the read again fails (no signal): the icon, no error card', (
      tester,
    ) async {
      profiles.answers = [
        withPhoto('old'),
        const Result.failure(Failure.network(message: 'no signal')),
      ];
      await pumpHeader(tester, overrides: [fileLinksFailWith(403)]);
      await settle(tester);

      expect(profiles.calls, 2);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('Somphone Vilaysone'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('another error (404): the icon, not read again', (
      tester,
    ) async {
      profiles.answers = [withPhoto('old')];
      await pumpHeader(tester, overrides: [fileLinksFailWith(404)]);
      await settle(tester);

      expect(profiles.calls, 1);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
