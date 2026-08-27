import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The bottom-nav tabs [MainShellPage] hosts, in bar order — `.index` is the
/// [IndexedStack] slot.
enum MainShellTab { list, home, profile }

/// Which shell tab is showing. Exposed as a provider so a screen living
/// inside one tab — e.g. the list page's "ເຂົ້າ/ອອກວຽກ" menu jumping to
/// Home — can move the shell without a chain of callbacks.
class MainShellTabNotifier extends Notifier<MainShellTab> {
  @override
  MainShellTab build() => MainShellTab.home;

  void select(MainShellTab tab) => state = tab;
}

final mainShellTabProvider = NotifierProvider<MainShellTabNotifier, MainShellTab>(
  MainShellTabNotifier.new,
);
