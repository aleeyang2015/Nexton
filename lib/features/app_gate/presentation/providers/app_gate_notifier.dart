import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app/app_version.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../app_gate_providers.dart';
import '../../domain/app_gate_status.dart';
import '../../domain/entities/app_info.dart';
import '../../domain/usecases/get_app_info_usecase.dart';

/// Whether the App may be used now (#57): asks the server at launch and on
/// each return to the foreground, at most once a [checkEvery].
///
/// Starts as [AppGateOk], so a slow check never holds the first frame. A
/// check that fails (no signal, a timeout, 4xx, 429, 5xx) changes nothing:
/// the App carries on as it was. App-wide, not a user's data: it lives as
/// long as the App.
class AppGateNotifier extends Notifier<AppGateStatus> {
  /// The least time between two checks (the `/mobile` group allows 60 calls
  /// a minute per IP).
  static const Duration checkEvery = Duration(minutes: 1);

  DateTime? _lastCheck;
  Future<void>? _checking;
  AppInfo? _info;

  @override
  AppGateStatus build() {
    final lifecycle = _tryCreateLifecycleListener();
    ref.onDispose(() => lifecycle?.dispose());

    // The maintenance message follows the App's language.
    ref.listen(localeProvider.select((l) => l.languageCode), (_, language) {
      final info = _info;
      if (info != null) state = AppGateStatus.from(info, language);
    });

    Future.microtask(check);
    return const AppGateOk();
  }

  AppLifecycleListener? _tryCreateLifecycleListener() {
    try {
      return AppLifecycleListener(onShow: () => unawaited(check()));
    } catch (_) {
      return null;
    }
  }

  /// Asks the server, unless it was asked less than [checkEvery] ago or is
  /// being asked now. [force]: the maintenance screen's Retry.
  Future<void> check({bool force = false}) {
    final running = _checking;
    if (running != null) return running;
    final now = ref.read(clockProvider)();
    final last = _lastCheck;
    if (!force && last != null && now.difference(last) < checkEvery) {
      return Future.value();
    }
    _lastCheck = now;
    final call = _ask();
    _checking = call;
    return call.whenComplete(() => _checking = null);
  }

  /// The maintenance screen's Retry: asks now.
  Future<void> retry() => check(force: true);

  Future<void> _ask() async {
    final version = AppVersion.clean(ref.read(appVersionProvider));
    // The platform's version could not be read: asking with 0.0.0 would
    // send everyone to the update screen. Carry on instead.
    if (version == AppVersion.unknown) return;
    final result = await ref.read(getAppInfoUseCaseProvider)(
      AppBuild(platform: ref.read(appPlatformProvider), version: version),
    );
    result.when(
      success: (info) {
        _info = info;
        state = AppGateStatus.from(info, ref.read(localeProvider).languageCode);
      },
      failure: (failure) {
        if (kDebugMode) debugPrint('App gate check skipped: $failure');
      },
    );
  }
}

final appGateProvider = NotifierProvider<AppGateNotifier, AppGateStatus>(
  AppGateNotifier.new,
);
