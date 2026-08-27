import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/widgets/home_shimmer.dart';
import '../../features/list/presentation/pages/list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../l10n/generated/app_localizations.dart';
import 'main_shell_tab_provider.dart';

/// Hosts the three bottom-nav tabs — ລາຍການ / ໜ້າຫຼັກ / ໂປຣຟາຍ — around the
/// existing [HomePage]. Home is the tab a session lands on, raised as a
/// floating circular button between the two flat side tabs.
///
/// This is also the route the router parks a cold start on while the stored
/// session is still resolving (see `authRedirect`), so until a session with
/// data is in hand it paints [HomeShimmer] instead of the tabs — the router
/// redirects away to `/login` or `/change-password` the moment resolution
/// says this isn't a signed-in user, so that never has to render for real.
class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null || !session.hasSession) {
      return const Scaffold(body: HomeShimmer());
    }

    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(mainShellTabProvider).index;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [ListPage(), HomePage(), ProfilePage()],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: index,
        onTap: (i) => ref
            .read(mainShellTabProvider.notifier)
            .select(MainShellTab.values[i]),
        items: [
          _NavItem(icon: Icons.list_alt, label: l10n.navList),
          _NavItem(icon: Icons.home, label: l10n.navHome),
          _NavItem(icon: Icons.person, label: l10n.navProfile),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _BottomNavBar extends StatelessWidget {
  static const _barHeight = 78.0;
  static const _buttonSize = 64.0;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _barHeight + _buttonSize / 2 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The bar itself — white, rounded top corners, lifted off the
          // content above with a soft shadow.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _barHeight + bottomInset,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SideTab(
                      item: items[0],
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  const SizedBox(width: _buttonSize),
                  Expanded(
                    child: _SideTab(
                      item: items[2],
                      selected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The Home tab, raised as a floating circular button straddling
          // the bar's top edge — the centerpiece of the bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _RaisedHomeButton(
              item: items[1],
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SideTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.gray400;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RaisedHomeButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _RaisedHomeButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: _BottomNavBar._buttonSize,
            height: _BottomNavBar._buttonSize,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
