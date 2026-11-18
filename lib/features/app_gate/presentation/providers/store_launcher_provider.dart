import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [link] outside the App (the store, #57). True when it opened. A
/// provider so tests can record instead of open.
final storeLauncherProvider = Provider<Future<bool> Function(Uri link)>(
  (ref) => (link) async {
    try {
      return await launchUrl(link, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);
