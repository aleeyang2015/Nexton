import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/offsite_requests_tab.dart';

/// "ຄຳຮ້ອງຂອງຂ້ອຍ" (#42): the requests the employee has filed, one tab per
/// kind. Off-site scans for now; #45 adds "forgot to scan". The tab bar
/// shows with one tab too, so the place looks the same when more arrive.
class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 1,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Scaffold(
            backgroundColor: AppColors.homeBackground,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                // Reached from a request's page opened by a toast or a link,
                // there may be nothing underneath.
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              ),
              title: customText(
                l10n.attMyRequestsTitle,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              bottom: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.subTitle,
                indicatorColor: AppColors.primary,
                tabs: [Tab(text: l10n.attOffsiteTab)],
              ),
            ),
            body: const TabBarView(children: [OffsiteRequestsTab()]),
          ),
        ),
      ),
    );
  }
}
