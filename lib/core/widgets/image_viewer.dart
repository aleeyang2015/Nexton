import 'package:flutter/material.dart';

/// Shows the photo at [url] full screen, pinch-zoomable; a tap anywhere
/// closes it. Shared by the "forgot to scan" and off-site pages and the
/// leave files.
void showImageViewer(BuildContext context, String url, {String? errorText}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: InteractiveViewer(
        child: Center(
          child: Image.network(
            url,
            // A photo the phone cannot draw (HEIC on some Androids, a
            // broken file) says so when the caller gave the words.
            errorBuilder: (_, _, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 48,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
