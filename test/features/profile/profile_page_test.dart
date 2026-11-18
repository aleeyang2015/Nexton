import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_summary.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/profile/presentation/pages/profile_page.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/file_capture_test_doubles.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/profile_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakeAttendanceRepository attendance;
  late FakeAuthRepository auth;

  const notLinked = Failure.validation(
    message: 'employee not found',
    code: 'EMPLOYEE_NOT_FOUND',
  );
  const notLinkedText =
      'Your account is not linked to an employee record. Please contact HR.';

  setUp(() {
    profiles = FakeProfileRepository();
    attendance = FakeAttendanceRepository()
      ..monthSummary = const Result.success(
        AttendanceSummary(lateDays: 3, absentDays: 2, totalWorkHours: 121.5),
      );
    auth = FakeAuthRepository();
  });

  tearDown(() => auth.sessionExpired.close());

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(profiles),
          attendanceRepositoryProvider.overrideWithValue(attendance),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ProfilePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  final en = lookupAppLocalizations(const Locale('en'));

  group('when the profile loads', () {
    testWidgets('shows the name, the email and the menu', (tester) async {
      await pumpPage(tester);

      expect(find.text('Somphone Vilaysone'), findsOneWidget);
      expect(find.text('somphone.vilaysone@nexton.la'), findsOneWidget);
      expect(find.text(en.changePassword), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the stats row shows the server\'s real numbers', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('121.5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text(en.lateArrivals), findsOneWidget);
      expect(find.text(en.absences), findsOneWidget);
    });

    testWidgets('a month summary that failed shows no number: a dash, never '
        'a 0', (tester) async {
      attendance.monthSummary = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await pumpPage(tester);

      expect(find.text('-'), findsNWidgets(3));
      expect(find.text('0'), findsNothing);
      expect(find.text('0.0'), findsNothing);
      // The identity above it is unaffected.
      expect(find.text('Somphone Vilaysone'), findsOneWidget);
    });
  });

  group('when the profile cannot be loaded', () {
    testWidgets('a login with no employee record is told so, with no Retry, '
        'and the menu still works', (tester) async {
      profiles.profile = const Result.failure(notLinked);

      await pumpPage(tester);

      expect(find.text(notLinkedText), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      // The menu is still there, so the user can change the password or
      // sign out.
      expect(find.text(en.changePassword), findsOneWidget);
      expect(find.text(en.logout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 500 says "could not load your profile" with a Retry, and '
        'tapping it loads the profile again', (tester) async {
      profiles.profile = const Result.failure(
        Failure.server(message: 'boom', statusCode: 500),
      );

      await pumpPage(tester);

      expect(find.text('Could not load your profile.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(profiles.calls, 1);

      profiles.profile = const Result.success(
        EmployeeProfileStub.somphone,
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(profiles.calls, 2);
      expect(find.text('Somphone Vilaysone'), findsOneWidget);
      expect(find.text('Could not load your profile.'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('no connection offers a Retry too', (tester) async {
      profiles.profile = const Result.failure(
        Failure.network(message: 'No internet connection', errorCode: 'NO_INTERNET'),
      );

      await pumpPage(tester);

      expect(find.text('Could not load your profile.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a module the company has not turned on says so, with no '
        'Retry', (tester) async {
      profiles.profile = const Result.failure(
        Failure.validation(message: 'not active', code: 'MODULE_NOT_ACTIVE'),
      );

      await pumpPage(tester);

      expect(find.text(en.errorModuleNotActive), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('changing the photo (#59)', () {
    late FakeFileCapture capture;

    Future<void> pumpWithCapture(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(profiles),
            attendanceRepositoryProvider.overrideWithValue(attendance),
            authRepositoryProvider.overrideWithValue(auth),
            fileCaptureProvider.overrideWithValue(capture),
          ],
          child: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: MaterialApp(
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const ProfilePage(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    setUp(() => capture = FakeFileCapture());

    testWidgets('camera, gallery and an image file are offered; a photo '
        'taken is sent, the avatar spins, then "changed"', (tester) async {
      profiles.holdPhoto = Completer<void>();
      await pumpWithCapture(tester);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(find.text(en.uploadTakePhoto), findsOneWidget);
      expect(find.text(en.uploadPickPhoto), findsOneWidget);
      expect(find.text(en.uploadPickFile), findsOneWidget);

      await tester.tap(find.text(en.uploadTakePhoto));
      // The sheet closes (the spinner never settles: a fixed wait).
      await tester.pump(const Duration(seconds: 1));
      expect(profiles.photoUploads, hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // A tap meanwhile opens nothing more.
      await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(en.uploadTakePhoto), findsNothing);

      profiles.holdPhoto!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text(en.profilePhotoChanged), findsOneWidget);
      expect(capture.asked, ['camera']);
    });

    testWidgets('no pencil before the profile has loaded', (tester) async {
      profiles.hold = Completer<void>();
      await pumpWithCapture(tester);
      expect(find.byIcon(Icons.edit), findsNothing);
      profiles.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('a refusal says why', (tester) async {
      profiles.photoResult = const Result.failure(
        Failure.validation(message: 'profilePhotoTooLarge'),
      );
      await pumpWithCapture(tester);
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.uploadPickFile));
      await tester.pump();
      await tester.pump();
      expect(find.text(en.profilePhotoTooLarge), findsOneWidget);
    });
  });
}
