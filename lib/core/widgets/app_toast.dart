import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wired into [MaterialApp.scaffoldMessengerKey] so a toast can be raised from
/// anywhere — a notifier, a Dio callback, a widget with no Scaffold above it —
/// without threading a [BuildContext] through the call site.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// The four shapes a toast comes in. Mirrors [AppDialogVariant] minus the
/// question case — a toast never asks anything, it only reports.
enum AppToastVariant { success, warning, error, info }

/// The app's global toast. The app reports every error through a dialog or a
/// toast; this is the toast half.
///
/// Purely presentational: callers decide *when* to show one and pass an
/// already-localized [message]. It resolves the messenger from
/// [rootScaffoldMessengerKey], so no context is required and a null messenger
/// (before the first frame) is a silent no-op rather than a crash.
class AppToast {
  AppToast._();

  /// Reports that something completed.
  static void success(String message) =>
      _show(message, AppToastVariant.success);

  /// Reports something the user should deal with, short of an outright failure.
  static void warning(String message) =>
      _show(message, AppToastVariant.warning);

  /// Reports a failure — a rejected login, a network error, a 500. Pass
  /// [actionLabel] with [onAction] to offer a single follow-up (e.g. "Retry").
  static void error(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    message,
    AppToastVariant.error,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  /// Reports a neutral fact the user should notice.
  static void info(String message) => _show(message, AppToastVariant.info);

  static void _show(
    String message,
    AppToastVariant variant, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_iconOf(variant), color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: _colorOf(variant),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  static Color _colorOf(AppToastVariant variant) => switch (variant) {
    AppToastVariant.success => AppColors.success,
    AppToastVariant.warning => AppColors.warning,
    AppToastVariant.error => AppColors.danger,
    AppToastVariant.info => AppColors.info,
  };

  static IconData _iconOf(AppToastVariant variant) => switch (variant) {
    AppToastVariant.success => Icons.check_circle_outline,
    AppToastVariant.warning => Icons.warning_amber_rounded,
    AppToastVariant.error => Icons.error_outline,
    AppToastVariant.info => Icons.info_outline,
  };
}
