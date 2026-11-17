import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/correction_error_code.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_form_notifier.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_type.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/file_capture_test_doubles.dart';
import '../../support/profile_test_doubles.dart';

/// The "forgot to scan" form, opened filled (#44).
void main() {
  final en = AppLocalizationsEn();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = DateTime(today.year, today.month, today.day - 7);

  const office = ShiftDetail(
    id: 'p-am',
    startTime: '08:00',
    endTime: '17:00',
    earlyCheckinMinutes: 30,
    lateCheckoutMinutes: 60,
  );

  late FakeAttendanceRepository attendance;
  late FakeFileCapture capture;
  late GoRouter router;

  Future<ProviderContainer> open(WidgetTester tester, String location) async {
    // Wide: the attachment buttons row overflows in English at 420 (on main
    // already, recorded).
    tester.view.physicalSize = const Size(700, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    attendance = FakeAttendanceRepository();
    capture = FakeFileCapture();
    final profiles = FakeProfileRepository()
      ..profile = const Result.success(
        EmployeeProfile(id: 'e1', fullName: 'Noy', shiftDetails: [office]),
      );
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: AppRoutes.timeCorrectionRequest,
          builder: (_, state) => timeCorrectionRequestPageFor(
            state.uri.queryParameters,
            state.extra,
          ),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(attendance),
        profileRepositoryProvider.overrideWithValue(profiles),
        fileCaptureProvider.overrideWithValue(capture),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    unawaited(router.push(location));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('?date=&part= fill in the day and the part', (tester) async {
    final container = await open(
      tester,
      AppRoutes.timeCorrectionRequestFor(weekAgo, partId: 'p-am'),
    );

    final state = container.read(timeCorrectionFormNotifierProvider);
    expect(state.date, weekAgo);
    expect(state.shiftDetail?.id, 'p-am');
  });

  testWidgets('the part\'s window shows as a hint under the times', (
    tester,
  ) async {
    await open(tester, AppRoutes.timeCorrectionRequest);

    expect(
      find.text(en.attCorrectionWindowHint('07:30', '18:00')),
      findsOneWidget,
    );
  });

  testWidgets('the date picker offers 30 days back to today', (tester) async {
    await open(tester, AppRoutes.timeCorrectionRequest);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined).first);
    await tester.pumpAndSettle();

    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(today.year, today.month, today.day - 30));
    expect(picker.lastDate, today);
  });

  testWidgets('"already asked" (DUPLICATE): a dialog, then back', (
    tester,
  ) async {
    await open(tester, AppRoutes.timeCorrectionRequest);
    attendance.timeCorrectionResult = Result.failure(
      Failure.validation(
        message: CorrectionErrorCode.encode(CorrectionErrorCode.tokenDuplicate),
        code: 'DUPLICATE',
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'Forgot');
    await tester.tap(find.text(en.timeCorrectionSubmit));
    await tester.pumpAndSettle();

    expect(find.text(en.attCorrectionDuplicate), findsOneWidget);
    // Closed (a tap outside it), the form goes back.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('"choose file" offers camera, photos and an image file (#38\'s '
      'photo sources)', (tester) async {
    await open(tester, AppRoutes.timeCorrectionRequest);

    await tester.tap(find.text(en.timeCorrectionChooseFile));
    await tester.pumpAndSettle();

    expect(find.text(en.uploadTakePhoto), findsOneWidget);
    expect(find.text(en.uploadPickPhoto), findsOneWidget);
    expect(find.text(en.uploadPickFile), findsOneWidget);
  });

  testWidgets('each type shows only the times it needs', (tester) async {
    final container = await open(tester, AppRoutes.timeCorrectionRequest);
    final notifier = container.read(
      timeCorrectionFormNotifierProvider.notifier,
    );

    notifier.setType(TimeCorrectionType.forgotClockIn);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(en.timeCorrectionClockInLabel, findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(en.timeCorrectionClockOutLabel, findRichText: true),
      findsNothing,
    );

    notifier.setType(TimeCorrectionType.forgotClockOut);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(en.timeCorrectionClockInLabel, findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining(en.timeCorrectionClockOutLabel, findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('"already asked" with nothing underneath (a link): home, no '
      'error', (tester) async {
    tester.view.physicalSize = const Size(700, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final attendance = FakeAttendanceRepository()
      ..timeCorrectionResult = Result.failure(
        Failure.validation(
          message: CorrectionErrorCode.encode(
            CorrectionErrorCode.tokenDuplicate,
          ),
          code: 'DUPLICATE',
        ),
      );
    final profiles = FakeProfileRepository()
      ..profile = const Result.success(
        EmployeeProfile(id: 'e1', fullName: 'Noy', shiftDetails: [office]),
      );
    final router = GoRouter(
      initialLocation: AppRoutes.timeCorrectionRequest,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: AppRoutes.timeCorrectionRequest,
          builder: (_, state) => timeCorrectionRequestPageFor(
            state.uri.queryParameters,
            state.extra,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(attendance),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Forgot');
    await tester.tap(find.text(en.timeCorrectionSubmit));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('HOME'), findsOneWidget);
  });
}
