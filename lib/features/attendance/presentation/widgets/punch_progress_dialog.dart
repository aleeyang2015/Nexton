import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/attendance_day.dart';

/// Blocks the screen while a punch is in flight, naming which punch it is.
///
/// A punch is not a quick call: acquiring a GPS fix alone is allowed up to
/// fifteen seconds, and the network round trip follows it. Without this the
/// app looks frozen — the slider springs back, nothing else moves, and the
/// natural response is to slide again.
class PunchProgressDialog extends StatelessWidget {
  /// Kept on screen at least this long once shown.
  ///
  /// A punch refused locally (Location Services off) resolves almost
  /// instantly, and a dialog that appears and vanishes within a frame or two
  /// reads as a glitch rather than as progress.
  static const Duration minimumVisible = Duration(milliseconds: 350);

  final ClockAction action;

  const PunchProgressDialog({super.key, required this.action});

  /// Runs [operation] behind the dialog and guarantees the dialog is taken
  /// down afterwards — including when [operation] throws.
  ///
  /// The result (or the error) is passed straight through, so callers read
  /// exactly as they did before the dialog existed.
  static Future<T> runWhile<T>(
    BuildContext context,
    ClockAction action,
    Future<T> Function() operation,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final shownAt = DateTime.now();

    // Deliberately not awaited: this future completes only when the dialog is
    // popped, which is what the `finally` below does.
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        // The user must not be able to dismiss a punch they cannot cancel.
        barrierDismissible: false,
        builder: (_) => PunchProgressDialog(action: action),
      ),
    );

    try {
      return await operation();
    } finally {
      final elapsed = DateTime.now().difference(shownAt);
      final remaining = minimumVisible - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }

      // The barrier means nothing else can have been pushed on top, so the
      // route on the end is this dialog.
      if (navigator.mounted && navigator.canPop()) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = action == ClockAction.clockIn
        ? l10n.clockingIn
        : l10n.clockingOut;

    return PopScope(
      // The request is already on its way; a back gesture must not strand it
      // behind a dismissed dialog.
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.secondary,
                ),
              ),
              widthBx(w: 16),
              Flexible(
                child: customText(
                  label,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  maxLine: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
