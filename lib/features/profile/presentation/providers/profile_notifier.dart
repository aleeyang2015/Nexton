import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/employee_profile.dart';
import '../../profile_providers.dart';

/// Owns the signed-in user's employee profile. The home header and the
/// profile page render straight from this — neither fetches on its own.
///
/// Fetched independently of the auth session on purpose: a slow or failing
/// Core HR lookup must never hold up sign-in or block the home shell.
class ProfileNotifier extends AsyncNotifier<EmployeeProfile> {
  @override
  Future<EmployeeProfile> build() => _load();

  /// Re-runs the fetch, e.g. after the user retries a failed load.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<EmployeeProfile> _load() async {
    final result = await ref.read(getMyProfileUseCaseProvider)();
    return result.fold(
      (Failure failure) => throw failure,
      (profile) => profile,
    );
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, EmployeeProfile>(
      ProfileNotifier.new,
    );
