import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/modules/app_modules.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/presentation/widgets/attendance_status_card.dart';
import '../widgets/attendance_history_summary.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';

/// Home screen.
///
/// The attendance card owns its own state and talks to the attendance
/// feature directly, so this page composes rather than coordinates — the
/// header's profile details are the only placeholder data left here.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Clocking and its month summary are Core HR's: a company without it
    // would only see them fail (#61).
    final coreHr = ref.watch(hasModuleProvider(AppModules.coreHr));
    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              heightBx(),
              const HomeHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                  children: [
                    if (coreHr) ...[
                      const AttendanceStatusCard(),
                      heightBx(h: 22),
                      const AttendanceHistorySummary(),
                    ] else
                      const _ModuleOff(),
                    heightBx(h: 28),
                    const HomeMenuGrid(),
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

/// In place of the clock card when the company has no Core HR (#61): the
/// same words the server's `MODULE_NOT_ACTIVE` gets.
class _ModuleOff extends StatelessWidget {
  const _ModuleOff();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.subTitle),
          widthBx(w: 12),
          Expanded(
            child: customText(
              AppLocalizations.of(context)!.errorModuleNotActive,
              fontSize: 14,
              color: AppColors.subTitle,
              maxLine: 3,
            ),
          ),
        ],
      ),
    );
  }
}
