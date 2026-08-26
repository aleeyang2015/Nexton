import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/list_menu_grid.dart';

/// "ລາຍການ" tab.
class ListPage extends StatelessWidget {
  const ListPage({super.key});
  List<ListMenuEntry> _menuEntries(BuildContext context, AppLocalizations l10n) => [
    ListMenuEntry(l10n.clockInOut, Icons.history),
    ListMenuEntry(
      l10n.timeOffRequestTab,
      Icons.edit_calendar_outlined,
      onTap: () => context.push(AppRoutes.timeOff),
    ),
    ListMenuEntry(l10n.documents, Icons.description),
    ListMenuEntry(l10n.reports, Icons.assessment),
    ListMenuEntry(l10n.departments, Icons.people),
    ListMenuEntry(
      l10n.settings,
      Icons.settings,
      onTap: () => context.push(AppRoutes.settings),
    ),
    ListMenuEntry(l10n.notifications, Icons.notifications),
    ListMenuEntry(l10n.profile, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
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
            child: ListMenuGrid(entries: _menuEntries(context, l10n)),
          ),
        ),
      ),
    );
  }
}
