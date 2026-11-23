import 'package:flutter/material.dart';

import '../upload/presentation/file_link_image.dart';

/// Circular profile photo for [url], falling back to a plain person icon
/// while there is no photo yet, or the image fails to load.
///
/// The photo is a file link that lives one hour (#118): when it has
/// expired, [onExpired] is told (once), so the profile can be read again
/// and the photo comes back with a new link.
Widget appAvatar({
  required String? url,
  required double size,
  VoidCallback? onExpired,
}) {
  if (url == null || url.isEmpty) return _avatarFallback(size);

  return ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: FileLinkImage(
        url: url,
        fallback: _avatarFallback(size),
        onExpired: onExpired,
      ),
    ),
  );
}

Widget _avatarFallback(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0xffeef3fe),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.person, size: size * 0.55, color: Color(0xff8598f8)),
  );
}
