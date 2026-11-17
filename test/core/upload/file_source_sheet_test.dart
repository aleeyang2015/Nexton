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

  test('file_picker errors: a picker already open is a back-out; any other '
      'is "choose it again", never an uncaught error', () {
    expect(
      FilePickerCapture.resultOf(PlatformException(code: 'already_active')),
      isA<CaptureCancelled>(),
    );
    expect(
      FilePickerCapture.resultOf(PlatformException(code: 'multiple_request')),
      isA<CaptureCancelled>(),
    );
    expect(
      FilePickerCapture.resultOf(PlatformException(code: 'unknown_path')),
      isA<CaptureFailed>(),
    );
  });

  testWidgets('a second tap while the sheet is open opens nothing more',
      (tester) async {
    await open(tester, CapturePolicy.document);
    expect(find.text(lo.uploadPickFile), findsOneWidget);

    // A second tap that lands before the sheet covers the button.
    tester.widget<TextButton>(find.byType(TextButton)).onPressed!();
    await tester.pumpAndSettle();

    expect(find.text(lo.uploadPickFile), findsOneWidget);
    expect(result, isA<CaptureCancelled>());
  });
}
