import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/app/app_version.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/locale_provider.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/app_gate/app_gate_providers.dart';
import 'package:next_on/features/app_gate/domain/app_gate_status.dart';
import 'package:next_on/features/app_gate/domain/entities/app_info.dart';
import 'package:next_on/features/app_gate/domain/repositories/app_info_repository.dart';
import 'package:next_on/features/app_gate/presentation/providers/app_gate_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The version gate (#57): any failure carries on; maintenance beats an
/// update; the message in the App's language; at most a check a minute.
void main() {
  late _FakeRepository repository;
  late DateTime now;
  late ProviderContainer container;

  Future<void> start({
    String version = '1.0.1+5',
    String language = 'lo',
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': language});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appInfoRepositoryProvider.overrideWithValue(repository),
        appVersionProvider.overrideWithValue(version),
        appPlatformProvider.overrideWithValue('android'),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.listen(appGateProvider, (_, _) {});
    await container.read(localeProvider.notifier).setLocale(Locale(language));
    await pumpEventQueue();
  }

  AppGateStatus gate() => container.read(appGateProvider);

  setUp(() {
    repository = _FakeRepository();
    now = DateTime(2026, 11, 18, 9);
  });

  test(
    'starts as ok, then asks once, with the version and no build number',
    () async {
      repository.hold = Completer<void>();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appInfoRepositoryProvider.overrideWithValue(repository),
          appVersionProvider.overrideWithValue('1.0.1+5'),
          appPlatformProvider.overrideWithValue('android'),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      container.listen(appGateProvider, (_, _) {});
      // A slow check never holds the start.
      expect(gate(), const AppGateOk());
      await pumpEventQueue();
      expect(repository.asked, [('android', '1.0.1')]);
      repository.hold!.complete();
    },
  );

  test('too old: the update screen, with the server\'s link', () async {
    repository.answer = const Result.success(
      AppInfo(
        forceUpdate: true,
        isMaintenance: false,
        updateUrl: 'https://example.com/app',
      ),
    );
    await start();
    expect(gate(), const AppGateUpdateRequired('https://example.com/app'));
  });

  test('maintenance beats an update', () async {
    repository.answer = const Result.success(
      AppInfo(forceUpdate: true, isMaintenance: true),
    );
    await start();
    expect(gate(), isA<AppGateMaintenance>());
  });

  group('the maintenance message', () {
    const both = AppInfo(
      forceUpdate: false,
      isMaintenance: true,
      maintenanceMessage: 'Back at 10:00',
      maintenanceMessageLo: 'ກັບມາເວລາ 10:00',
    );

    test('Lao in Lao, English in English', () async {
      repository.answer = const Result.success(both);
      await start(language: 'lo');
      expect(gate(), const AppGateMaintenance('ກັບມາເວລາ 10:00'));

      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('en'));
      await pumpEventQueue();
      expect(gate(), const AppGateMaintenance('Back at 10:00'));
    });

    test('no Lao text: the English one', () async {
      repository.answer = const Result.success(
        AppInfo(
          forceUpdate: false,
          isMaintenance: true,
          maintenanceMessage: 'Back at 10:00',
        ),
      );
      await start(language: 'lo');
      expect(gate(), const AppGateMaintenance('Back at 10:00'));
    });

    test(
      'English with only a Lao text: the default words, never Lao',
      () async {
        repository.answer = const Result.success(
          AppInfo(
            forceUpdate: false,
            isMaintenance: true,
            maintenanceMessageLo: 'ກັບມາເວລາ 10:00',
          ),
        );
        await start(language: 'en');
        expect(gate(), const AppGateMaintenance());
      },
    );

    test(
      'no text at all: the default (null here, the screen\'s words)',
      () async {
        repository.answer = const Result.success(
          AppInfo(forceUpdate: false, isMaintenance: true),
        );
        await start();
        expect(gate(), const AppGateMaintenance());
      },
    );
  });

  for (final (label, failure) in <(String, Failure)>[
    (
      '400 INVALID_PLATFORM',
      const Failure.validation(message: 'bad', code: 'INVALID_PLATFORM'),
    ),
    ('404 NOT_FOUND', const Failure.server(message: 'none', statusCode: 404)),
    (
      '429 RATE_LIMITED',
      const Failure.network(message: 'slow', statusCode: 429),
    ),
    ('500', const Failure.server(message: 'down', statusCode: 500)),
    ('a timeout, or no signal', const Failure.network(message: 'offline')),
  ]) {
    test('$label: carry on as normal', () async {
      repository.answer = Result.failure(failure);
      await start();
      expect(gate(), const AppGateOk());
    });
  }

  test('a failed check keeps what the last one said', () async {
    repository.answer = const Result.success(
      AppInfo(forceUpdate: false, isMaintenance: true),
    );
    await start();
    repository.answer = const Result.failure(
      Failure.network(message: 'offline'),
    );
    await container.read(appGateProvider.notifier).retry();
    expect(gate(), const AppGateMaintenance());
  });

  test('back in the foreground: asked again, at most once a minute', () async {
    await start();
    expect(repository.asked, hasLength(1));

    now = now.add(const Duration(seconds: 30));
    await container.read(appGateProvider.notifier).check();
    expect(repository.asked, hasLength(1));

    now = now.add(const Duration(seconds: 31));
    await container.read(appGateProvider.notifier).check();
    expect(repository.asked, hasLength(2));
  });

  test(
    'a phone clock moved back: asked again, not held until it catches up',
    () async {
      await start();
      now = now.subtract(const Duration(days: 1));
      await container.read(appGateProvider.notifier).check();
      expect(repository.asked, hasLength(2));
    },
  );

  test('a failed check does not hold the next one for a minute', () async {
    repository.answer = const Result.failure(
      Failure.network(message: 'offline'),
    );
    await start();
    repository.answer = const Result.success(
      AppInfo(forceUpdate: true, isMaintenance: false),
    );
    now = now.add(const Duration(seconds: 5));
    await container.read(appGateProvider.notifier).check();
    expect(repository.asked, hasLength(2));
    expect(gate(), const AppGateUpdateRequired());
  });

  test('Retry asks now, and the gate opens when maintenance ends', () async {
    repository.answer = const Result.success(
      AppInfo(forceUpdate: false, isMaintenance: true),
    );
    await start();
    repository.answer = const Result.success(
      AppInfo(forceUpdate: false, isMaintenance: false),
    );
    await container.read(appGateProvider.notifier).retry();
    expect(repository.asked, hasLength(2));
    expect(gate(), const AppGateOk());
  });

  test('the version could not be read: nothing asked, carry on', () async {
    await start(version: AppVersion.unknown);
    expect(repository.asked, isEmpty);
    expect(gate(), const AppGateOk());
  });

  group('where Update goes', () {
    test('the server\'s link', () {
      expect(
        const AppGateUpdateRequired('https://example.com/app').storeLink('ios'),
        Uri.parse('https://example.com/app'),
      );
    });

    test(
      'a server link that is not a web address: the Play page on Android',
      () {
        for (final bad in [
          'http://[bad',
          'play.google.com/store',
          'market://x',
        ]) {
          expect(
            AppGateUpdateRequired(bad).storeLink('android'),
            Uri.parse(AppGateUpdateRequired.playStorePage),
            reason: bad,
          );
          expect(AppGateUpdateRequired(bad).storeLink('ios'), isNull);
        }
      },
    );

    test('no link: the Play page on Android, nothing on iOS', () {
      expect(
        const AppGateUpdateRequired().storeLink('android'),
        Uri.parse(
          'https://play.google.com/store/apps/details?id=next.on.hr.com',
        ),
      );
      expect(const AppGateUpdateRequired().storeLink('ios'), isNull);
    });
  });

  test('the version sent never carries a build number', () {
    expect(AppVersion.clean('1.0.1+5'), '1.0.1');
    expect(AppVersion.clean(' 2.3.4 '), '2.3.4');
    expect(AppVersion.clean(''), AppVersion.unknown);
  });
}

class _FakeRepository implements AppInfoRepository {
  Result<AppInfo> answer = const Result.success(
    AppInfo(forceUpdate: false, isMaintenance: false),
  );
  final List<(String, String)> asked = [];
  Completer<void>? hold;

  @override
  FutureResult<AppInfo> appInfo({
    required String platform,
    required String version,
  }) async {
    asked.add((platform, version));
    await hold?.future;
    return answer;
  }
}
