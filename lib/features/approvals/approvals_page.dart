import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/global_widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../attendance/presentation/widgets/offsite_approvals_tab.dart';
import '../attendance/presentation/widgets/time_correction_approvals_tab.dart';
import '../time_off/presentation/widgets/leave_approvals_badge_icon.dart';
import '../time_off/presentation/widgets/leave_approvals_tab.dart';

/// Which tab [ApprovalsPage] should open on. The order matches the [TabBar]
/// below, so `.index` doubles as the tab index.
enum ApprovalsTab { leave, timeCorrection, offsite }

/// "ອະນຸມັດ" — everything waiting on the signed-in approver, gathered behind
/// the home menu's single approvals tile: the leave requests
/// ([LeaveApprovalsTab], the same tab [TimeOffPage] shows), the time-correction
/// requests ([TimeCorrectionApprovalsTab]) and the off-site scan requests
/// ([OffsiteApprovalsTab]).
///
/// Both tabs are the feature's own widgets rather than copies, so a change to
/// either list shows up here and on its own screen at once. Each one owns its
/// provider, its filters and its empty / failed states; this page only holds
/// the chrome and the [TabController].
///
/// The title stays "ອະນຸມັດ" on both tabs — the tab bar already names the
/// section, so there is nothing for a switching title to add.
class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key, this.initialTab = ApprovalsTab.leave});

  final ApprovalsTab initialTab;

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: ApprovalsTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: customText(
              l10n.approvalsMenu,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 20,
            ),
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
            ),
            bottom: TabBar(
              controller: _controller,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.subTitle,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                // Badged with the pending count, and the watch that keeps the
                // leave approvals provider alive across tab switches.
                Tab(
                  icon: const LeaveApprovalsBadgeIcon(),
                  text: l10n.approvalsLeaveTab,
                ),
                Tab(
                  icon: const Icon(Icons.more_time),
                  text: l10n.approvalsTimeCorrectionTab,
                ),
                Tab(
                  icon: const Icon(Icons.wrong_location_outlined),
                  text: l10n.approvalsOffsiteTab,
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _controller,
            children: const [
              LeaveApprovalsTab(),
              TimeCorrectionApprovalsTab(),
              OffsiteApprovalsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
