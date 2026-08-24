import 'package:flutter/material.dart';

import '../../../../core/widgets/global_widgets.dart';
import '../../../attendance/presentation/widgets/attendance_status_card.dart';
import '../widgets/home_header.dart';

/// Home screen.
///
/// The attendance card owns its own state and talks to the attendance
/// feature directly, so this page composes rather than coordinates — the
/// header's profile details are the only placeholder data left here.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  children: const [AttendanceStatusCard()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
