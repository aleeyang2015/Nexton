import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ot_request.dart';
import 'ot_copy.dart';

/// One OT request in the list: its day, the window as typed, the status
/// pill, and the "from an HR post" and "did not come" badges. A tap opens
/// the request's page ([onTap]).
class OtRequestRow extends StatelessWidget {
  final OtRequest request;
  final VoidCallback? onTap;

  const OtRequestRow({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workDate = request.workDate;
    final pill = OtCopy.statusPill(l10n, request.status);
    final window = OtCopy.window(l10n, request);

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: customText(
                  workDate == null ? '' : OtCopy.date(workDate),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (pill != null) _Pill(label: pill.label, color: pill.color),
            ],
          ),
          if (window.isNotEmpty) ...[
            heightBx(h: 4),
            customText(window, fontSize: 14, color: AppColors.subTitle),
          ],
          if (request.announcementId != null || request.didNotCome) ...[
            heightBx(h: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (request.announcementId != null)
                  _Badge(label: l10n.otFromPost, color: AppColors.info),
                if (request.didNotCome)
                  _Badge(label: l10n.otDidNotCome, color: AppColors.danger),
              ],
            ),
          ],
        ],
      ),
    );

    final onTap = this.onTap;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: onTap == null
          ? card
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: card,
              ),
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: customText(
      label,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: customText(label, fontSize: 11, color: color),
  );
}
