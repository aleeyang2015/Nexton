import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/personal_info.dart';
import 'personal_info_copy.dart';

/// One emergency contact (#58): the name (and the Lao one), the
/// relationship, and the phones as plain text.
class EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;

  const EmergencyContactCard({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final relationship = contact.relationship;
    final phones = [?contact.phone, ?contact.phoneSecondary].join(' · ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.homeBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            contact.name,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            maxLine: 2,
          ),
          if (contact.nameLo case final String lo) ...[
            heightBx(h: 2),
            customText(lo, fontSize: 13, maxLine: 2),
          ],
          if (relationship != null) ...[
            heightBx(h: 4),
            customText(
              PersonalInfoCopy.relationship(l10n, relationship),
              fontSize: 13,
              color: AppColors.subTitle,
            ),
          ],
          heightBx(h: 4),
          customText(phones.isEmpty ? '-' : phones, fontSize: 14, maxLine: 2),
        ],
      ),
    );
  }
}
