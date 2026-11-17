import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/upload/domain/local_file.dart';
import '../../../../core/upload/domain/uploaded_attachment.dart';
import '../../../../core/upload/domain/upload_rules.dart';
import '../../../../core/upload/upload_providers.dart';

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
  /// Largest file the form accepts, in bytes: the shared limit.
  static const int maxBytes = UploadRules.maxBytes;

  @override
  FutureOr<OffsitePhoto?> build() => null;

  /// Uploads [picked] — from the camera only (owner's decision 23: off-site
  /// proof is taken there and then) — and keeps it,
  /// replacing any previous one. Returns [OffsitePhotoError.tooLarge] for a
  /// file over [maxBytes], which is never uploaded; null otherwise.
  Future<OffsitePhotoError?> upload(LocalFile picked) async {
    if (state.isLoading) return null;

    // A file that cannot be read here is left to the upload, which says
    // "choose it again".
    final size = await File(picked.path).length().catchError((_) => 0);
    if (size > maxBytes) {
      return OffsitePhotoError.tooLarge;
    }

    final previous = state.valueOrNull;
    state = const AsyncValue<OffsitePhoto?>.loading().copyWithPrevious(state);

    final result = await ref.read(uploadAttachmentUseCaseProvider)((
      file: picked,
      folder: UploadFolder.offsite,
    ));

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
