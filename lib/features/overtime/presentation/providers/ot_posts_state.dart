import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../domain/entities/ot_post.dart';

/// HR's open posts for the user's department, and which one is being
/// joined.
class OtPostsState {
  final AsyncValue<PagedList<OtPost>> posts;

  /// The post a join is on its way for; null when none is.
  final String? joiningId;

  const OtPostsState({
    this.posts = const AsyncValue.loading(),
    this.joiningId,
  });

  OtPostsState withPosts(AsyncValue<PagedList<OtPost>> posts) =>
      OtPostsState(posts: posts, joiningId: joiningId);

  OtPostsState withJoining(String? joiningId) =>
      OtPostsState(posts: posts, joiningId: joiningId);
}
