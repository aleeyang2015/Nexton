import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_on/core/upload/presentation/file_link_image.dart';

/// An image whose load fails as a file link does: with [status] (403 once
/// its hour has passed, #73).
class FailingLinkImage extends ImageProvider<FailingLinkImage> {
  FailingLinkImage(this.status, this.url);

  final int status;
  final String url;

  @override
  Future<FailingLinkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    FailingLinkImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(
      NetworkImageLoadException(statusCode: status, uri: Uri.parse(url)),
    ),
  );
}

/// Every file link's image fails with [status] while [failing] says so for
/// its url (all by default).
Override fileLinksFailWith(int status, {bool Function(String url)? failing}) =>
    fileLinkImageProvider.overrideWithValue(
      (url) => (failing?.call(url) ?? true)
          ? FailingLinkImage(status, url)
          : FailingLinkImage(0, url),
    );
