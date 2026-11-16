import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "Remember me" toggle
class RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;

  const RememberMeCheckbox({
    super.key,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            height: 24,
            width: 24,
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: value ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: value ? AppColors.primary : AppColors.gray400,
              ),
            ),
            child: const Icon(Icons.check, size: 15, color: Colors.white),
          ),
          widthBx(w: 10),
          customText(l10n.rememberMe, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}
