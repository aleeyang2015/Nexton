import 'package:equatable/equatable.dart';

import 'entities/app_info.dart';

/// Whether the App may be used now (#57): as normal, only after an update,
/// or not until the server's maintenance ends.
sealed class AppGateStatus extends Equatable {
  const AppGateStatus();

  /// What [info] says, in the App's language [languageCode]. Maintenance
  /// outranks an update: an updated App could not be used either.
  factory AppGateStatus.from(AppInfo info, String languageCode) {
    if (info.isMaintenance) {
      final lo = _text(info.maintenanceMessageLo);
      final en = _text(info.maintenanceMessage);
      return AppGateMaintenance(languageCode == 'lo' ? lo ?? en : en ?? lo);
    }
    if (info.forceUpdate) return AppGateUpdateRequired(_text(info.updateUrl));
    return const AppGateOk();
  }

  static String? _text(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  List<Object?> get props => [];
}

/// Carry on as normal: also whenever the check could not be made.
final class AppGateOk extends AppGateStatus {
  const AppGateOk();
}

/// This version is too old: the update screen, with no way past it.
final class AppGateUpdateRequired extends AppGateStatus {
  /// The server's link, or null (the store's own page then).
  final String? url;

  const AppGateUpdateRequired([this.url]);

  /// Where the Update button goes on [platform] (`android` / `ios`): the
  /// server's link, else the Play page on Android; null on iOS with no link
  /// (no App Store id yet: the screen says to update from the App Store).
  Uri? storeLink(String platform) {
    final link = url;
    if (link != null) return Uri.tryParse(link);
    if (platform == 'android') return Uri.parse(playStorePage);
    return null;
  }

  /// The App's Play page (app id `next.on.hr.com`, #3).
  static const String playStorePage =
      'https://play.google.com/store/apps/details?id=next.on.hr.com';

  @override
  List<Object?> get props => [url];
}

/// The server is under maintenance: its message, or null for the default.
final class AppGateMaintenance extends AppGateStatus {
  final String? message;

  const AppGateMaintenance([this.message]);

  @override
  List<Object?> get props => [message];
}
