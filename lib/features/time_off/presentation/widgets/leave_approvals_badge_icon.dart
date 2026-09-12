import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/leave_approvals_notifier.dart';

/// The approvals tab's icon, badged with how many leave requests are waiting
/// on the signed-in approver.
///
/// It watches the same `pending` list the tab body counts in its header
/// ([LeaveApprovalsTab]), so the badge and that header can never disagree.
/// `select` narrows the rebuild to the count itself — a decision going in or
/// out of flight must not repaint the tab bar.
///
/// Watching from the [TabBar] is deliberate: the badge has to be right before
/// the tab is ever opened, so this is what triggers the approvals fetch when
/// [TimeOffPage] opens, on whichever tab. It also keeps the auto-dispose
/// notifier alive for the life of the page, so switching tabs no longer
/// refetches.
///
/// Nothing is drawn at zero — an empty badge would read as "0 waiting" only
/// after the user stops to parse it, and a loading or failed fetch reports no
/// count rather than a wrong one.
class LeaveApprovalsBadgeIcon extends ConsumerWidget {
  const LeaveApprovalsBadgeIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      leaveApprovalsNotifierProvider.select(
        (state) => state.pending.valueOrNull?.length ?? 0,
      ),
    );

    const icon = Icon(Icons.approval);
    if (count == 0) return icon;

    return Badge(
      backgroundColor: AppColors.danger,
      textColor: AppColors.textWhite,
      // Past 99 the exact number stops being the point, and a 3-digit badge
      // would bleed over the neighbouring tab.
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
