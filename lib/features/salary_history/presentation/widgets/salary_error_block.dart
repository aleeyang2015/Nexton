import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The salary screens' inline failure state: an icon, the message and a
/// retry link. Shared by the history list and the payslip-detail sections.
///
/// [forFailure] picks the words for a failed load: a company that has not
/// bought payroll is told so, with no Retry (asking again gets the same
/// answer); a payslip that is not there (404) gets the screen's own "could
/// not load" with no Retry either; anything else gets that text and a
/// Retry.
class SalaryErrorBlock extends StatelessWidget {
  final String message;

  /// Null leaves the Retry link out.
  final VoidCallback? onRetry;

  const SalaryErrorBlock({
    super.key,
    required this.message,
    required this.onRetry,
  });

  factory SalaryErrorBlock.forFailure({
    Key? key,
    required AppLocalizations l10n,
    required Object? error,
    required String fallbackMessage,
    required VoidCallback onRetry,
  }) {
    final moduleOff =
        error is ValidationFailure &&
        error.code == ApiErrorCodes.moduleNotActive;
    // Not there (or not this person's, or not approved yet): asking again
    // gets the same answer.
    final notFound = error is NetworkFailure && error.statusCode == 404;

    return SalaryErrorBlock(
      key: key,
      message: moduleOff ? error.localize(l10n) : fallbackMessage,
      onRetry: moduleOff || notFound ? null : onRetry,
    );
  }

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
            if (onRetry != null) ...[
              heightBx(h: 12),
              InkWell(
                onTap: onRetry,
                child: customText(l10n.retry, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
