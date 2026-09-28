import 'package:flutter/material.dart';

/// Shows the evidence photo at [url] full screen, pinch-zoomable; a tap
/// anywhere closes it. Shared by the detail and approvals pages.
void showTimeCorrectionImage(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: InteractiveViewer(
        child: Center(
          child: Image.network(
            url,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    ),
  );
}
