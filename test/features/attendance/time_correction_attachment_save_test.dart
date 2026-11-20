import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_detail_notifier.dart';
import 'package:next_on/features/attendance/presentation/services/attachment_file_saver.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/correction_approval_test_doubles.dart';

class _Saver extends AttachmentFileSaver {
  const _Saver();

  @override
  Future<String?> save(Uint8List bytes, {required String fileName}) async =>
      '/phone/$fileName';
}

/// Saving a "forgot to scan" file whose link is past its hour (#73).
void main() {
  const oldUrl = 'https://api.nexton.work/files/old.jpg?exp=1&sig=a';
  const newUrl = 'https://api.nexton.work/files/new.jpg?exp=2&sig=b';
  const expired = Result<Uint8List>.failure(
    Failure.validation(message: 'expired', code: 'LINK_EXPIRED'),
  );
  late FakeAttendanceRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAttendanceRepository()
      ..timeCorrectionDetailResults = [
        Result.success(correctionForApproval(attachmentUrl: oldUrl)),
        Result.success(correctionForApproval(attachmentUrl: newUrl)),
      ];
    container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(repository),
        attachmentFileSaverProvider.overrideWithValue(const _Saver()),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<TimeCorrectionDetailNotifier> loaded() async {
    container.listen(timeCorrectionDetailNotifierProvider('tc-1'), (_, _) {});
    await pumpEventQueue();
    return container.read(
      timeCorrectionDetailNotifierProvider('tc-1').notifier,
    );
  }

  test('expired: the request is read again, and the file saved from the new '
      'link', () async {
    repository.timeCorrectionAttachmentAnswer = (url) =>
        url == oldUrl ? expired : Result.success(Uint8List.fromList([1, 2]));
    final notifier = await loaded();

    expect(await notifier.saveAttachment(), AttachmentSaveOutcome.saved);
    expect(repository.timeCorrectionAttachmentUrls, [oldUrl, newUrl]);
    expect(repository.timeCorrectionDetailCalls, ['tc-1', 'tc-1']);
  });

  test('the new link refused too: failed, and no third try', () async {
    repository.timeCorrectionAttachmentAnswer = (_) => expired;
    final notifier = await loaded();

    expect(await notifier.saveAttachment(), AttachmentSaveOutcome.failed);
    expect(repository.timeCorrectionAttachmentUrls, [oldUrl, newUrl]);
  });

  test('another failure (no signal): failed, no reload', () async {
    repository.timeCorrectionAttachmentResult = const Result.failure(
      Failure.network(message: 'offline'),
    );
    final notifier = await loaded();

    expect(await notifier.saveAttachment(), AttachmentSaveOutcome.failed);
    expect(repository.timeCorrectionDetailCalls, ['tc-1']);
  });
}
