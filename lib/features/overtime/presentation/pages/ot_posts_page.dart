import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ot_post.dart';
import '../providers/ot_detail_notifier.dart';
import '../providers/ot_posts_notifier.dart';
import '../widgets/ot_copy.dart';
import '../widgets/ot_post_card.dart';

/// "ປະກາດໂອທີ": HR's open OT posts for the user's department, soonest
/// first, and joining one. Pull to refresh; the next page loads near the
/// end. Everything comes from [otPostsNotifierProvider].
class OtPostsPage extends ConsumerStatefulWidget {
  const OtPostsPage({super.key});

  @override
  ConsumerState<OtPostsPage> createState() => _OtPostsPageState();
}

class _OtPostsPageState extends ConsumerState<OtPostsPage> {
  static const double _loadMoreWithin = 300;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMoreIfNearEnd);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _loadMoreIfNearEnd() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter > _loadMoreWithin) return;
    ref.read(otPostsNotifierProvider.notifier).loadMore();
  }

  /// Asks first; then joins and says what happened.
  Future<void> _join(OtPost post) async {
    final l10n = AppLocalizations.of(context)!;
    final sure = await AppDialog.ask(
      context,
      message: l10n.otPostJoinConfirm,
      confirmLabel: l10n.otPostJoin,
      cancelLabel: l10n.back,
    );
    if (!sure || !mounted) return;

    final result = await ref
        .read(otPostsNotifierProvider.notifier)
        .join(post.id);
    if (result == null) return;
    result.fold(
      (failure) => AppToast.error(
        OtDetailNotifier.isGone(failure)
            ? l10n.otPostGone
            : failure.localize(l10n),
      ),
      (_) => AppToast.success(l10n.otPostJoinSent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(otPostsNotifierProvider);
    final notifier = ref.read(otPostsNotifierProvider.notifier);
    final list = state.posts.valueOrNull;

    ref.listen(otPostsNotifierProvider.select((s) => s.posts), (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMoreIfNearEnd();
      });
    });

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.overtime),
                      child: popBack(),
                    ),
                    widthBx(w: 4),
                    Expanded(
                      child: customText(
                        l10n.otPostsTitle,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (!await notifier.refresh() && context.mounted) {
                      AppToast.error(l10n.otListLoadFailed);
                    }
                  },
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 40),
                    children: [
                      _Body(
                        posts: state.posts,
                        joiningId: state.joiningId,
                        onRetry: notifier.retry,
                        onJoin: _join,
                        onOpenJoin: (post) => context.push(
                          AppRoutes.otRequest(post.myJoin!.id),
                          extra: post.myJoin,
                        ),
                      ),
                      if (list != null && !state.posts.isLoading)
                        LoadMoreFooter(
                          loadingMore: list.loadingMore,
                          failed: list.loadMoreError != null,
                          onRetry: notifier.retryLoadMore,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AsyncValue<PagedList<OtPost>> posts;
  final String? joiningId;
  final VoidCallback onRetry;
  final void Function(OtPost) onJoin;
  final void Function(OtPost) onOpenJoin;

  const _Body({
    required this.posts,
    required this.joiningId,
    required this.onRetry,
    required this.onJoin,
    required this.onOpenJoin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = posts.valueOrNull;

    if (list == null && posts.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (posts.hasError && !posts.isLoading) {
      final shown = OtCopy.listError(l10n, posts.error);
      return _Message(
        text: shown.message,
        retryLabel: shown.canRetry ? l10n.retry : null,
        onRetry: onRetry,
      );
    }
    if (list == null || list.items.isEmpty) {
      return _Message(text: l10n.otPostsEmpty);
    }
    return Column(
      children: [
        for (final post in list.items)
          OtPostCard(
            post: post,
            joining: joiningId == post.id,
            busy: joiningId != null,
            onJoin: () => onJoin(post),
            onOpenJoin: () => onOpenJoin(post),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const _Message({required this.text, this.retryLabel, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final retryLabel = this.retryLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          customText(
            text,
            color: AppColors.subTitle,
            alight: TextAlign.center,
            maxLine: 4,
          ),
          if (retryLabel != null) ...[
            heightBx(h: 12),
            TextButton(
              onPressed: onRetry,
              child: customText(
                retryLabel,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
