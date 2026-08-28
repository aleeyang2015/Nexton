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

/// Hosts the three bottom-nav tabs — ໜ້າຫຼັກ / ລາຍການ / ໂປຣຟາຍ — around the
/// existing [HomePage]. Home is the first tab and the one a session lands on;
/// all three are flat tabs of equal width.
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
        children: const [HomePage(), ListPage(), ProfilePage()],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: index,
        onTap: (i) => ref
            .read(mainShellTabProvider.notifier)
            .select(MainShellTab.values[i]),
        items: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: l10n.navHome,
          ),
          _NavItem(
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt,
            label: l10n.navList,
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Flat bottom bar — white, rounded top corners, lifted off the content
/// above with a soft shadow. Three equal-width tabs, no raised button.
class _BottomNavBar extends StatelessWidget {
  static const _barHeight = 68.0;

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

    return Container(
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
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavTab(
                item: items[i],
                selected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
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
          Icon(selected ? item.activeIcon : item.icon, color: color, size: 24),
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
