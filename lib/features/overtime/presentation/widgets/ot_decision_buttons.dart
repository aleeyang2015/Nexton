import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../approvals/domain/approver_access.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../domain/entities/ot_request.dart';
import '../providers/ot_decision_notifier.dart';
import 'ot_decision_flow.dart';

/// A head's buttons on an OT request (#49), on its row and its page:
/// Reject and Approve while it waits at their step
/// ([ApproverAccess.canDecideOt]); "ຍົກເລີກໂອທີ" on an OT they approved that
/// has not started ([ApproverAccess.canCancelApprovedOt]). Nothing
/// otherwise. Off while an action is on its way. [onEnd] hears how an
/// action ended (the page goes back when the request is gone).
class OtDecisionButtons extends ConsumerWidget {
  const OtDecisionButtons({
    super.key,
    required this.request,
    this.onEnd,
    this.padding = EdgeInsets.zero,
  });

  final OtRequest request;
  final ValueChanged<OtDecisionEnd>? onEnd;

  /// Around the buttons, when there are any (none: no space taken).
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user),
    );
    final provider = otDecisionNotifierProvider(request.id);
    final decision = ref.watch(provider);
    final now = ref.watch(clockProvider)();
    final canDecide = ApproverAccess.canDecideOt(request, user);
    final canCancel =
        !decision.cancelHidden &&
        ApproverAccess.canCancelApprovedOt(request, user, now);
    if (!canDecide && !canCancel) return const SizedBox.shrink();

    final enabled = !decision.deciding;
    final notifier = ref.read(provider.notifier);
    Future<void> after(Future<OtDecisionEnd> done) async {
      final end = await done;
      onEnd?.call(end);
    }

    if (canCancel) {
      return Padding(
        padding: padding,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: enabled
                ? () => after(
                    OtDecisionFlow.cancelApproved(context, notifier, request),
                  )
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.danger),
            ),
            child: customText(
              l10n.otCancelApprovedAction,
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: enabled
                  ? () =>
                        after(OtDecisionFlow.reject(context, notifier, request))
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.danger),
              ),
              child: customText(
                l10n.leaveApprovalRejectAction,
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          widthBx(w: 10),
          Expanded(
            child: FilledButton(
              onPressed: enabled
                  ? () => after(
                      OtDecisionFlow.approve(context, notifier, request),
                    )
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: customText(
                l10n.leaveApprovalApproveAction,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
