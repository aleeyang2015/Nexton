import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/leave_history_tab.dart';
import '../widgets/leave_request_tab.dart';

/// Which tab [TimeOffPage] should open on. The order matches the [TabBar]
/// below, so `.index` doubles as the tab index.
enum TimeOffTab { history, request }

/// The "ຂໍລາພັກ" destination behind the list page's menu button: a 2-tab
/// screen for the leave history and the request-leave form. Opens on the
/// history tab unless [initialTab] says otherwise — the list page's "ລາພັກ"
/// menu points it straight at the request-leave tab.
///
/// The team-approvals tab now lives on the approvals page, beside the
/// time-correction approvals, so an approver decides everything in one place.
class TimeOffPage extends StatefulWidget {
  const TimeOffPage({super.key, this.initialTab = TimeOffTab.history});

  final TimeOffTab initialTab;

  @override
  State<TimeOffPage> createState() => _TimeOffPageState();
}

class _TimeOffPageState extends State<TimeOffPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TabController(
          length: TimeOffTab.values.length,
          vsync: this,
          initialIndex: widget.initialTab.index,
        )..addListener(() {
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
    final titles = [l10n.timeOffHistoryTab, l10n.timeOffRequestTab];

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
            // AppBar(
            //   backgroundColor: Colors.white,
            //   elevation: 0,
            //   centerTitle: true,
            //   title: customText(
            //     titles[_controller.index],
            //     fontWeight: FontWeight.w700,
            //     fontSize: 18,
            //   ),
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
                Tab(
                  icon: const Icon(Icons.history),
                  text: l10n.timeOffHistoryTab,
                ),
                Tab(
                  icon: const Icon(Icons.note_add_outlined),
                  text: l10n.timeOffRequestTab,
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _controller,
            children: const [LeaveHistoryTab(), LeaveRequestTab()],
          ),
        ),
      ),
    );
  }
}
