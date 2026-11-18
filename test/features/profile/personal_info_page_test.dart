import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/entities/personal_info.dart';
import 'package:next_on/features/profile/presentation/pages/personal_info_page.dart';
import 'package:next_on/features/profile/presentation/pages/profile_page.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/profile_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

/// "Personal" (#58): the employee's own record, read-only.
void main() {
  final en = AppLocalizationsEn();
  late FakeProfileRepository profiles;

  EmployeeProfile withPersonal(EmployeePersonalInfo personal) =>
      EmployeeProfile(id: 'emp-1', fullName: personal.name, personal: personal);

  const bee = EmployeePersonalInfo(
    firstName: 'Bee',
    lastName: 'Sisouk',
    firstNameLo: 'ບີ',
    lastNameLo: 'ສີສຸກ',
    employeeNumber: 'EMP-0042',
    mobilePhone: '020 5555 1234',
    workPhone: '021 412 000',
    workPhoneExtension: '12',
    departmentName: 'Finance',
    managerName: 'Noy Phommachanh',
    emergencyContacts: [
      EmergencyContact(
        name: 'Keo Sisouk',
        relationship: 'spouse',
        phone: '020 7777 0000',
      ),
      EmergencyContact(name: 'Somchai', relationship: 'cousin'),
    ],
  );

  setUp(() => profiles = FakeProfileRepository());

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(profiles)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const PersonalInfoPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('every row, the Lao name, the work phone with its extension', (
    tester,
  ) async {
    profiles.profile = Result.success(
      withPersonal(bee.copyWithHireDate(DateTime(2024, 1, 15))),
    );
    await pumpPage(tester);

    expect(find.text('Bee Sisouk'), findsOneWidget);
    expect(find.text('ບີ ສີສຸກ'), findsOneWidget);
    expect(find.text('EMP-0042'), findsOneWidget);
    expect(find.text('020 5555 1234'), findsOneWidget);
    expect(
      find.text('021 412 000 (${en.personalPhoneExt} 12)'),
      findsOneWidget,
    );
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Noy Phommachanh'), findsOneWidget);
    expect(find.text('15/01/2024'), findsOneWidget);
    expect(find.text(en.personalAskHrToFix), findsOneWidget);
  });

  testWidgets('emergency contacts: the relationship in the App\'s words, an '
      'unknown one as sent', (tester) async {
    profiles.profile = Result.success(withPersonal(bee));
    await pumpPage(tester);

    expect(find.text('Keo Sisouk'), findsOneWidget);
    expect(find.text(en.relationshipSpouse), findsOneWidget);
    expect(find.text('020 7777 0000'), findsOneWidget);
    expect(find.text('Somchai'), findsOneWidget);
    expect(find.text('cousin'), findsOneWidget);
  });

  testWidgets('none of the optional fields: "-" rows and "None yet", no Lao '
      'name row', (tester) async {
    profiles.profile = Result.success(
      withPersonal(
        const EmployeePersonalInfo(
          firstName: 'Bee',
          lastName: 'Sisouk',
          employeeNumber: 'EMP-0042',
        ),
      ),
    );
    await pumpPage(tester);

    expect(find.text(en.personalNameLo), findsNothing);
    // Mobile, work, home, department, manager, hire date.
    expect(find.text('-'), findsNWidgets(6));
    expect(find.text(en.personalNoEmergencyContacts), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no staff record: #12\'s "contact HR", no Retry', (tester) async {
    profiles.profile = const Result.failure(
      Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      ),
    );
    await pumpPage(tester);

    expect(
      find.text(
        'Your account is not linked to an employee record. '
        'Please contact HR.',
      ),
      findsOneWidget,
    );
    expect(find.text(en.retry), findsNothing);
  });

  testWidgets('a 500: the load failed, with Retry that reads again', (
    tester,
  ) async {
    profiles.profile = const Result.failure(
      Failure.server(message: 'down', statusCode: 500),
    );
    await pumpPage(tester);
    expect(profiles.calls, 1);

    profiles.profile = Result.success(withPersonal(bee));
    await tester.tap(find.text(en.retry));
    await tester.pumpAndSettle();
    expect(profiles.calls, 2);
    expect(find.text('Bee Sisouk'), findsOneWidget);
  });

  testWidgets(
    'opened from Profile: no request of its own; a pull reads again',
    (tester) async {
      profiles.profile = Result.success(withPersonal(bee));
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = FakeAuthRepository();
      addTearDown(auth.sessionExpired.close);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ProfilePage()),
          GoRoute(
            path: AppRoutes.personalInfo,
            builder: (_, _) => const PersonalInfoPage(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(profiles),
            attendanceRepositoryProvider.overrideWithValue(
              FakeAttendanceRepository(),
            ),
            authRepositoryProvider.overrideWithValue(auth),
          ],
          child: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(profiles.calls, 1);

      await tester.tap(find.text(en.personal));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalInfoPage), findsOneWidget);
      expect(profiles.calls, 1);

      await tester.fling(find.text('Bee Sisouk'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(profiles.calls, 2);
    },
  );

  testWidgets('no salary, ID, passport, tax or bank label on the page', (
    tester,
  ) async {
    profiles.profile = Result.success(withPersonal(bee));
    await pumpPage(tester);
    for (final word in ['Salary', 'Passport', 'National ID', 'Tax', 'Bank']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });
}

extension on EmployeePersonalInfo {
  EmployeePersonalInfo copyWithHireDate(DateTime date) => EmployeePersonalInfo(
    firstName: firstName,
    lastName: lastName,
    firstNameLo: firstNameLo,
    lastNameLo: lastNameLo,
    employeeNumber: employeeNumber,
    mobilePhone: mobilePhone,
    workPhone: workPhone,
    workPhoneExtension: workPhoneExtension,
    homePhone: homePhone,
    departmentName: departmentName,
    managerName: managerName,
    hireDate: date,
    emergencyContacts: emergencyContacts,
  );
}
