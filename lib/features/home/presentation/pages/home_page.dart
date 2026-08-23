import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';
import '../widgets/monitoring_card.dart';

/// Home screen. Placeholder content until the home feature has a
/// data source — see the note on [_placeholderStats].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Hardcoded until a home repository exists. Kept here rather than in
  /// the widgets so the swap to a provider touches one place.
  List<MonitoringStat> _placeholderStats(AppLocalizations l10n) => [
    MonitoringStat("12", l10n.absent),
    MonitoringStat("0", l10n.lateArrival),
    MonitoringStat("35", l10n.overtime),
  ];

  List<HomeMenuEntry> _menuEntries(BuildContext context, AppLocalizations l10n) => [
    HomeMenuEntry(l10n.clockInOut, Icons.history),
    HomeMenuEntry(l10n.activities, Icons.directions_run),
    HomeMenuEntry(l10n.documents, Icons.description),
    HomeMenuEntry(l10n.reports, Icons.assessment),
    HomeMenuEntry(l10n.departments, Icons.people),
    HomeMenuEntry(
      l10n.settings,
      Icons.settings,
      onTap: () => context.push(AppRoutes.settings),
    ),
    HomeMenuEntry(l10n.notifications, Icons.notifications),
    HomeMenuEntry(l10n.profile, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              heightBx(),
              const HomeHeader(
                name: "ໝ່ຳ ຈົກມົກ",
                jobTitle: "ນັກພັດທະນາແອັບມືຖື",
                avatarAsset: "assets/images/mum_jokmok.jpeg",
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 60),
                  children: [
                    MonitoringCard(
                      stats: _placeholderStats(l10n),
                      date: DateTime.now(),
                    ),
                    heightBx(h: 20),
                    HomeMenuGrid(entries: _menuEntries(context, l10n)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
