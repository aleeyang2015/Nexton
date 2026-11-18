import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';

/// The frame of a gate screen (#57): an icon, a title, a text and what can
/// be done, with no way back past it.
class AppGateScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  const AppGateScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 72, color: AppColors.primary),
                  heightBx(h: 24),
                  customText(
                    title,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    alight: TextAlign.center,
                    maxLine: 2,
                  ),
                  heightBx(h: 12),
                  customText(
                    body,
                    fontSize: 15,
                    color: AppColors.subTitle,
                    alight: TextAlign.center,
                    maxLine: 6,
                  ),
                  for (final action in actions) ...[heightBx(h: 24), action],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
