import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/widgets/main_shell_tab_provider.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../time_off/presentation/pages/time_off_page.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/list_menu_grid.dart';

/// "ລາຍການ" tab.
class ListPage extends ConsumerWidget {
  const ListPage({super.key});
  List<ListMenuEntry> _menuEntries(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) => [
    ListMenuEntry(
      l10n.clockInOut,
      Icons.punch_clock_outlined,
      onTap: () =>
          ref.read(mainShellTabProvider.notifier).select(MainShellTab.home),
    ),
    ListMenuEntry(
      l10n.attendanceHistoryMenu,
      Icons.history,
      onTap: () => context.push(AppRoutes.attendanceHistory),
    ),
    ListMenuEntry(
      l10n.leaveMenu,
      Icons.edit_calendar_outlined,
      onTap: () => context.push(AppRoutes.timeOff, extra: TimeOffTab.request),
    ),
    ListMenuEntry(
      l10n.leaveHistoryMenu,
      Icons.event_available_outlined,
      onTap: () => context.push(AppRoutes.timeOff),
    ),
    ListMenuEntry(l10n.delegateTaskMenu, Icons.assignment_ind_outlined),
    ListMenuEntry(l10n.delegateTaskHistoryMenu, Icons.assignment_turned_in_outlined),
    ListMenuEntry(
      l10n.salaryHistoryMenu,
      Icons.payments_outlined,
      onTap: () => context.push(AppRoutes.salaryHistory),
    ),
    ListMenuEntry(
      l10n.profile,
      Icons.person,
      onTap: () =>
          ref.read(mainShellTabProvider.notifier).select(MainShellTab.profile),
    ),
    ListMenuEntry(
      l10n.changePassword,
      Icons.lock_reset,
      onTap: () => context.push(AppRoutes.changePassword),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: customText(l10n.navList, fontWeight: FontWeight.w700, fontSize: 18),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            child: ListMenuGrid(entries: _menuEntries(context, ref, l10n)),
          ),
        ),
      ),
    );
  }
}
