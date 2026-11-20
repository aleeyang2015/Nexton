import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../upload/presentation/file_link_image.dart';

/// Shows the photo at [url] full screen, pinch-zoomable; a tap anywhere
/// closes it. Shared by the "forgot to scan" and off-site pages and the
/// leave files.
///
/// A link past its hour (#73) says so, and [onExpired] is told once: a
/// page that owns the request reads it again, so the next tap opens the new
/// link. Lists pass nothing: a pull to refresh gives new links.
void showImageViewer(
  BuildContext context,
  String url, {
  String? errorText,
  VoidCallback? onExpired,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: InteractiveViewer(
        child: Center(
          child: _ViewerImage(
            url: url,
            errorText: errorText,
            onExpired: onExpired,
          ),
        ),
      ),
    ),
  );
}

class _ViewerImage extends ConsumerWidget {
  const _ViewerImage({required this.url, this.errorText, this.onExpired});

  final String url;
  final String? errorText;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Image(
    image: ref.watch(fileLinkImageProvider)(url),
    // A photo the phone cannot draw (HEIC on some Androids, a broken file)
    // says so when the caller gave the words; an expired link always does.
    errorBuilder: (context, error, _) {
      final expired = isExpiredFileLink(error);
      if (expired) reportExpiredOnce(url, onExpired);
      final text = expired
          ? AppLocalizations.of(context)!.fileLinkExpired
          : errorText;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: Colors.white,
            size: 48,
          ),
          if (text != null) ...[
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ],
      );
    },
  );
}
