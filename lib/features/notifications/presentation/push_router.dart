import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../domain/push_route.dart';

/// The one place a [PushTarget] becomes an App location (#53). #54 reuses
/// it for taps in the bell list.
abstract final class PushRouter {
  static String locationOf(PushTarget target) => switch (target) {
    LeaveRequestTarget(:final id) => AppRoutes.timeOffRequest(id),
    CorrectionTarget(:final id) => AppRoutes.myCorrectionRequest(id),
    OtRequestTarget(:final id) => AppRoutes.otRequest(id),
    OtPostsTarget() => AppRoutes.otPosts,
    MyOtTarget() => AppRoutes.overtime,
    HomeTarget() => AppRoutes.home,
  };
}

/// Opens [target]: Home by `go` (it is the root), anything else by `push`
/// on top of what shows, so Back always has somewhere to go. A provider so
/// tests can record instead of navigate.
final pushOpenerProvider = Provider<void Function(PushTarget target)>((ref) {
  return (target) {
    final router = ref.read(appRouterProvider);
    final location = PushRouter.locationOf(target);
    if (target is HomeTarget) {
      router.go(location);
    } else {
      router.push(location);
    }
  };
});
