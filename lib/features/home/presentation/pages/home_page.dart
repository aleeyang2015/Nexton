import 'package:flutter/material.dart';

import '../../../../core/widgets/global_widgets.dart';
import '../widgets/attendance_status_card.dart';
import '../widgets/home_header.dart';

/// Home screen. Placeholder content until the home feature has a
/// data source — see the note on [_placeholderStatus].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Hardcoded until an attendance/clock feature exists. Kept here rather
  /// than in the widget so the swap to a provider touches one place.
  static const _placeholderStatus = AttendanceStatus(
    clockedIn: false,
    clockInTime: "17:00",
    clockOutTime: "23:00",
    opensAt: "16:00",
    methods: ["gps", "wifi", "biometric", "field"],
  );

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
                    const AttendanceStatusCard(status: _placeholderStatus),
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
