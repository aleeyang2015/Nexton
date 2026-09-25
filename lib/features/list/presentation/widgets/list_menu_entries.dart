import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/presentation/pages/time_off_page.dart';
import 'list_menu_grid.dart';

/// The app's shortcut entries, shared by the "ລາຍການ" tab and the home screen
/// so both always show the same menu.
List<ListMenuEntry> buildListMenuEntries(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) => [
  // ListMenuEntry(
  //   l10n.clockInOut,
  //   Icons.punch_clock_outlined,
  //   onTap: () =>
  //       ref.read(mainShellTabProvider.notifier).select(MainShellTab.home),
  // ),
  // ListMenuEntry(
  //   l10n.attendanceHistoryMenu,
  //   Icons.history,
  //   onTap: () => context.push(AppRoutes.attendanceHistory),
  // ),
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
  // ListMenuEntry(l10n.delegateTaskMenu, Icons.assignment_ind_outlined),
  // ListMenuEntry(
  //   l10n.delegateTaskHistoryMenu,
  //   Icons.assignment_turned_in_outlined,
  // ),
  ListMenuEntry(
    l10n.salaryHistoryMenu,
    Icons.payments_outlined,
    onTap: () => context.push(AppRoutes.salaryHistory),
  ),
  ListMenuEntry(
    l10n.forgotClockInMenu,
    Icons.more_time,
    onTap: () => context.push(AppRoutes.timeCorrectionRequest),
  ),
  ListMenuEntry(
    l10n.timeCorrectionHistoryMenu,
    Icons.manage_history,
    onTap: () => context.push(AppRoutes.timeCorrectionHistory),
  ),
  // ListMenuEntry(
  //   l10n.profile,
  //   Icons.person,
  //   onTap: () =>
  //       ref.read(mainShellTabProvider.notifier).select(MainShellTab.profile),
  // ),
  // ListMenuEntry(
  //   l10n.changePassword,
  //   Icons.lock_reset,
  //   onTap: () => context.push(AppRoutes.changePassword),
  // ),
];
