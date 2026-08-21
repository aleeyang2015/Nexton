import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// Serves a 1×1 transparent PNG for every asset key, plus an empty asset
/// manifest so `Image.asset` resolves without variant lookup.
///
/// Widget tests don't ship the real asset bundle, and an `Image.asset` that
/// can't resolve reports an exception that fails the test. This keeps the
/// failure surface on the widget under test.
class TestAssetBundle extends CachingAssetBundle {
  static final _pixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(_pixel));

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async {
    // No variants declared — every asset resolves to its own key.
    final empty = const StandardMessageCodec().encodeMessage(
      <String, Object>{},
    )!;
    return parser(empty);
  }
}
