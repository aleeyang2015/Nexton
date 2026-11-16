import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/home/presentation/widgets/home_header.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/profile_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

void main() {
  late FakeProfileRepository profiles;

  setUp(() => profiles = FakeProfileRepository());

  Future<void> pumpHeader(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(390, 200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(profiles)],
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
}
