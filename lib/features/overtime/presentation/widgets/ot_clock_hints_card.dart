import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "ວິທີສະແກນໂອທີ": how to clock OT so it is paid, closed until opened.
/// The rules are the server's: an OT clock-in opens 30 minutes before the
/// start, a clock-out closes it until 60 minutes after the end, and two OTs
/// less than 60 minutes apart are one run.
class OtClockHintsCard extends StatelessWidget {
  const OtClockHintsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hints = [
      l10n.otClockHintAfterShift,
      l10n.otClockHintWindow,
      l10n.otClockHintTwoOts,
      l10n.otClockHintThisApp,
    ];

    // A Material, not a coloured box: the tile's ripple paints on it.
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Theme(
        // No divider lines when it opens.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.lightbulb_outline, color: AppColors.primary),
          title: customText(
            l10n.otClockHintsTitle,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final hint in hints)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText('•  ', color: AppColors.subTitle),
                    Expanded(
                      child: customText(
                        hint,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        maxLine: 6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
