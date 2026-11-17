import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/files/temp_share_files.dart';
import 'package:next_on/core/widgets/pdf_file_view.dart';
import 'package:next_on/features/time_off/data/datasources/leave_file_downloader.dart';
import 'package:next_on/features/time_off/domain/entities/leave_attachment.dart';
import 'package:next_on/features/time_off/presentation/pages/leave_file_page.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_file_notifier.dart';
import 'package:next_on/features/time_off/presentation/widgets/attachment_opener.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

class _StubAdapter implements HttpClientAdapter {
  RequestOptions? last;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    last = options;
    return ResponseBody.fromBytes(
      utf8.encode('%PDF-1.4 hello'),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/pdf'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Temp files in memory.
class _Files extends TempShareFiles {
  _Files() : super(folderName: 'leave-files', fallbackName: 'file');

  final List<String> written = [];
  final List<String> deleted = [];
  final List<({String path, String? mimeType})> shared = [];

  @override
  Future<String> writeBytes(Uint8List bytes, String fileName) async {
    final path = '/tmp/leave-files/${written.length}/$fileName';
    written.add(path);
    return path;
  }

  @override
  Future<void> delete(String path) async => deleted.add(path);

  @override
  Future<void> share(String path, {String? mimeType, Rect? origin}) async =>
      shared.add((path: path, mimeType: mimeType));
}

/// A leave file opens where it can be read (#39).
void main() {
  late _StubAdapter adapter;
  late _Files files;

  const photo = LeaveAttachment(
    fileName: 'uploads/cert.jpg',
    originalName: 'cert.jpg',
    url: 'https://files.nexton.work/uploads/cert.jpg',
    contentType: 'image/jpeg',
  );
  const pdf = LeaveAttachment(
    fileName: 'uploads/medical.pdf',
    originalName: 'medical.pdf',
    url: 'https://files.nexton.work/uploads/medical.pdf',
    contentType: 'application/pdf',
  );
  const word = LeaveAttachment(
    fileName: 'uploads/note.docx',
    originalName: 'note.docx',
    url: 'https://files.nexton.work/uploads/note.docx',
    contentType:
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  );
  const noUrl = LeaveAttachment(fileName: 'uploads/old.pdf');

  setUp(() {
    adapter = _StubAdapter();
    files = _Files();
  });

  Future<void> pumpTile(WidgetTester tester, LeaveAttachment file) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaveFileDownloaderProvider.overrideWithValue(
            LeaveFileDownloader(dio: Dio()..httpClientAdapter = adapter),
          ),
          leaveFilesProvider.overrideWithValue(files),
          pdfFileViewProvider.overrideWithValue(
            (path, _) => Text('PDF $path'),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: LeaveFileTile(file: file)),
        ),
      ),
    );
  }

  test('the download sends no Bearer header (a plain storage link)',
      () async {
    final downloader = LeaveFileDownloader(
      dio: Dio()..httpClientAdapter = adapter,
    );

    final result = await downloader.download(pdf.url!);

    expect(result.isSuccess, isTrue);
    expect(adapter.last!.uri.toString(), pdf.url);
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
    expect(adapter.last!.headers.containsKey('authorization'), isFalse);
  });

  testWidgets('a photo opens full screen, pinch to zoom; nothing downloaded',
      (tester) async {
    await pumpTile(tester, photo);

    await tester.tap(find.text('cert.jpg'));
    await tester.pump();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(adapter.calls, 0);
  });

  testWidgets('a PDF opens in the App\'s viewer, with Share', (tester) async {
    await pumpTile(tester, pdf);

    await tester.tap(find.text('medical.pdf'));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveFilePage), findsOneWidget);
    expect(find.text('PDF /tmp/leave-files/0/medical.pdf'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();
    expect(files.shared.single.mimeType, 'application/pdf');
  });

  testWidgets('a Word file opens on a page with Share, not the PDF viewer',
      (tester) async {
    await pumpTile(tester, word);

    await tester.tap(find.text('note.docx'));
    await tester.pumpAndSettle();

    expect(find.textContaining('PDF '), findsNothing);
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();
    expect(files.shared.single.path, '/tmp/leave-files/0/note.docx');
  });

  testWidgets('closing the page deletes the downloaded copy', (tester) async {
    await pumpTile(tester, pdf);
    await tester.tap(find.text('medical.pdf'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(files.deleted, ['/tmp/leave-files/0/medical.pdf']);
  });

  testWidgets('a file with no url is plain text: nothing to tap',
      (tester) async {
    await pumpTile(tester, noUrl);

    expect(find.byType(InkWell), findsNothing);
    expect(find.text('uploads/old.pdf'), findsOneWidget);
  });
}
