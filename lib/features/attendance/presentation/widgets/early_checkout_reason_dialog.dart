import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/punch_outcome.dart';
import 'attendance_copy.dart';

/// Collects the justification a clock-out needs when it lands before the
/// session's early-exit grace (§4 rule 4).
///
/// This is the one refusal with a way forward: the same punch, re-sent with
/// `notes`, is accepted. Returns the typed reason, or null if the user backed
/// out — in which case the clock-out simply doesn't happen.
class EarlyCheckoutReasonDialog extends StatefulWidget {
  final PunchBlockDetails details;

  const EarlyCheckoutReasonDialog({super.key, required this.details});

  /// Shows the dialog and resolves to the reason, or null on cancel.
  static Future<String?> show(BuildContext context, PunchBlockDetails details) {
    return showDialog<String>(
      context: context,
      // The user must answer or cancel: dismissing by tapping outside would
      // silently drop a clock-out they meant to make.
      barrierDismissible: false,
      builder: (_) => EarlyCheckoutReasonDialog(details: details),
    );
  }

  @override
  State<EarlyCheckoutReasonDialog> createState() =>
      _EarlyCheckoutReasonDialogState();
}

class _EarlyCheckoutReasonDialogState extends State<EarlyCheckoutReasonDialog> {
  final _controller = TextEditingController();

  /// The backend rejects an empty reason, so the submit button stays disabled
  /// until there is something to send.
  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: customText(
        l10n.earlyCheckoutTitle,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            AttendanceCopy.earlyCheckoutPrompt(l10n, widget.details),
            color: AppColors.secondaryTxt,
            fontSize: 14,
            maxLine: 3,
          ),
          heightBx(h: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.done,
            decoration: inputDecoration(l10n.earlyCheckoutHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: customText(l10n.cancel, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: customText(
            l10n.earlyCheckoutSubmit,
            color: _canSubmit ? AppColors.secondary : AppColors.gray400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
