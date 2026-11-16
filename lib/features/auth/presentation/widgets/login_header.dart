import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Brand block at the top of the login screen: app tile, wordmark, heading and
/// a line of guidance. Purely presentational.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  static const _wordmarkColor = Color(0xFF111B3A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        heightBx(h: 20),
        customText(
          'NEXTON',
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: _wordmarkColor,
        ),
        heightBx(h: 24),
        customText(
          l10n.login,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _wordmarkColor,
          alight: TextAlign.center,
        ),
        heightBx(h: 6),
        customText(
          l10n.loginSubtitle,
          fontSize: 13,
          color: AppColors.subTitle,
          alight: TextAlign.center,
          maxLine: 2,
        ),
      ],
    );
  }
}
