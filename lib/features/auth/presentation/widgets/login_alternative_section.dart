import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "Or log in with" divider and the fingerprint tile below it.
///
/// UI only for now: the tile has no action until biometric sign-in is built,
/// which needs its own domain/data layers.
class LoginAlternativeSection extends StatelessWidget {
  const LoginAlternativeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.gray200)),
            widthBx(w: 12),
            customText(
              l10n.loginOrLoginWith,
              fontSize: 12,
              color: AppColors.subTitle,
            ),
            widthBx(w: 12),
            const Expanded(child: Divider(color: AppColors.gray200)),
          ],
        ),
        heightBx(h: 20),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.fingerprint,
            size: 26,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
