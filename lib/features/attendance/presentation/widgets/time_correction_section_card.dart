import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// A white card with a bold title (plus a red `*` when [required]), an
/// optional [trailing] widget on the title row, and the field below.
class TimeCorrectionSectionCard extends StatelessWidget {
  final String title;
  final bool required;
  final Widget? trailing;
  final Widget child;

  const TimeCorrectionSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.required = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    children: [
                      if (required)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.danger),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[widthBx(w: 8), trailing!],
            ],
          ),
          heightBx(h: 12),
          child,
        ],
      ),
    );
  }
}

/// The "ແຈ້ງເຕືອນລະບົບ" banner at the top of the form: the request goes to
/// the employee's manager for approval.
class TimeCorrectionNotice extends StatelessWidget {
  const TimeCorrectionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.primaryVariant,
              size: 22,
            ),
          ),
          widthBx(w: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  l10n.timeCorrectionNoticeTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                heightBx(h: 2),
                customText(
                  l10n.timeCorrectionNoticeBody,
                  fontSize: 13,
                  color: AppColors.secondaryTxt,
                  maxLine: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip for a card's title row, e.g. the shift's "Shift A".
class TimeCorrectionBadge extends StatelessWidget {
  final String label;

  const TimeCorrectionBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: customText(
        label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2E7D32),
      ),
    );
  }
}
