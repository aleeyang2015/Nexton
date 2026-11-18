import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// A "My requests" tab's empty or failed state: an icon, a line, and a Retry
/// when there is something to retry.
class RequestsListMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const RequestsListMessage({
    super.key,
    required this.icon,
    required this.text,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retry = onRetry;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gray400, size: 36),
          heightBx(h: 8),
          customText(
            text,
            color: AppColors.subTitle,
            alight: TextAlign.center,
            maxLine: 2,
          ),
          if (retry != null) ...[
            heightBx(h: 12),
            InkWell(
              onTap: retry,
              child: customText(
                l10n.retry,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
