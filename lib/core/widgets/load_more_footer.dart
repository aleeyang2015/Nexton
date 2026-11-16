import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import 'global_widgets.dart';

/// What goes under the last row of a list that loads page after page: a
/// spinner while the next page is on its way, "could not load more" with a
/// Retry when it failed, and nothing otherwise.
///
/// The rows above stay whatever happens here.
class LoadMoreFooter extends StatelessWidget {
  final bool loadingMore;
  final bool failed;
  final VoidCallback onRetry;

  const LoadMoreFooter({
    super.key,
    required this.loadingMore,
    required this.failed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (!failed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: customText(
              l10n.listLoadMoreFailed,
              fontSize: 13,
              color: AppColors.subTitle,
              maxLine: 2,
            ),
          ),
          widthBx(w: 10),
          InkWell(
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: customText(
                l10n.retry,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
