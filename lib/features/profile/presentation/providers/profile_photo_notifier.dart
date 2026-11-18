import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/upload/domain/capture_policy.dart';
import '../../../../core/upload/domain/local_file.dart';
import '../../../../core/upload/domain/upload_error_code.dart';
import '../../domain/profile_photo_error.dart';
import '../../profile_providers.dart';
import 'profile_notifier.dart';

/// Where a photo change stands (#59).
enum ProfilePhotoStatus { idle, uploading, done, failed }

class ProfilePhotoState extends Equatable {
  final ProfilePhotoStatus status;

  /// Why the last change failed; the old photo stays.
  final Failure? failure;

  /// Which change this is: two failures in a row are two states, so each
  /// is said.
  final int attempt;

  const ProfilePhotoState({
    this.status = ProfilePhotoStatus.idle,
    this.failure,
    this.attempt = 0,
  });

  bool get uploading => status == ProfilePhotoStatus.uploading;

  @override
  List<Object?> get props => [status, failure, attempt];
}

/// Changes the employee's own photo (#59): idle → uploading → done or
/// failed. One at a time: a second photo while one is on its way is
/// ignored. On success the profile (and so the home header) shows the new
/// photo at once. AutoDispose: it lives with the profile page.
class ProfilePhotoNotifier extends AutoDisposeNotifier<ProfilePhotoState> {
  bool _disposed = false;

  @override
  ProfilePhotoState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const ProfilePhotoState();
  }

  /// What came back from the source sheet. A back-out changes nothing.
  Future<void> accept(CaptureResult result) async {
    switch (result) {
      case Captured(:final file):
        await _upload(file);
      case CaptureFailed():
        if (state.uploading) return;
        state = ProfilePhotoState(
          status: ProfilePhotoStatus.failed,
          failure: const Failure.validation(
            message: ProfilePhotoError.tokenNotImage,
          ),
          attempt: state.attempt + 1,
        );
      case CaptureDenied():
        if (state.uploading) return;
        state = ProfilePhotoState(
          status: ProfilePhotoStatus.failed,
          failure: const Failure.validation(
            message: UploadErrorCode.tokenPermissionDenied,
          ),
          attempt: state.attempt + 1,
        );
      case CaptureCancelled():
        break;
    }
  }

  Future<void> _upload(LocalFile file) async {
    if (state.uploading) return;
    final employeeId = ref.read(profileNotifierProvider).valueOrNull?.id;
    if (employeeId == null || employeeId.isEmpty) return;

    final attempt = state.attempt + 1;
    state = ProfilePhotoState(
      status: ProfilePhotoStatus.uploading,
      attempt: attempt,
    );
    // Alive until the answer is in: a page left (or the avatar scrolled
    // away) mid-upload comes back to the spinner and an off pencil, not to
    // a second upload, and the outcome is still said.
    final alive = ref.keepAlive();
    // Taken now: the page (and this notifier) may be gone when the answer
    // comes, while the profile, which the home header shows, lives on.
    final profile = ref.read(profileNotifierProvider.notifier);
    final result = await ref.read(uploadMyPhotoUseCaseProvider)((
      employeeId: employeeId,
      file: file,
    ));

    final url = result.dataOrNull;
    if (url != null) {
      // The server has the new photo: show it, even if this page was left.
      try {
        await profile.showPhoto(url);
      } catch (_) {
        // The profile itself is gone (signed out): nothing to show.
      }
    }
    alive.close();
    if (_disposed) return;
    state = result.fold(
      (failure) => ProfilePhotoState(
        status: ProfilePhotoStatus.failed,
        failure: failure,
        attempt: attempt,
      ),
      (_) =>
          ProfilePhotoState(status: ProfilePhotoStatus.done, attempt: attempt),
    );
  }
}

final profilePhotoNotifierProvider =
    NotifierProvider.autoDispose<ProfilePhotoNotifier, ProfilePhotoState>(
      ProfilePhotoNotifier.new,
    );
