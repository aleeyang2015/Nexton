import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The salary screens' inline failure state: an icon, the message and a
/// retry link. Shared by the history list and the payslip-detail sections.
class SalaryErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SalaryErrorBlock({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
            heightBx(h: 8),
            customText(message, color: AppColors.subTitle, alight: TextAlign.center),
            heightBx(h: 12),
            InkWell(
              onTap: onRetry,
              child: customText(l10n.retry, color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
