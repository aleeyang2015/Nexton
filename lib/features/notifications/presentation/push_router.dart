import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../domain/push_route.dart';
import 'providers/notifications_notifier.dart';

/// The one place a [PushTarget] becomes an App location (#53); the bell
/// list's rows (#54) open through it too.
abstract final class PushRouter {
  static String locationOf(PushTarget target) => switch (target) {
    LeaveRequestTarget(:final id) => AppRoutes.timeOffRequest(id),
    CorrectionTarget(:final id) => AppRoutes.myCorrectionRequest(id),
    OtRequestTarget(:final id) => AppRoutes.otRequest(id),
    OtPostsTarget() => AppRoutes.otPosts,
    MyOtTarget() => AppRoutes.overtime,
    HomeTarget() => AppRoutes.home,
    NotificationsTarget() => AppRoutes.notifications,
  };
}

/// Opens [target]: Home by `go` (it is the root), anything else by `push`
/// on top of what shows, so Back always has somewhere to go. Done when the
/// page opened is closed again. A provider so tests can record instead of
/// navigate.
///
/// The bell list is read again (it may be open already, under the page on
/// top, and would show its old rows), and is not pushed over itself.
final pushOpenerProvider = Provider<Future<void> Function(PushTarget target)>((
  ref,
) {
  return (target) async {
    final router = ref.read(appRouterProvider);
    final location = PushRouter.locationOf(target);
    if (target is HomeTarget) {
      router.go(location);
      return;
    }
    if (target is NotificationsTarget) {
      ref.invalidate(notificationsNotifierProvider);
      // The page on top (`uri` is the bottom one's after a push).
      final top = router.routerDelegate.currentConfiguration.lastOrNull;
      if (top?.matchedLocation == location) return;
    }
    await router.push<void>(location);
  };
});
