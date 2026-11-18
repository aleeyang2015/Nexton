import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/upload/domain/capture_policy.dart';
import '../../../../core/upload/domain/local_file.dart';
import '../../data/datasources/profile_photo_error_code.dart';
import '../../profile_providers.dart';
import 'profile_notifier.dart';

/// Where a photo change stands (#59).
enum ProfilePhotoStatus { idle, uploading, done, failed }

class ProfilePhotoState extends Equatable {
  final ProfilePhotoStatus status;

  /// Why the last change failed; the old photo stays.
  final Failure? failure;

  const ProfilePhotoState({
    this.status = ProfilePhotoStatus.idle,
    this.failure,
  });

  bool get uploading => status == ProfilePhotoStatus.uploading;

  @override
  List<Object?> get props => [status, failure];
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
      case CaptureFailed() || CaptureDenied():
        if (state.uploading) return;
        state = const ProfilePhotoState(
          status: ProfilePhotoStatus.failed,
          failure: Failure.validation(
            message: ProfilePhotoErrorCode.tokenNotImage,
          ),
        );
      case CaptureCancelled():
        break;
    }
  }

  Future<void> _upload(LocalFile file) async {
    if (state.uploading) return;
    final employeeId = ref.read(profileNotifierProvider).valueOrNull?.id;
    if (employeeId == null || employeeId.isEmpty) return;

    state = const ProfilePhotoState(status: ProfilePhotoStatus.uploading);
    final result = await ref.read(uploadMyPhotoUseCaseProvider)((
      employeeId: employeeId,
      file: file,
    ));
    if (_disposed) return;

    result.when(
      success: (url) {
        ref.read(profileNotifierProvider.notifier).showPhoto(url);
        state = const ProfilePhotoState(status: ProfilePhotoStatus.done);
      },
      failure: (failure) => state = ProfilePhotoState(
        status: ProfilePhotoStatus.failed,
        failure: failure,
      ),
    );
  }
}

final profilePhotoNotifierProvider =
    NotifierProvider.autoDispose<ProfilePhotoNotifier, ProfilePhotoState>(
      ProfilePhotoNotifier.new,
    );
