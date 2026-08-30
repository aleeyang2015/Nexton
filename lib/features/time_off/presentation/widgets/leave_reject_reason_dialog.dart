import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Collects the rejection reason `PUT /leave/requests/:id/reject` requires
/// (leave-request-flutter.md §3.10). Modelled on `EarlyCheckoutReasonDialog`.
///
/// Resolves to the trimmed reason, or null if the approver backed out.
class LeaveRejectReasonDialog extends StatefulWidget {
  const LeaveRejectReasonDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LeaveRejectReasonDialog(),
    );
  }

  @override
  State<LeaveRejectReasonDialog> createState() =>
      _LeaveRejectReasonDialogState();
}

class _LeaveRejectReasonDialogState extends State<LeaveRejectReasonDialog> {
  final _controller = TextEditingController();

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
        l10n.leaveRejectReasonTitle,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        minLines: 2,
        textInputAction: TextInputAction.done,
        decoration: inputDecoration(l10n.leaveRejectReasonHint),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: customText(l10n.cancel, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: customText(
            l10n.leaveRejectReasonSubmit,
            color: _canSubmit ? AppColors.danger : AppColors.gray400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
