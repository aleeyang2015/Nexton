import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/core/widgets/image_viewer.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// #39's refusals and texts.
void main() {
  test('LEAVE_ATTACHMENT_REQUIRED (after Nexton-Backend#192) says "attach '
      'a file", in Lao too', () {
    final token = LeaveErrorCode.tokenByWire[LeaveErrorCode.attachmentRequired];
    expect(token, isNotNull);

    final failure = Failure.validation(message: token!);
    expect(
      failure.localize(AppLocalizationsLo()),
      AppLocalizationsLo().leaveRequiresAttachmentBlocked,
    );
    expect(
      failure.localize(AppLocalizationsEn()),
      'This type needs a file; attach one before sending',
    );
    expect(LeaveErrorCode.tokenOf(failure), token);
  });

  testWidgets('a photo that cannot be drawn says so, not just a broken icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showImageViewer(
              context,
              'https://files.nexton.work/broken.heic',
              errorText: "This file can't be opened",
            ),
            child: const Text('OPEN'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    // The test's HTTP answers 400: the image fails to load.
    await tester.pumpAndSettle();

    expect(find.text("This file can't be opened"), findsOneWidget);
  });
}
