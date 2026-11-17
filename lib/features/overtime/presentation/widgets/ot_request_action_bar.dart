import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';
import '../providers/ot_detail_notifier.dart';
import 'ot_request_actions.dart';

/// Under the OT request: Edit and Cancel for the employee's own waiting
/// request, or, once it is approved, the line that says to ask the
/// approver or HR. Nothing on someone else's request. Which shows is
/// [OtRequestActions]'; the server still decides.
class OtRequestActionBar extends ConsumerStatefulWidget {
  final OtRequest request;

  const OtRequestActionBar({super.key, required this.request});

  @override
  ConsumerState<OtRequestActionBar> createState() =>
      _OtRequestActionBarState();
}

class _OtRequestActionBarState extends ConsumerState<OtRequestActionBar> {
  /// True while a cancel is asked for or on its way: the buttons wait.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = OtRequestActions.of(
      widget.request,
      ownEmployeeId: ref.watch(otOwnEmployeeIdProvider),
    );

    if (actions.askApprover) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: customText(
          l10n.otAskApproverToChange,
          fontSize: 13,
          color: AppColors.subTitle,
          alight: TextAlign.center,
          maxLine: 3,
        ),
      );
    }
    if (!actions.any) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 14),
      color: Colors.white,
      child: Row(
        children: [
          if (actions.canCancel)
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _cancel(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.danger),
                ),
                child: customText(
                  l10n.otCancelAction,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (actions.canCancel && actions.canEdit) widthBx(w: 12),
          if (actions.canEdit)
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _edit(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: customText(
                  l10n.otEditAction,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the edit form, once: a second tap while it opens, or while it is
  /// open, does nothing (two forms would send two edits, each restarting
  /// the approval).
  Future<void> _edit(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.push<void>(
        AppRoutes.otRequestEditOf(widget.request.id),
        extra: widget.request,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks first; then cancels and says what happened. A second tap while
  /// asking or sending does nothing.
  Future<void> _cancel(BuildContext context) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final sure = await AppDialog.ask(
        context,
        message: l10n.otCancelConfirm,
        confirmLabel: l10n.otCancelAction,
        // Not "Cancel": that is the other button's word here.
        cancelLabel: l10n.back,
      );
      if (!sure || !context.mounted) return;

      final result = await ref
          .read(otDetailNotifierProvider(widget.request.id).notifier)
          .cancel();
      if (result == null) return;
      result.fold(
        (failure) {
          // A request that is gone says so itself (the page's 404 path).
          if (!OtDetailNotifier.isGone(failure)) {
            AppToast.error(failure.localize(l10n));
          }
        },
        (_) => AppToast.success(l10n.otCancelledToast),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
