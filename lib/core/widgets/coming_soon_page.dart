import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'global_widgets.dart';

/// Generic placeholder body for a bottom-nav tab that doesn't have a real
/// screen yet. Swap this out for the real page without touching the nav
/// structure in `MainShellPage`.
class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonPage({super.key, required this.title, required this.icon});

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
            title: customText(title, fontWeight: FontWeight.w700, fontSize: 18),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppColors.gray400),
                heightBx(h: 12),
                customText(l10n.comingSoon, color: AppColors.subTitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
