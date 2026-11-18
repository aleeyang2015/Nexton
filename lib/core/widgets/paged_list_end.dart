import 'package:flutter/material.dart';

import '../network/paged_list.dart';
import 'load_more_footer.dart';

/// What sits under a paged list's last row: the trigger that asks for its
/// next page when it comes near the screen, and the footer that shows how
/// that page is doing. Shared by the approvals lists (#19, #46).
class PagedListEnd<T> extends StatelessWidget {
  final PagedList<T> list;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  const PagedListEnd({
    super.key,
    required this.list,
    required this.onLoadMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (list.canLoadMore)
          // A new one for each length, so a page that lands and leaves the
          // end still in view asks for the one after it.
          _LoadMoreWhenShown(
            key: ValueKey(list.items.length),
            onShown: onLoadMore,
          ),
        LoadMoreFooter(
          loadingMore: list.loadingMore,
          failed: list.loadMoreError != null,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

/// Calls [onShown] once, when it is first built.
///
/// A `ListView` builds a child only when it comes within reach of the
/// screen, so placing this after a list's last row means "the user is near
/// the end of this list": the moment to ask for its next page. That works
/// for a list in the middle of the page too, which the page's own scroll
/// position cannot tell from the one below it.
class _LoadMoreWhenShown extends StatefulWidget {
  final VoidCallback onShown;

  const _LoadMoreWhenShown({super.key, required this.onShown});

  @override
  State<_LoadMoreWhenShown> createState() => _LoadMoreWhenShownState();
}

class _LoadMoreWhenShownState extends State<_LoadMoreWhenShown> {
  @override
  void initState() {
    super.initState();
    // After this frame: asking changes the notifier's state, which may not
    // happen while the list is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
