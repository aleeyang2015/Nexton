import 'package:flutter/material.dart';

import '../../../../core/widgets/global_widgets.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';
import '../widgets/monitoring_card.dart';

/// Home screen. Placeholder content until the home feature has a
/// data source — see the note on [_placeholderStats].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Hardcoded until a home repository exists. Kept here rather than in
  /// the widgets so the swap to a provider touches one place.
  static const _placeholderStats = [
    MonitoringStat("12", "ຂາດວຽກ"),
    MonitoringStat("0", "ມາຊ້າ"),
    MonitoringStat("35", "ລ່ວງເວລາ"),
  ];

  static const _menuEntries = [
    HomeMenuEntry("ເຂົ້າ/ອອກວຽກ", Icons.history),
    HomeMenuEntry("ການເຄື່ອນໄຫວ", Icons.directions_run),
    HomeMenuEntry("ເອກະສານ", Icons.description),
    HomeMenuEntry("ລາຍງານ", Icons.assessment),
    HomeMenuEntry("ພາກສ່ວນ", Icons.people),
    HomeMenuEntry("ຕັ້ງຄ່າ", Icons.settings),
    HomeMenuEntry("ແຈ້ງເຕືອນ", Icons.notifications),
    HomeMenuEntry("ໂປຣໄຟລ໌", Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
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
                      stats: _placeholderStats,
                      date: DateTime.now(),
                    ),
                    heightBx(h: 20),
                    const HomeMenuGrid(entries: _menuEntries),
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
