import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/datasources/leave_error_code.dart';

/// What the request page and its edit page show when the request could not
/// be loaded: the reason, and a Retry when trying again can help.
///
/// No Retry when the server said the request is gone (or is not the
/// caller's), or that this login has no staff record: asking again gets the
/// same answer. The page's own back arrow is the way out.
class LeaveRequestUnavailable extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const LeaveRequestUnavailable({
    super.key,
    required this.error,
    required this.onRetry,
  });

  /// True when [error] is an answer, not a breakdown: retrying cannot change
  /// it.
  static bool isFinal(Object? error) =>
      error is Failure && LeaveErrorCode.tokenOf(error) != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = error;
    final message = failure is Failure
        ? failure.localize(l10n)
        : l10n.genericError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
            heightBx(h: 10),
            customText(
              message,
              color: AppColors.subTitle,
              alight: TextAlign.center,
              maxLine: 4,
            ),
            if (!isFinal(failure)) ...[
              heightBx(h: 14),
              InkWell(
                onTap: onRetry,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: customText(
                    l10n.retry,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
