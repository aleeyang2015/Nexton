import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/employee_profile.dart';
import '../../profile_providers.dart';

/// Owns the signed-in user's employee profile. The home header and the
/// profile page render straight from this — neither fetches on its own.
///
/// Fetched independently of the auth session on purpose: a slow or failing
/// Core HR lookup must never hold up sign-in or block the home shell.
class ProfileNotifier extends AutoDisposeAsyncNotifier<EmployeeProfile> {
  /// A quiet read is on its way ([reloadQuietly]).
  bool _quietReading = false;

  @override
  Future<EmployeeProfile> build() => _load();

  /// The photo just changed (#59): the profile shows it at once, without
  /// asking for the whole record again. Nothing when no profile is loaded.
  ///
  /// A load on its way (a pull to refresh during the upload) is waited for
  /// first: it may have been answered before the photo changed.
  Future<void> showPhoto(String url) async {
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {
        return;
      }
    }
    final profile = state.valueOrNull;
    if (profile == null) return;
    state = AsyncValue.data(profile.withAvatar(url));
  }

  /// Re-runs the fetch, e.g. after the user retries a failed load.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Reads the profile again without showing it: the photo's link has
  /// expired (#118; every file link lives one hour). What is on screen stays
  /// while it is read; only a new profile replaces it, and a failure (no
  /// signal) changes nothing — a photo gets no error card.
  ///
  /// Nothing when a load is already on its way, and the answer is dropped
  /// when the profile changed meanwhile (a new photo, a pull to refresh). A
  /// sign-out disposes this notifier, and the next sign-in gets a new one,
  /// so a late answer cannot reach it.
  Future<void> reloadQuietly() async {
    if (_quietReading || state.isLoading) return;
    final before = state;
    _quietReading = true;
    try {
      final result = await ref.read(getMyProfileUseCaseProvider)();
      if (!identical(state, before)) return;
      result.fold((_) {}, (profile) => state = AsyncValue.data(profile));
    } finally {
      _quietReading = false;
    }
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
    AsyncNotifierProvider.autoDispose<ProfileNotifier, EmployeeProfile>(
      ProfileNotifier.new,
    );
