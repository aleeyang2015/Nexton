import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/paged_list_end.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/presentation/widgets/requests_list_message.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/push_route.dart';
import '../providers/notifications_notifier.dart';
import '../push_router.dart';
import '../widgets/notification_row.dart';

/// "ແຈ້ງເຕືອນ" (#54): the user's recent pushes, newest first, a page at a
/// time. A row opens what its push opens (#53). Opened from the bell on
/// Home and from Profile.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    final rows = state.rows;
    final list = rows.valueOrNull;

    final List<Widget> body;
    if (rows.isLoading && list == null) {
      body = const [_Loading()];
    } else if (rows.hasError && list == null) {
      body = [
        RequestsListMessage(
          icon: Icons.error_outline,
          text: l10n.notificationsLoadFailed,
          onRetry: notifier.retry,
        ),
      ];
    } else if (state.visible.isEmpty) {
      body = [
        RequestsListMessage(
          icon: Icons.notifications_none_outlined,
          text: l10n.notificationsEmpty,
        ),
      ];
    } else {
      body = [
        for (final row in state.visible)
          NotificationRow(
            notification: row,
            onTap: _opensSomething(row) ? () => _open(ref, row) : null,
          ),
      ];
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
            ),
            title: customText(
              l10n.notifications,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final ok = await notifier.refresh();
              // The rows shown stay; say they were not renewed.
              if (!ok) AppToast.error(l10n.notificationsLoadFailed);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
              children: [
                ...body,
                if (list != null && !rows.isLoading)
                  PagedListEnd(
                    list: list,
                    onLoadMore: notifier.loadMore,
                    onRetry: notifier.retryLoadMore,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A row whose push has nowhere of its own to open (an unknown kind, or
  /// one missing its id) would only open this list again.
  static bool _opensSomething(AppNotification row) =>
      pushTarget(row.routeData) is! NotificationsTarget;

  static void _open(WidgetRef ref, AppNotification row) =>
      ref.read(pushOpenerProvider)(pushTarget(row.routeData));
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      4,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: ShimmerBox(width: double.infinity, height: 84),
      ),
    ),
  );
}
