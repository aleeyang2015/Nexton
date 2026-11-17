import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_pdf.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_files.dart';

/// The temp files behind the PDF page, on a real folder: written under the
/// server's name, each in a folder of its own, and gone once deleted.
void main() {
  late Directory temp;
  late PayslipPdfFiles files;

  final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('payslip_pdf_files_test');
    files = PayslipPdfFiles(tempDir: () async => temp);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  PayslipPdf pdf(String name) => PayslipPdf(bytes: bytes, fileName: name);

  test('writes the bytes under the server\'s name, in the temp folder', () async {
    final path = await files.write(pdf('payslip-EMP-002-2026-09.pdf'));

    expect(path, startsWith(temp.path));
    expect(path, endsWith('payslip-EMP-002-2026-09.pdf'));
    expect(await File(path).readAsBytes(), bytes);
  });

  test('delete removes the file and its folder', () async {
    final path = await files.write(pdf('payslip-EMP-002-2026-09.pdf'));

    await files.delete(path);

    expect(await File(path).exists(), isFalse);
    expect(await File(path).parent.exists(), isFalse);
  });

  test('deleting twice, or a file already gone, throws nothing', () async {
    final path = await files.write(pdf('a.pdf'));

    await files.delete(path);
    await files.delete(path);
  });

  test('the same payslip opened twice gets two files: closing the first '
      'does not delete the second', () async {
    final first = await files.write(pdf('payslip-EMP-002-2026-09.pdf'));
    final second = await files.write(pdf('payslip-EMP-002-2026-09.pdf'));

    await files.delete(first);

    expect(first, isNot(second));
    expect(await File(second).exists(), isTrue);
  });

  test('files left by an App that was killed are cleared at the next open, '
      'and an open one is kept', () async {
    final leftover = Directory('${temp.path}/payslips/old');
    await leftover.create(recursive: true);
    await File('${leftover.path}/payslip-old.pdf').writeAsBytes(bytes);
    final open = await files.write(pdf('open.pdf'));

    final next = await files.write(pdf('next.pdf'));

    expect(await leftover.exists(), isFalse);
    expect(await File(open).exists(), isTrue);
    expect(await File(next).exists(), isTrue);
  });

  test('a write that fails leaves no folder behind, and the next one works',
      () async {
    // A file where the folder of PDFs should be: nothing can be written.
    await File('${temp.path}/payslips').writeAsString('in the way');

    await expectLater(files.write(pdf('a.pdf')), throwsA(anything));

    await File('${temp.path}/payslips').delete();
    final path = await files.write(pdf('b.pdf'));
    final folders = await Directory('${temp.path}/payslips').list().toList();
    expect(folders, hasLength(1));
    expect(await File(path).exists(), isTrue);
  });

  test('Android\'s share copies of payslips are cleared at the next open; '
      'other features\' shares are left alone', () async {
    final shared = Directory('${temp.path}/share_plus');
    await shared.create(recursive: true);
    final payslip = File('${shared.path}/payslip-EMP-002-2026-09.pdf');
    final other = File('${shared.path}/leave-photo.jpg');
    await payslip.writeAsBytes(bytes);
    await other.writeAsBytes(bytes);

    await files.write(pdf('next.pdf'));

    expect(await payslip.exists(), isFalse);
    expect(await other.exists(), isTrue);
  });

  group('safeFileName', () {
    test('keeps a plain name', () {
      expect(
        PayslipPdfFiles.safeFileName('payslip-EMP-002-2026-09.pdf'),
        'payslip-EMP-002-2026-09.pdf',
      );
    });

    test('a name with folders in it cannot leave the folder', () {
      expect(PayslipPdfFiles.safeFileName('../../etc/passwd'), 'passwd.pdf');
      expect(PayslipPdfFiles.safeFileName('..\\..\\x.pdf'), 'x.pdf');
      expect(PayslipPdfFiles.safeFileName('..'), 'payslip.pdf');
    });

    test('odd characters become _, and the name ends in .pdf', () {
      expect(PayslipPdfFiles.safeFileName('slip 9:30?.PDF'), 'slip_9_30_.pdf');
      expect(PayslipPdfFiles.safeFileName('slip'), 'slip.pdf');
      expect(PayslipPdfFiles.safeFileName(''), 'payslip.pdf');
    });

    test('a very long name is cut to 100 characters before .pdf', () {
      final name = PayslipPdfFiles.safeFileName('${'a' * 400}.pdf');

      expect(name, '${'a' * 100}.pdf');
    });

    test('a very long name can still be written', () async {
      final path = await files.write(pdf('${'a' * 400}.pdf'));

      expect(await File(path).exists(), isTrue);
    });
  });
}
