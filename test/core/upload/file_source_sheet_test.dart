import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/upload/domain/capture_policy.dart';
import 'package:next_on/core/upload/presentation/file_capture.dart';
import 'package:next_on/core/upload/presentation/file_source_sheet.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/file_capture_test_doubles.dart';

/// Each policy offers only its sources (decision 23).
void main() {
  final lo = AppLocalizationsLo();
  late FakeFileCapture capture;
  CaptureResult? result;

  setUp(() {
    capture = FakeFileCapture();
    result = null;
  });

  Future<void> open(WidgetTester tester, CapturePolicy policy) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fileCaptureProvider.overrideWithValue(capture)],
        child: MaterialApp(
          locale: const Locale('lo'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async =>
                    result = await FileSourceSheet.pick(context, ref, policy),
                child: const Text('ATTACH'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ATTACH'));
    await tester.pumpAndSettle();
  }

  testWidgets('camera only (off-site): no sheet, the camera at once',
      (tester) async {
    await open(tester, CapturePolicy.cameraOnly);

    expect(find.text(lo.uploadTakePhoto), findsNothing);
    expect(capture.asked, ['camera']);
    expect(result, isA<Captured>());
  });

  testWidgets('photo: camera, gallery and an image file, no PDF',
      (tester) async {
    await open(tester, CapturePolicy.photo);

    expect(find.text(lo.uploadTakePhoto), findsOneWidget);
    expect(find.text(lo.uploadPickPhoto), findsOneWidget);
    expect(find.text(lo.uploadPickFile), findsOneWidget);

    await tester.tap(find.text(lo.uploadPickFile));
    await tester.pumpAndSettle();
    expect(capture.asked, ['file']);
  });

  testWidgets('document (leave): the file may be a PDF', (tester) async {
    await open(tester, CapturePolicy.document);

    await tester.tap(find.text(lo.uploadPickFile));
    await tester.pumpAndSettle();
    expect(capture.asked, ['file(pdf)']);
  });

  testWidgets('each choice opens its source', (tester) async {
    await open(tester, CapturePolicy.photo);
    await tester.tap(find.text(lo.uploadTakePhoto));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ATTACH'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(lo.uploadPickPhoto));
    await tester.pumpAndSettle();

    expect(capture.asked, ['camera', 'gallery']);
  });

  testWidgets('the sheet dismissed: cancelled, nothing opened', (tester) async {
    await open(tester, CapturePolicy.document);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, isA<CaptureCancelled>());
    expect(capture.asked, isEmpty);
  });

  test('a refused permission from file_picker reads as "denied"', () {
    expect(
      FilePickerCapture.isPermissionRefusal(
        PlatformException(code: 'read_external_storage_denied'),
      ),
      isTrue,
    );
    expect(
      FilePickerCapture.isPermissionRefusal(
        PlatformException(code: 'photo_access_denied'),
      ),
      isTrue,
    );
    expect(
      FilePickerCapture.isPermissionRefusal(
        PlatformException(code: 'unknown_path'),
      ),
      isFalse,
    );
  });
}
