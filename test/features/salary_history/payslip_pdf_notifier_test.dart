import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/presentation/providers/payslip_pdf_notifier.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_files.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';

import '../../support/salary_test_doubles.dart';

/// The PDF page's state: one request per payslip, a temp file while the
/// page is open, and no file left behind.
void main() {
  late FakeSalaryRepository repository;
  late FakePayslipPdfFiles files;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSalaryRepository()
      ..pdfResult = Result.success(samplePayslipPdf);
    files = FakePayslipPdfFiles();
    container = ProviderContainer(
      overrides: [
        salaryRepositoryProvider.overrideWithValue(repository),
        payslipPdfFilesProvider.overrideWithValue(files),
      ],
    );
    addTearDown(container.dispose);
  });

  final provider = payslipPdfNotifierProvider('p-oct');

  test('loads the PDF and writes it under the server\'s name; the value is '
      'the file\'s path', () async {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);

    final path = await container.read(provider.future);

    expect(repository.pdfIds, ['p-oct']);
    expect(files.writes.single.fileName, 'payslip-EMP-002-2026-10.pdf');
    expect(path, '/tmp/payslips/1/payslip-EMP-002-2026-10.pdf');
  });

  test('two pages for the same payslip share one request', () async {
    final a = container.listen(provider, (_, _) {});
    final b = container.listen(provider, (_, _) {});
    addTearDown(a.close);
    addTearDown(b.close);

    await container.read(provider.future);

    expect(repository.pdfIds, ['p-oct']);
    expect(files.writes, hasLength(1));
  });

  test('when the page closes the file is deleted', () async {
    final sub = container.listen(provider, (_, _) {});
    final path = await container.read(provider.future);

    sub.close();
    await container.pump();

    expect(files.deletes, [path]);
    expect(files.live, isEmpty);
  });

  test('a page closed while the PDF is being made leaves no file', () async {
    final hold = Completer<void>();
    repository.holdPdf = hold;
    final sub = container.listen(provider, (_, _) {});
    await container.pump();

    sub.close();
    await container.pump();
    hold.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(files.live, isEmpty);
  });

  test('a failure writes nothing and is the state\'s error', () async {
    repository.pdfResult = const Result.failure(
      Failure.server(message: 'boom', statusCode: 500),
    );
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);

    await expectLater(container.read(provider.future), throwsA(isA<ServerFailure>()));

    expect(files.writes, isEmpty);
    expect(container.read(provider).error, isA<ServerFailure>());
  });

  test('retry asks again and loads the PDF', () async {
    repository.pdfResult = const Result.failure(
      Failure.server(message: 'boom', statusCode: 500),
    );
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future).catchError((_) => '');

    repository.pdfResult = Result.success(samplePayslipPdf);
    await container.read(provider.notifier).retry();

    expect(repository.pdfIds, ['p-oct', 'p-oct']);
    expect(container.read(provider).valueOrNull, isNotNull);
  });

  test('retry while a load is running sends nothing more', () async {
    final hold = Completer<void>();
    repository.holdPdf = hold;
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.pump();

    unawaited(container.read(provider.notifier).retry());
    hold.complete();
    await container.read(provider.future);

    expect(repository.pdfIds, ['p-oct']);
  });

  test('share hands the file to the share sheet', () async {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    final path = await container.read(provider.future);

    final shared = await container.read(provider.notifier).share();

    expect(shared, isTrue);
    expect(files.shares.single.path, path);
  });

  test('share says so when the share sheet could not be opened', () async {
    files.shareFails = true;
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future);

    expect(await container.read(provider.notifier).share(), isFalse);
  });

  test('share with no PDF yet does nothing', () async {
    repository.pdfResult = const Result.failure(
      Failure.server(message: 'boom', statusCode: 500),
    );
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await container.read(provider.future).catchError((_) => '');

    expect(await container.read(provider.notifier).share(), isFalse);
    expect(files.shares, isEmpty);
  });
}
