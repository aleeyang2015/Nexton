import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expired_file_link.dart';

/// Makes the image for a file link: a seam, so a test can have one fail as
/// a link past its hour does.
final fileLinkImageProvider = Provider<ImageProvider Function(String url)>(
  (ref) => NetworkImage.new,
);

/// True when [error] says a file link from `POST /uploads` has expired: it
/// lives one hour from the read that gave it, then answers `403`
/// `LINK_EXPIRED` (#73). An image cannot read the body, so any 403 on one
/// counts; a download reads the code ([isExpiredDownload]).
bool isExpiredFileLink(Object? error) {
  if (error is NetworkImageLoadException) return error.statusCode == 403;
  return isExpiredDownload(error);
}

/// How long one file waits before its request may be read again for it.
const Duration expiredLinkCooldown = Duration(seconds: 30);

/// When each file last asked for its request to be read again, by its link
/// without the signature (`?exp=…&sig=…` is new on every read).
final Map<String, DateTime> _lastAsked = {};

/// The clock the cooldown reads; a test sets its own.
@visibleForTesting
DateTime Function() expiredLinkClock = DateTime.now;

bool _mayAsk(String url) {
  final file = Uri.tryParse(url)?.replace(query: '').toString() ?? url;
  final now = expiredLinkClock();
  final last = _lastAsked[file];
  if (last != null && now.difference(last) < expiredLinkCooldown) {
    return false;
  }
  _lastAsked[file] = now;
  return true;
}

/// Tells [onExpired] that [url] has expired, after the frame (it is found
/// while a widget builds). At most once per [expiredLinkCooldown] for the
/// same file, whatever its signature: a fresh link refused again (a 403 for
/// another reason) cannot make the page reload over and over, and a reload
/// that failed (no signal) is tried again once the time has passed.
void reportExpiredOnce(String url, VoidCallback? onExpired) {
  if (onExpired == null || !_mayAsk(url)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) => onExpired());
}

/// [reportExpiredOnce] without waiting for a frame, for tests.
@visibleForTesting
void reportExpiredNow(String url, VoidCallback onExpired) {
  if (_mayAsk(url)) onExpired();
}

/// Forgets which files asked, between tests.
@visibleForTesting
void resetExpiredLinkReports() => _lastAsked.clear();

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
