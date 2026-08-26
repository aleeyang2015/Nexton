import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/leave_approvals_tab.dart';
import '../widgets/leave_history_tab.dart';
import '../widgets/leave_request_tab.dart';

/// The "ຂໍລາພັກ" destination behind the list page's menu button: a 3-tab
/// screen for the leave history, the request-leave form and the
/// team-approvals list, opening on the history tab.
class TimeOffPage extends StatefulWidget {
  const TimeOffPage({super.key});

  @override
  State<TimeOffPage> createState() => _TimeOffPageState();
}

class _TimeOffPageState extends State<TimeOffPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_controller.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.timeOffHistoryTab,
      l10n.timeOffRequestTab,
      l10n.timeOffApprovalsTab,
    ];

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: customText(
              titles[_controller.index],
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            bottom: TabBar(
              controller: _controller,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.subTitle,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(icon: const Icon(Icons.history), text: l10n.timeOffHistoryTab),
                Tab(
                  icon: const Icon(Icons.note_add_outlined),
                  text: l10n.timeOffRequestTab,
                ),
                Tab(icon: const Icon(Icons.approval), text: l10n.timeOffApprovalsTab),
              ],
            ),
          ),
          body: TabBarView(
            controller: _controller,
            children: const [
              LeaveHistoryTab(),
              LeaveRequestTab(),
              LeaveApprovalsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
