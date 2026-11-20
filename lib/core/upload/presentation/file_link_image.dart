import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors/failure.dart';

/// Makes the image for a file link: a seam, so a test can have one fail as
/// a link past its hour does.
final fileLinkImageProvider = Provider<ImageProvider Function(String url)>(
  (ref) => NetworkImage.new,
);

/// The server's code for a file link opened after its hour.
const String linkExpiredCode = 'LINK_EXPIRED';

/// True when [error] says a file link from `POST /uploads` has expired: it
/// lives one hour from the read that gave it, then answers `403`
/// `LINK_EXPIRED` (#73). An image cannot read the body, so any 403 on one
/// counts; a download reads the code.
bool isExpiredFileLink(Object? error) {
  if (error is NetworkImageLoadException) return error.statusCode == 403;
  return error is ValidationFailure && error.code == linkExpiredCode;
}

final Set<String> _reported = {};

/// Tells [onExpired] that [url] has expired, after the frame (it is found
/// while a widget builds), and at most once for that url. Reading the
/// request again gives new links, which may expire in their turn; the same
/// expired link never asks twice, so a link the server keeps refusing
/// cannot make the page reload over and over.
void reportExpiredOnce(String url, VoidCallback? onExpired) {
  if (onExpired == null || !_reported.add(url)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) => onExpired());
}

/// Forgets which links were reported, between tests.
@visibleForTesting
void resetExpiredLinkReports() => _reported.clear();

/// A photo at a file link. Shows [fallback] when it cannot be drawn; when
/// the link has expired, also calls [onExpired] (once), so a page that owns
/// the request can read it again and the photo comes back with a new link.
class FileLinkImage extends ConsumerWidget {
  const FileLinkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.onExpired,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Image(
    // A new link starts afresh: an Image keeps its last error until the new
    // one loads, and that error is the old link's.
    key: ValueKey(url),
    image: ref.watch(fileLinkImageProvider)(url),
    fit: fit,
    errorBuilder: (_, error, _) {
      if (isExpiredFileLink(error)) reportExpiredOnce(url, onExpired);
      return fallback;
    },
  );
}
