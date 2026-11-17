import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/overtime/data/datasources/ot_error_code.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_ask_page.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_request_detail_page.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_ask_notifier.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/overtime_test_doubles.dart';
import '../../support/profile_test_doubles.dart';

/// The Ask OT page: what it warns about, what it says when refused, and
/// where it goes when the request is saved.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();
  late FakeOtRepository repository;

  setUp(() => repository = FakeOtRepository());

  /// Opens the page from the OT list, today being Wednesday 11 November.
  Future<void> openAsk(WidgetTester tester, {String locale = 'en'}) async {
    tester.view.physicalSize = const Size(900, 2000);
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
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 11, 10)),
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
    router.push(AppRoutes.otAsk);
    await tester.pumpAndSettle();
  }

  OtAskNotifier form(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(OtAskPage)),
  ).read(otAskNotifierProvider.notifier);

  Future<void> times(
    WidgetTester tester,
    (int, int) start,
    (int, int) end,
  ) async {
    form(tester)
      ..setStart(start.$1, start.$2)
      ..setEnd(end.$1, end.$2);
    await tester.pump();
  }

  FilledButton send(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('the fields, in Lao; today\'s date; Send waits for both times',
      (tester) async {
    await openAsk(tester, locale: 'lo');

    expect(find.text('ຂໍໂອທີ'), findsOneWidget);
    expect(find.text('ວັນທີ'), findsOneWidget);
    expect(find.text('ເວລາເລີ່ມ'), findsOneWidget);
    expect(find.text('ເວລາສິ້ນສຸດ'), findsOneWidget);
    expect(find.text('ເຫດຜົນ (ບໍ່ບັງຄັບ)'), findsOneWidget);
    expect(find.text('11/11/2026'), findsOneWidget);
    expect(find.text(lo.leaveRequestSubmit), findsOneWidget);
    expect(send(tester).onPressed, isNull);

    await times(tester, (18, 0), (20, 0));

    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(send(tester).onPressed, isNotNull);
  });

  testWidgets('an end before the start says (ມື້ຖັດໄປ) beside End', (
    tester,
  ) async {
    await openAsk(tester, locale: 'lo');

    await times(tester, (22, 0), (2, 0));

    expect(find.text('(ມື້ຖັດໄປ)'), findsOneWidget);

    await times(tester, (18, 0), (20, 0));
    expect(find.text('(ມື້ຖັດໄປ)'), findsNothing);
  });

  testWidgets('a past date shows the amber note; today does not', (
    tester,
  ) async {
    await openAsk(tester, locale: 'lo');
    expect(find.text(lo.otPastDateWarning), findsNothing);

    form(tester).setDate(DateTime(2026, 11, 9));
    await tester.pump();

    expect(find.text(lo.otPastDateWarning), findsOneWidget);
  });

  testWidgets('the reason allows 2000 characters', (tester) async {
    await openAsk(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField)).maxLength,
      2000,
    );
  });

  testWidgets('Send is disabled while sending, and a double tap sends once', (
    tester,
  ) async {
    await openAsk(tester);
    await times(tester, (18, 0), (20, 0));
    final hold = Completer<void>();
    repository.holdAsk = hold;

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(send(tester).onPressed, isNull);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();

    hold.complete();
    await tester.pumpAndSettle();
    expect(repository.asked, hasLength(1));
  });

  testWidgets('saved: "OT request sent", and the new request\'s page in '
      'place of this one', (tester) async {
    await openAsk(tester);
    await times(tester, (18, 0), (20, 0));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text(en.otAskSent), findsOneWidget);
    expect(find.byType(OtRequestDetailPage), findsOneWidget);
    expect(find.byType(OtAskPage), findsNothing);

    // Back goes to the list, not to the form.
    await tester.tap(
      find.descendant(
        of: find.byType(OtRequestDetailPage),
        matching: find.byIcon(Icons.arrow_back_ios),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OtAskPage), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('refused for the shift: the Lao text above Send, the form kept',
      (tester) async {
    repository.askAnswer = (_) => const Result.failure(
      Failure.validation(message: OtErrorCode.tokenOverlapsShift),
    );
    await openAsk(tester, locale: 'lo');
    await times(tester, (16, 0), (19, 0));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(
      find.text('ເວລານີ້ທັບກັບກະວຽກຂອງທ່ານ. ໂອທີຕ້ອງຢູ່ນອກກະວຽກ.'),
      findsOneWidget,
    );
    expect(find.text('16:00'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.byType(OtAskPage), findsOneWidget);
  });

  testWidgets('OT off at the company: the Lao OT_DISABLED text', (tester) async {
    repository.askAnswer = (_) =>
        const Result.failure(Failure.validation(message: OtErrorCode.tokenDisabled));
    await openAsk(tester, locale: 'lo');
    await times(tester, (18, 0), (20, 0));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('ບໍລິສັດຍັງບໍ່ໄດ້ເປີດໃຊ້ໂອທີ.'), findsOneWidget);
  });

  testWidgets('18:00–18:00: the End error under End', (tester) async {
    repository.askAnswer = (_) => const Result.failure(
      Failure.validation(
        message: 'end_time must differ',
        field: 'end_time',
        code: ApiErrorCodes.validationError,
      ),
    );
    await openAsk(tester, locale: 'lo');
    await times(tester, (18, 0), (18, 0));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('ເວລາສິ້ນສຸດຕ້ອງບໍ່ເທົ່າກັບເວລາເລີ່ມ'), findsOneWidget);
    expect(find.text('end_time must differ'), findsNothing);
  });

  testWidgets('no signal: says so; nothing saved, she can send again', (
    tester,
  ) async {
    repository.askAnswer = (_) => const Result.failure(
      Failure.network(message: 'offline', errorCode: ApiErrorCodes.noInternet),
    );
    await openAsk(tester, locale: 'lo');
    await times(tester, (18, 0), (20, 0));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text(lo.noInternetConnection), findsOneWidget);
    expect(send(tester).onPressed, isNotNull);
  });

  testWidgets('the time picker opens in 24-hour time', (tester) async {
    await openAsk(tester);

    await tester.tap(find.text('--:--').first);
    await tester.pumpAndSettle();

    final picker = find.byType(TimePickerDialog);
    expect(picker, findsOneWidget);
    expect(
      MediaQuery.of(tester.element(picker)).alwaysUse24HourFormat,
      isTrue,
    );
  });
}
