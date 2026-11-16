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
/// bought payroll is told so; anything else gets the screen's own "could
/// not load". Retry is offered only when asking again can help (see
/// [isFinal]).
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
    return SalaryErrorBlock(
      key: key,
      message: isModuleOff(error) && error is Failure
          ? error.localize(l10n)
          : fallbackMessage,
      onRetry: isFinal(error) ? null : onRetry,
    );
  }

  /// The company has not bought payroll (`403 MODULE_NOT_ACTIVE`).
  static bool isModuleOff(Object? error) =>
      error is ValidationFailure &&
      error.code == ApiErrorCodes.moduleNotActive;

  /// Not there, not this person's, or not approved yet (`404`): the server
  /// gives one answer for all three.
  static bool isNotFound(Object? error) =>
      error is NetworkFailure && error.statusCode == 404;

  /// True for an answer that asking again cannot change: a refusal (no
  /// payroll, not allowed, a request the server calls invalid), a payslip
  /// that is not there, or one the App could not read. No Retry is offered
  /// for these. No signal and a server error are worth another try.
  static bool isFinal(Object? error) =>
      error is ValidationFailure || isNotFound(error);

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
            // Room for a sentence: the Lao texts do not fit on one line of a
            // narrow phone.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: customText(
                message,
                color: AppColors.subTitle,
                alight: TextAlign.center,
                maxLine: 4,
              ),
            ),
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
