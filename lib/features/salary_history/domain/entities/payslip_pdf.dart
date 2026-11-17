import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// The rendered payslip from `GET /payroll/payslips/my/{id}/pdf`: the raw PDF
/// bytes and its file name, the one the server sent in `Content-Disposition`
/// (`payslip-EMP-002-2026-09.pdf`) or else `payslip-<id>.pdf`. The
/// presentation layer decides where the bytes end up.
class PayslipPdf extends Equatable {
  final Uint8List bytes;
  final String fileName;

  const PayslipPdf({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
