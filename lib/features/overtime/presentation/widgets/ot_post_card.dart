import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ot_post.dart';
import 'ot_copy.dart';
import 'ot_post_button.dart';

/// One HR post: its day and window, each piece's time and pay, the places
/// left, when joining closes, the reason, and the button
/// ([OtPostButton]).
class OtPostCard extends StatelessWidget {
  final OtPost post;

  /// True while a join for this post is on its way.
  final bool joining;

  /// True while a join for any post is on its way: the buttons wait.
  final bool busy;

  final VoidCallback onJoin;

  /// Opens the user's join (its request page).
  final VoidCallback onOpenJoin;

  const OtPostCard({
    super.key,
    required this.post,
    required this.joining,
    required this.busy,
    required this.onJoin,
    required this.onOpenJoin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workDate = post.workDate;
    final window = OtCopy.postWindow(l10n, post);
    final closes = OtCopy.closes(l10n, post);
    final reason = post.reason;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workDate != null)
            customText(
              OtCopy.date(workDate),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          if (window.isNotEmpty) ...[
            heightBx(h: 2),
            customText(window, fontSize: 14, color: AppColors.subTitle),
          ],
          for (final piece in post.pieces) ...[
            heightBx(h: 4),
            customText(
              OtCopy.piece(l10n, piece),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ],
          heightBx(h: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              customText(
                OtCopy.placesLeft(l10n, post),
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              if (closes != null)
                customText(closes, fontSize: 13, color: AppColors.subTitle),
            ],
          ),
          if (reason != null) ...[
            heightBx(h: 6),
            customText(
              reason,
              fontSize: 13,
              color: AppColors.subTitle,
              maxLine: 4,
            ),
          ],
          heightBx(h: 12),
          SizedBox(width: double.infinity, child: _button(l10n)),
        ],
      ),
    );
  }

  Widget _button(AppLocalizations l10n) {
    final state = OtPostButton.of(post);
    final label = switch (state) {
      OtPostButton.join => l10n.otPostJoin,
      OtPostButton.waiting => l10n.otPostWaitingHr,
      OtPostButton.accepted => l10n.otPostAccepted,
      OtPostButton.full => l10n.otPostFull,
      OtPostButton.cannotJoin => l10n.otPostCannotJoin,
    };

    if (state == OtPostButton.join) {
      return FilledButton(
        onPressed: busy ? null : onJoin,
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        child: joining
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : customText(
                label,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
      );
    }
    return OutlinedButton(
      onPressed: state.opensJoin ? onOpenJoin : null,
      child: customText(
        label,
        color: state.opensJoin ? AppColors.primary : AppColors.subTitle,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
