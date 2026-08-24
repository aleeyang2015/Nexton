import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import 'global_widgets.dart';

/// The four shapes a global dialog comes in.
///
/// The variant decides the icon and its colour only — never the button, which
/// stays [AppColors.primary] throughout so the confirming action looks the
/// same everywhere in the app.
enum AppDialogVariant {
  /// Something finished.
  success,

  /// Something needs attention before it can finish.
  warning,

  /// Something failed.
  error,

  /// Something needs a yes or no.
  question,
}

/// The app's standard dialog: an outlined circular icon, a centred message,
/// and a full-width primary action.
///
/// Use the named constructors rather than building this directly —
/// [AppDialog.success], [AppDialog.warning], [AppDialog.error] and
/// [AppDialog.ask] each show the dialog and resolve when it closes.
class AppDialog extends StatelessWidget {
  final AppDialogVariant variant;

  /// Optional heading above [message]. Most dialogs need only the message.
  final String? title;

  final String message;

  /// Defaults to the localized "OK".
  final String? confirmLabel;

  /// Shown only for [AppDialogVariant.question]. Defaults to "Cancel".
  final String? cancelLabel;

  const AppDialog({
    super.key,
    required this.variant,
    required this.message,
    this.title,
    this.confirmLabel,
    this.cancelLabel,
  });

  /// Reports that something completed.
  static Future<void> success(
    BuildContext context, {
    required String message,
    String? title,
    String? confirmLabel,
    bool barrierDismissible = true,
  }) => _show<void>(
    context,
    AppDialogVariant.success,
    message: message,
    title: title,
    confirmLabel: confirmLabel,
    barrierDismissible: barrierDismissible,
  );

  /// Reports something the user has to deal with before continuing.
  static Future<void> warning(
    BuildContext context, {
    required String message,
    String? title,
    String? confirmLabel,
    bool barrierDismissible = true,
  }) => _show<void>(
    context,
    AppDialogVariant.warning,
    message: message,
    title: title,
    confirmLabel: confirmLabel,
    barrierDismissible: barrierDismissible,
  );

  /// Reports a failure.
  static Future<void> error(
    BuildContext context, {
    required String message,
    String? title,
    String? confirmLabel,
    bool barrierDismissible = true,
  }) => _show<void>(
    context,
    AppDialogVariant.error,
    message: message,
    title: title,
    confirmLabel: confirmLabel,
    barrierDismissible: barrierDismissible,
  );

  /// Asks a yes/no question. Resolves `true` only when the user confirms —
  /// dismissing the dialog counts as "no", so a caller can act on the answer
  /// without a null check.
  ///
  /// Not dismissible by default: an unanswered question is ambiguous, and the
  /// caller is about to do something on the strength of the answer.
  static Future<bool> ask(
    BuildContext context, {
    required String message,
    String? title,
    String? confirmLabel,
    String? cancelLabel,
    bool barrierDismissible = false,
  }) async {
    final answer = await _show<bool>(
      context,
      AppDialogVariant.question,
      message: message,
      title: title,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      barrierDismissible: barrierDismissible,
    );

    return answer ?? false;
  }

  static Future<T?> _show<T>(
    BuildContext context,
    AppDialogVariant variant, {
    required String message,
    String? title,
    String? confirmLabel,
    String? cancelLabel,
    required bool barrierDismissible,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog(
        variant: variant,
        message: message,
        title: title,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }

  /// The accent for [variant] — the icon only.
  Color get _accent => switch (variant) {
    AppDialogVariant.success => AppColors.success,
    AppDialogVariant.warning => AppColors.warning,
    AppDialogVariant.error => AppColors.danger,
    AppDialogVariant.question => AppColors.secondary,
  };

  IconData get _icon => switch (variant) {
    AppDialogVariant.success => Icons.check,
    AppDialogVariant.warning => Icons.priority_high,
    AppDialogVariant.error => Icons.close,
    AppDialogVariant.question => Icons.question_mark,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isQuestion = variant == AppDialogVariant.question;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _VariantBadge(color: _accent, icon: _icon),
            ),
            heightBx(h: 20),
            if (title != null) ...[
              customText(
                title!,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                alight: TextAlign.center,
                maxLine: 2,
              ),
              heightBx(h: 8),
            ],
            customText(
              message,
              fontSize: 16,
              color: AppColors.textPrimary,
              alight: TextAlign.center,
              // Long backend messages must wrap, not be clipped to one line.
              maxLine: 6,
            ),
            heightBx(h: 24),
            // Reuses the app's standard call to action, so the confirming
            // button is the same shape and colour everywhere.
            button(
              () =>
                  Navigator.of(context).pop<Object?>(isQuestion ? true : null),
              confirmLabel ?? l10n.ok,
            ),
            if (isQuestion) ...[
              heightBx(h: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop<Object?>(false),
                child: customText(
                  cancelLabel ?? l10n.cancel,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The outlined circle that carries the variant's icon.
class _VariantBadge extends StatelessWidget {
  static const double _size = 72;

  final Color color;
  final IconData icon;

  const _VariantBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, size: 38, color: color),
    );
  }
}
