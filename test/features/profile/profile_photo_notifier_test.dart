import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/upload/domain/capture_policy.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/profile/data/datasources/profile_photo_error_code.dart';
import 'package:next_on/features/profile/presentation/providers/profile_notifier.dart';
import 'package:next_on/features/profile/presentation/providers/profile_photo_notifier.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/profile_test_doubles.dart';

/// Changing the employee's own photo (#59).
void main() {
  final en = AppLocalizationsEn();
  late FakeProfileRepository profiles;
  late ProviderContainer container;

  const photo = LocalFile(path: '/tmp/me.jpg', name: 'me.jpg');

  Future<void> start() async {
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(profiles)],
    );
    addTearDown(container.dispose);
    container.listen(profileNotifierProvider, (_, _) {});
    container.listen(profilePhotoNotifierProvider, (_, _) {});
    await container.read(profileNotifierProvider.future);
  }

  ProfilePhotoNotifier notifier() =>
      container.read(profilePhotoNotifierProvider.notifier);
  ProfilePhotoState state() => container.read(profilePhotoNotifierProvider);

  setUp(() => profiles = FakeProfileRepository());

  test('a photo taken: sent for the profile\'s own id; the profile shows the '
      'new photo at once, with no new request', () async {
    await start();

    await notifier().accept(const Captured(photo));

    expect(profiles.photoUploads.single.employeeId, 'emp-1');
    expect(profiles.photoUploads.single.file, photo);
    expect(state().status, ProfilePhotoStatus.done);
    expect(
      container.read(profileNotifierProvider).requireValue.avatarUrl,
      'https://files.nexton.work/photos/new.jpg',
    );
    expect(profiles.calls, 1);
  });

  test('a second photo while one is on its way is ignored', () async {
    await start();
    profiles.holdPhoto = Completer<void>();

    final first = notifier().accept(const Captured(photo));
    await pumpEventQueue();
    expect(state().uploading, isTrue);
    await notifier().accept(const Captured(photo));
    profiles.holdPhoto!.complete();
    await first;

    expect(profiles.photoUploads, hasLength(1));
  });

  test('a back-out changes nothing', () async {
    await start();
    await notifier().accept(const CaptureCancelled());
    expect(profiles.photoUploads, isEmpty);
    expect(state(), const ProfilePhotoState());
  });

  test('no profile loaded (no employee id): nothing is sent', () async {
    profiles.profile = const Result.failure(
      Failure.server(message: 'down', statusCode: 500),
    );
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(profiles)],
    );
    addTearDown(container.dispose);
    container.listen(profileNotifierProvider, (_, _) {});
    container.listen(profilePhotoNotifierProvider, (_, _) {});
    await pumpEventQueue();

    await notifier().accept(const Captured(photo));
    expect(profiles.photoUploads, isEmpty);
  });

  group('each refusal says its own words; the old photo stays', () {
    for (final (label, failure, words) in <(String, Failure, String)>[
      (
        'not an image (400 INVALID_REQUEST)',
        const Failure.validation(message: ProfilePhotoErrorCode.tokenNotImage),
        en.profilePhotoNotImage,
      ),
      (
        'too large (on the phone, or 413)',
        const Failure.validation(message: ProfilePhotoErrorCode.tokenTooLarge),
        en.profilePhotoTooLarge,
      ),
      (
        'no staff record (EMPLOYEE_NOT_FOUND)',
        const Failure.validation(
          message: 'employee not found',
          code: 'EMPLOYEE_NOT_FOUND',
        ),
        en.ruleEmployeeNotFound,
      ),
      (
        '503 STORAGE_UNAVAILABLE',
        const Failure.server(
          message: 'storage',
          statusCode: 503,
          errorCode: 'STORAGE_UNAVAILABLE',
        ),
        en.serverError,
      ),
      (
        '403 FORBIDDEN',
        const Failure.validation(message: 'forbidden', code: 'FORBIDDEN'),
        en.accessForbidden,
      ),
      (
        'a plain 500',
        const Failure.server(message: 'boom', statusCode: 500),
        en.serverError,
      ),
      (
        'no signal',
        const Failure.network(
          message: 'No internet connection',
          errorCode: ApiErrorCodes.noInternet,
        ),
        en.noInternetConnection,
      ),
    ]) {
      test(label, () async {
        await start();
        final before = container.read(profileNotifierProvider).requireValue;
        profiles.photoResult = Result.failure(failure);

        await notifier().accept(const Captured(photo));

        expect(state().status, ProfilePhotoStatus.failed);
        expect(state().failure!.localize(en), words);
        expect(container.read(profileNotifierProvider).requireValue, before);
      });
    }
  });

  test(
    'a pull to refresh during the upload does not lose the new photo',
    () async {
      await start();
      profiles.holdPhoto = Completer<void>();
      final upload = notifier().accept(const Captured(photo));
      await pumpEventQueue();
      // The refresh answers with the record as it was, before the change.
      profiles.hold = Completer<void>();
      final refresh = container
          .read(profileNotifierProvider.notifier)
          .refresh();
      profiles.holdPhoto!.complete();
      await pumpEventQueue();
      profiles.hold!.complete();
      await refresh;
      await upload;

      expect(
        container.read(profileNotifierProvider).requireValue.avatarUrl,
        'https://files.nexton.work/photos/new.jpg',
      );
    },
  );

  test('the page left mid-upload: the profile (the home header) still shows '
      'the new photo, and the change is not dropped', () async {
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(profiles)],
    );
    addTearDown(container.dispose);
    container.listen(profileNotifierProvider, (_, _) {});
    await container.read(profileNotifierProvider.future);
    final page = container.listen(profilePhotoNotifierProvider, (_, _) {});
    profiles.holdPhoto = Completer<void>();

    final upload = container
        .read(profilePhotoNotifierProvider.notifier)
        .accept(const Captured(photo));
    await pumpEventQueue();
    page.close();
    await pumpEventQueue();
    // Back on the page meanwhile: still uploading, no second upload.
    expect(container.read(profilePhotoNotifierProvider).uploading, isTrue);

    profiles.holdPhoto!.complete();
    await upload;
    expect(
      container.read(profileNotifierProvider).requireValue.avatarUrl,
      'https://files.nexton.work/photos/new.jpg',
    );
  });

  test('two failures in a row are both said', () async {
    await start();
    var said = 0;
    container.listen(profilePhotoNotifierProvider, (_, next) {
      if (next.status == ProfilePhotoStatus.failed) said++;
    });
    await notifier().accept(const CaptureFailed());
    await notifier().accept(const CaptureFailed());
    expect(said, 2);
  });

  test('the phone refused the camera or the photos: said so', () async {
    await start();
    await notifier().accept(const CaptureDenied());
    expect(state().failure!.localize(en), en.uploadPermissionDenied);
  });

  test('the picker failed: "choose another"', () async {
    await start();
    await notifier().accept(const CaptureFailed());
    expect(state().failure!.localize(en), en.profilePhotoNotImage);
    expect(profiles.photoUploads, isEmpty);
  });
}
