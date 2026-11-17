import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/files/temp_share_files.dart';
import '../../data/datasources/leave_file_downloader.dart';
import '../../domain/entities/leave_attachment.dart';

/// Downloads leave files (no token: see [LeaveFileDownloader]).
final leaveFileDownloaderProvider = Provider<LeaveFileDownloader>(
  (ref) => LeaveFileDownloader(),
);

/// Where an opened leave file lives while it is open: `<temp>/leave-files/`,
/// under its own name. A seam for tests.
final leaveFilesProvider = Provider<TempShareFiles>(
  (ref) => TempShareFiles(folderName: 'leave-files', fallbackName: 'file'),
);

/// One leave file, downloaded and written to a temp file; the value is the
/// file's path. Keyed by the file, and dropped (the file deleted) when no
/// page watches it.
class LeaveFileNotifier
    extends AutoDisposeFamilyAsyncNotifier<String, LeaveAttachment> {
  @override
  Future<String> build(LeaveAttachment arg) async {
    final files = ref.read(leaveFilesProvider);
    var disposed = false;
    String? written;
    ref.onDispose(() {
      disposed = true;
      final path = written;
      if (path != null) files.delete(path);
    });

    final url = arg.url;
    if (url == null) throw StateError('No url to open');
    final result = await ref.read(leaveFileDownloaderProvider).download(url);
    final bytes = result.fold((failure) => throw failure, (bytes) => bytes);

    final path = await files.writeBytes(bytes, arg.displayName);
    if (disposed) {
      await files.delete(path);
    } else {
      written = path;
    }
    return path;
  }

  /// Asks again after a failure. Does nothing while a load is running.
  Future<void> retry() async {
    if (state.isLoading) return;
    ref.invalidateSelf();
    await future.then<void>((_) {}, onError: (_) {});
  }

  bool _sharing = false;

  /// Opens the share sheet with the loaded file. False when there is no
  /// file yet, or the sheet could not be opened.
  Future<bool> share({Rect? origin}) async {
    final path = state.valueOrNull;
    if (path == null || state.isLoading) return false;
    if (_sharing) return true;
    _sharing = true;
    try {
      await ref
          .read(leaveFilesProvider)
          .share(path, mimeType: arg.contentType, origin: origin);
      return true;
    } catch (_) {
      return false;
    } finally {
      _sharing = false;
    }
  }
}

final leaveFileNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<LeaveFileNotifier, String, LeaveAttachment>(LeaveFileNotifier.new);
