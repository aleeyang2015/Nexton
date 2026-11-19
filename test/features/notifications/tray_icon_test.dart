import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/notifications/data/datasources/push_constants.dart';

/// The tray icon for pushes (#51): the Nexton mark, white on transparent,
/// one PNG per screen density. Android draws a status-bar icon from its
/// alpha only, so a colour icon shows as a white square.
void main() {
  const res = 'android/app/src/main/res';
  const name = 'ic_stat_nexton';

  /// Density folder → the pixels of a 24dp icon there.
  const sizes = {
    'mdpi': 24,
    'hdpi': 36,
    'xhdpi': 48,
    'xxhdpi': 72,
    'xxxhdpi': 96,
  };

  test('the App and the manifest name this icon', () {
    expect(PushConstants.androidSmallIcon, '@drawable/$name');
    expect(
      File('$res/../AndroidManifest.xml').readAsStringSync(),
      contains('android:resource="@drawable/$name"'),
    );
  });

  test('there is one PNG per density, of the right size, with '
      'transparency', () {
    for (final MapEntry(key: density, value: px) in sizes.entries) {
      final file = File('$res/drawable-$density/$name.png');
      expect(file.existsSync(), isTrue, reason: '$density is missing');

      // A PNG's header: width and height at bytes 16 to 23, then the bit
      // depth and the colour type (6 = colour with alpha).
      final bytes = file.readAsBytesSync();
      int at(int offset) =>
          bytes.buffer.asByteData().getUint32(offset, Endian.big);
      expect(at(16), px, reason: '$density width');
      expect(at(20), px, reason: '$density height');
      expect(bytes[25], 6, reason: '$density has no alpha channel');
    }
  });

  test('the placeholder drawing is gone, so no density falls back to it', () {
    expect(File('$res/drawable/$name.xml').existsSync(), isFalse);
  });
}
