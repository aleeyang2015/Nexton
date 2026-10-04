import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../time_off/domain/entities/local_file.dart';
import '../../../time_off/domain/entities/uploaded_attachment.dart';
import '../../../time_off/presentation/services/attachment_picker.dart';
import '../../../time_off/time_off_providers.dart';

/// Why a picked photo was turned away before upload.
enum OffsitePhotoError { tooLarge }

/// A photo the backend has accepted: the [uploaded] record the request embeds
/// as `attachments`, and the [local] copy the form previews from — the
/// upload's `url` may point at a host the phone can't reach.
class OffsitePhoto extends Equatable {
  final LocalFile local;
  final UploadedAttachment uploaded;

  const OffsitePhoto({required this.local, required this.uploaded});

  @override
  List<Object?> get props => [local, uploaded];
}

/// Holds the off-site scan's photo — the same workflow as the leave and
/// time-correction forms: the file is uploaded (`POST /uploads`) the moment it
/// is picked, and §3's `attachments` object is what comes back.
///
/// The one difference is that this photo is **required** (§3), so the form
/// mirrors the accepted file into its own state and refuses to submit without
/// one. A failed upload surfaces as [AsyncError] while the previous value is
/// kept.
class OffsitePhotoNotifier extends AutoDisposeAsyncNotifier<OffsitePhoto?> {
  /// Images only. A scan outside the geofence is evidenced by a photograph of
  /// where the employee is standing — a PDF would prove nothing.
  static const extensions = ['jpg', 'jpeg', 'png', 'heic', 'webp'];

  /// Largest file the form accepts, in bytes (5 MB).
  static const int maxBytes = 5 * 1024 * 1024;

  @override
  FutureOr<OffsitePhoto?> build() => null;

  /// Opens the gallery/file chooser, then [upload]s the pick. A back-out
  /// changes nothing and returns null.
  Future<OffsitePhotoError?> pickAndUpload() async {
    if (state.isLoading) return null;

    final picked = await ref
        .read(attachmentPickerProvider)
        .pickAttachment(extensions: extensions);
    if (picked == null) return null;

    return upload(picked);
  }

  /// Uploads [picked] — from the camera or the chooser — and keeps it,
  /// replacing any previous one. Returns [OffsitePhotoError.tooLarge] for a
  /// file over [maxBytes], which is never uploaded; null otherwise.
  Future<OffsitePhotoError?> upload(LocalFile picked) async {
    if (state.isLoading) return null;

    if (await File(picked.path).length() > maxBytes) {
      return OffsitePhotoError.tooLarge;
    }

    final previous = state.valueOrNull;
    state = const AsyncValue<OffsitePhoto?>.loading().copyWithPrevious(state);

    final result = await ref.read(uploadAttachmentUseCaseProvider)(picked);

    state = result.fold(
      (failure) => AsyncValue<OffsitePhoto?>.error(
        failure,
        StackTrace.current,
      ).copyWithPrevious(AsyncValue.data(previous)),
      (uploaded) =>
          AsyncValue.data(OffsitePhoto(local: picked, uploaded: uploaded)),
    );
    return null;
  }

  /// Drops the photo locally. Does not delete it server-side — that endpoint
  /// is out of scope here.
  void clear() => state = const AsyncValue.data(null);
}

final offsitePhotoNotifierProvider =
    AsyncNotifierProvider.autoDispose<OffsitePhotoNotifier, OffsitePhoto?>(
      OffsitePhotoNotifier.new,
    );
