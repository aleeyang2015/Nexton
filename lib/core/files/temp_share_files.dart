import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Where a downloaded file lives while its page is open, and how it is
/// shared. Shared by the payslip PDF and the leave files.
///
/// Each open gets its own folder under `<temp>/<folderName>/`, holding one
/// file under the server's name, so the share sheet offers that name. The
/// page deletes the folder when it closes. Folders left by an App that was
/// killed while the page was open are cleared the next time a file is
/// opened, and so are the copies Android's share sheet keeps of a shared
/// file whose name starts with [sharedCopyPrefix] (`share_plus` copies a
/// shared file into `<cache>/share_plus/` and only empties it at its next
/// share). They are not cleared when the page closes: the App the user
/// shared to may still be reading the copy.
///
/// A seam for the tests: the plugins need a platform.
class TempShareFiles {
  final Future<Directory> Function() _tempDir;

  /// The folder under the temp folder these files live in.
  final String folderName;

  /// The name given to a file whose own name has nothing usable left.
  final String fallbackName;

  /// When set (`pdf`), every name ends in it; otherwise a name keeps its
  /// own extension.
  final String? forcedExtension;

  /// Android's shared copies starting with this are cleared at the next
  /// open; null leaves that folder alone.
  final String? sharedCopyPrefix;

  TempShareFiles({
    required this.folderName,
    required this.fallbackName,
    this.forcedExtension,
    this.sharedCopyPrefix,
    Future<Directory> Function()? tempDir,
  }) : _tempDir = tempDir ?? getTemporaryDirectory;

  /// The folders of files open now, in this run of the App. Anything else in
  /// [folderName] is left over and is cleared.
  final Set<String> _open = {};
  int _count = 0;

  /// Writes [bytes] under [fileName] to a folder of its own and returns the
  /// file's path.
  Future<String> writeBytes(Uint8List bytes, String fileName) async {
    final temp = (await _tempDir()).path;
    final root = Directory(_join(temp, folderName));
    final folder = Directory(
      _join(root.path, '${DateTime.now().microsecondsSinceEpoch}-${_count++}'),
    );
    // Claimed before any await, so a clean-up running at the same time
    // never takes it for a leftover.
    _open.add(folder.path);

    try {
      await _clearLeftovers(root);
      final prefix = sharedCopyPrefix;
      if (prefix != null) {
        await _clearSharedCopies(Directory(_join(temp, 'share_plus')), prefix);
      }
      await folder.create(recursive: true);
      final file = File(
        _join(
          folder.path,
          safeName(
            fileName,
            fallback: fallbackName,
            forcedExtension: forcedExtension,
          ),
        ),
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      // Nothing half-written stays behind: the caller never gets this path
      // to delete.
      _open.remove(folder.path);
      try {
        if (await folder.exists()) await folder.delete(recursive: true);
      } on FileSystemException {
        // Already gone.
      }
      rethrow;
    }
  }

  /// Deletes the file at [path] and its folder. Nothing happens when they
  /// are already gone.
  Future<void> delete(String path) async {
    final folder = File(path).parent;
    _open.remove(folder.path);
    try {
      if (await folder.exists()) await folder.delete(recursive: true);
    } on FileSystemException {
      // Already gone, or the OS cleared its temp folder: nothing to keep.
    }
  }

  /// Opens the phone's share sheet with the file at [path]. [origin] is
  /// where the sheet points from on an iPad.
  Future<void> share(String path, {String? mimeType, Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _clearLeftovers(Directory root) async {
    if (!await root.exists()) return;
    await for (final entry in root.list()) {
      if (_open.contains(entry.path)) continue;
      try {
        await entry.delete(recursive: true);
      } on FileSystemException {
        // A leftover the OS is clearing at the same time: fine either way.
      }
    }
  }

  /// Android's copies of files shared from here; anything else in that
  /// folder belongs to another feature's share and is left alone.
  Future<void> _clearSharedCopies(Directory shared, String prefix) async {
    if (!await shared.exists()) return;
    final extension = forcedExtension;
    await for (final entry in shared.list()) {
      final name = entry.path.split(Platform.pathSeparator).last;
      if (entry is! File || !name.startsWith(prefix)) continue;
      if (extension != null && !name.toLowerCase().endsWith('.$extension')) {
        continue;
      }
      try {
        await entry.delete();
      } on FileSystemException {
        // Gone already.
      }
    }
  }

  static String _join(String folder, String name) =>
      '$folder${Platform.pathSeparator}$name';

  /// [name] as a plain file name: no folders, nothing but letters, digits,
  /// `-`, `_` and `.`, at most [_maxNameLength] characters before its
  /// extension. With [forcedExtension] it ends in that; otherwise it keeps
  /// its own (when it has a short plain one). A name from a server must not
  /// write outside the folder (`../../x`) or be longer than the phone
  /// allows.
  static String safeName(
    String name, {
    required String fallback,
    String? forcedExtension,
  }) {
    var base = name.replaceAll('\\', '/').split('/').last;
    base = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    base = base.replaceAll(RegExp(r'^\.+'), '');
    String? extension = forcedExtension;
    if (extension != null) {
      if (base.toLowerCase().endsWith('.$extension')) {
        base = base.substring(0, base.length - extension.length - 1);
      }
    } else {
      final match = RegExp(r'\.([A-Za-z0-9]{1,5})$').firstMatch(base);
      if (match != null) {
        extension = match[1]!.toLowerCase();
        base = base.substring(0, match.start);
      }
    }
    if (base.length > _maxNameLength) base = base.substring(0, _maxNameLength);
    if (base.isEmpty) base = fallback;
    return extension == null ? base : '$base.$extension';
  }

  static const _maxNameLength = 100;
}
