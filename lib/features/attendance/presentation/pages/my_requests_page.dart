import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/offsite_requests_tab.dart';
import '../widgets/time_correction_requests_tab.dart';

/// The tabs of "My requests", in their order on screen.
enum MyRequestsTab { offsite, correction }

/// "ຄຳຮ້ອງຂອງຂ້ອຍ" (#42): the requests the employee has filed, one tab per
/// kind: off-site scans (#42) and "forgot to scan" (#45). [initialTab] is
/// the one it opens on (the old history addresses open their own).
class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key, this.initialTab = MyRequestsTab.offsite});

  final MyRequestsTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: MyRequestsTab.values.length,
      initialIndex: initialTab.index,
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
                tabs: [
                  Tab(text: l10n.attOffsiteTab),
                  Tab(text: l10n.attCorrectionTab),
                ],
              ),
            ),
            body: const TabBarView(
              children: [OffsiteRequestsTab(), TimeCorrectionRequestsTab()],
            ),
          ),
        ),
      ),
    );
  }
}
