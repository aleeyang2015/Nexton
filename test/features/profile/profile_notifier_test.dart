import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/presentation/providers/profile_notifier.dart';
import 'package:next_on/features/profile/profile_providers.dart';

import '../../support/profile_test_doubles.dart';

/// A profile photo's link expires after an hour (#118): the avatar asks for
/// the profile again, quietly — what is on screen stays while it is read,
/// and a failure changes nothing.
void main() {
  const photo = 'https://api.nexton.work/api/v1/files/tenants/demo/p.jpg';
  const oldLink = EmployeeProfile(
    id: 'emp-1',
    fullName: 'Somphone Vilaysone',
    avatarUrl: '$photo?exp=1&sig=old',
  );
  const newLink = EmployeeProfile(
    id: 'emp-1',
    fullName: 'Somphone Vilaysone',
    avatarUrl: '$photo?exp=2&sig=new',
  );

  late FakeProfileRepository profiles;
  late ProviderContainer container;
  late List<AsyncValue<EmployeeProfile>> seen;
  late ProviderSubscription<AsyncValue<EmployeeProfile>> subscription;

  setUp(() async {
    profiles = FakeProfileRepository()..profile = const Result.success(oldLink);
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(profiles)],
    );
    addTearDown(container.dispose);
    seen = [];
    subscription = container.listen(
      profileNotifierProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    await container.read(profileNotifierProvider.future);
    seen.clear();
  });

  ProfileNotifier notifier() =>
      container.read(profileNotifierProvider.notifier);
  AsyncValue<EmployeeProfile> state() =>
      container.read(profileNotifierProvider);

  test(
    'the new link replaces the old one, with no loading in between',
    () async {
      profiles.profile = const Result.success(newLink);

      await notifier().reloadQuietly();

      expect(profiles.calls, 2);
      expect(state().value, newLink);
      expect(seen.where((s) => s.isLoading), isEmpty);
    },
  );

  test(
    'a failed read (no signal) keeps the profile on screen, no error',
    () async {
      profiles.profile = const Result.failure(
        Failure.network(message: 'no signal'),
      );

      await notifier().reloadQuietly();

      expect(profiles.calls, 2);
      expect(state().hasError, isFalse);
      expect(state().value, oldLink);
      expect(seen, isEmpty);
    },
  );

  test('a load already on its way: nothing more is sent', () async {
    profiles.hold = Completer<void>();
    final refresh = notifier().refresh();

    final reload = notifier().reloadQuietly();
    profiles.hold!.complete();
    await Future.wait([refresh, reload]);

    expect(profiles.calls, 2);
  });

  test('two avatars reporting at once: one read', () async {
    profiles
      ..profile = const Result.success(newLink)
      ..hold = Completer<void>();

    final first = notifier().reloadQuietly();
    final second = notifier().reloadQuietly();
    profiles.hold!.complete();
    await Future.wait([first, second]);

    expect(profiles.calls, 2);
    expect(state().value, newLink);
  });

  test('a photo changed while the read was on its way wins over its older '
      'answer', () async {
    profiles.hold = Completer<void>();
    final reload = notifier().reloadQuietly();

    await notifier().showPhoto('$photo?exp=3&sig=uploaded');
    profiles.hold!.complete();
    await reload;

    expect(state().value!.avatarUrl, '$photo?exp=3&sig=uploaded');
  });

  test('signed out while the read was on its way, and another user signed '
      'in: the late answer does not show the last user\'s photo', () async {
    const noy = EmployeeProfile(
      id: 'emp-2',
      fullName: 'Noy Keomany',
      avatarUrl: 'https://api.nexton.work/api/v1/files/tenants/demo/noy.jpg',
    );
    final held = Completer<void>();
    profiles
      ..profile = const Result.success(newLink)
      ..hold = held;
    final reload = notifier().reloadQuietly();

    // Signed out: nothing watches the profile any more, so it is disposed.
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    profiles
      ..hold = null
      ..profile = const Result.success(noy);
    container.listen(profileNotifierProvider, (_, _) {});
    await container.read(profileNotifierProvider.future);

    held.complete();
    await expectLater(reload, completes);
    await Future<void>.delayed(Duration.zero);

    expect(state().value, noy);
  });
}
