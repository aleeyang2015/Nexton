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
/// the approvals page opens, on whichever tab. It also keeps the auto-dispose
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
    // The list comes a page at a time, so the count is what has been loaded,
    // with a `+` while there is more: "20+", the same words as the header.
    final label = ref.watch(
      leaveApprovalsNotifierProvider.select((state) {
        final pending = state.pending.valueOrNull;
        if (pending == null || pending.items.isEmpty) return null;
        // Past 99 the exact number stops being the point, and a longer
        // badge would bleed over the neighbouring tab.
        return pending.items.length > 99 ? '99+' : pending.countLabel;
      }),
    );

    const icon = Icon(Icons.approval);
    if (label == null) return icon;

    return Badge(
      backgroundColor: AppColors.danger,
      textColor: AppColors.textWhite,
      label: Text(label),
      child: icon,
    );
  }
}
