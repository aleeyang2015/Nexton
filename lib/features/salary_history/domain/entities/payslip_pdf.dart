import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// The rendered payslip from `GET /payroll/payslips/my/{id}/pdf`: the raw PDF bytes
/// plus the file name the server suggested (via `Content-Disposition`), if
/// any. The presentation layer decides where the bytes end up.
class PayslipPdf extends Equatable {
  final Uint8List bytes;
  final String? fileName;

  const PayslipPdf({required this.bytes, this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
