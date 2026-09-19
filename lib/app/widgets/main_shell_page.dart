import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/widgets/home_shimmer.dart';

/// The signed-in landing screen: [HomePage], with no bottom navigation. The
/// profile screen is a pushed route opened from the home header's avatar.
///
/// This is also the route the router parks a cold start on while the stored
/// session is still resolving (see `authRedirect`), so until a session with
/// data is in hand it paints [HomeShimmer] instead of the page — the router
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

    return const Scaffold(body: HomePage());
  }
}
