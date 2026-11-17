import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/payslip_pdf.dart';
import '../../domain/entities/payslip_record.dart';
import '../models/payslip_record_model.dart';
import 'salary_api_paths.dart';

abstract class SalaryRemoteDataSource {
  Future<PayslipPdf> pdf(String id);

  /// The caller's payslips for [year], as the server sends them.
  Future<List<PayslipRecord>> myPayslips(int year);

  /// One of the caller's payslips in full, as the server sends it.
  Future<PayslipRecord> myPayslip(String id);
}

/// The payroll calls behind the salary-history screens, on the shared
/// authenticated [ApiClient].
class SalaryRemoteDataSourceImpl implements SalaryRemoteDataSource {
  /// A `Failure.validation` message token the localizer knows, raised when
  /// the PDF endpoint answers 200 with something that isn't a PDF.
  static const String pdfInvalidToken = 'salaryPdfInvalid';

  static const _pdfMagic = [0x25, 0x50, 0x44, 0x46]; // %PDF

  final ApiClient _client;

  SalaryRemoteDataSourceImpl(this._client);

  /// A year has at most a handful of payslips and the server sends up to
  /// 100 in a page, so one page is the whole year.
  static const int _yearPageSize = 100;

  /// No `status` is sent: staff are only ever given payslips of runs HR has
  /// approved or paid, and every one of them belongs on the screen. The
  /// order is the server's (newest pay month first); nothing is sorted
  /// here.
  ///
  /// A login with no employee record gets `200` with an empty list, not an
  /// error.
  @override
  Future<List<PayslipRecord>> myPayslips(int year) async {
    final response = await _client.get<dynamic>(
      SalaryPaths.payslipsMy,
      queryParameters: {'year': year, 'page': 1, 'per_page': _yearPageSize},
    );
    return ApiEnvelope.unwrapList(
      response.data,
    ).map(PayslipRecordModel.fromJson).toList();
  }

  /// An id the server does not have, someone else's, or a payslip not yet
  /// approved all answer `404`; the failure keeps that status for the page
  /// to say so.
  @override
  Future<PayslipRecord> myPayslip(String id) async {
    final response = await _client.get<dynamic>(SalaryPaths.payslip(id));
    return PayslipRecordModel.fromJson(
      ApiEnvelope.unwrapObject(response.data),
    );
  }

  /// The payslip's PDF. A refusal comes back as JSON in bytes; the error
  /// mapper reads its code (`ApiError.tryParse`). A 200 that is not a PDF
  /// is refused here, so nothing ever opens a JSON body as a file.
  @override
  Future<PayslipPdf> pdf(String id) async {
    final response = await _client.get<List<int>>(
      SalaryPaths.payslipPdf(id),
      options: Options(responseType: ResponseType.bytes),
    );

    final data = response.data;
    // Dio already hands bytes over as a Uint8List: no second copy of the PDF.
    final bytes = data == null
        ? Uint8List(0)
        : data is Uint8List
        ? data
        : Uint8List.fromList(data);
    if (!_looksLikePdf(bytes)) {
      throw const Failure.validation(message: pdfInvalidToken);
    }

    return PayslipPdf(
      bytes: bytes,
      fileName:
          _fileNameOf(response.headers.value('content-disposition')) ??
          'payslip-$id.pdf',
    );
  }

  static bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < _pdfMagic.length) return false;
    for (var i = 0; i < _pdfMagic.length; i++) {
      if (bytes[i] != _pdfMagic[i]) return false;
    }
    return true;
  }

  /// `attachment; filename="payslip.pdf"` → `payslip.pdf`; null when the
  /// header is absent or carries no name.
  static String? _fileNameOf(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final match = RegExp(
      'filename\\*?=(?:UTF-8\'\')?"?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    final name = match?.group(1)?.trim();
    return (name == null || name.isEmpty) ? null : name;
  }
}
