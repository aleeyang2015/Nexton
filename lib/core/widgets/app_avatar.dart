import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular profile photo for [url], falling back to a plain person icon
/// while there is no photo yet, or the image fails to load.
Widget appAvatar({required String? url, required double size}) {
  if (url == null || url.isEmpty) return _avatarFallback(size);

  return ClipOval(
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _avatarFallback(size),
    ),
  );
}

Widget _avatarFallback(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.gray200,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.person, size: size * 0.55, color: AppColors.gray500),
  );
}
