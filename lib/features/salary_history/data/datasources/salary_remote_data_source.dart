import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/payslip.dart';
import '../../domain/entities/payslip_pdf.dart';
import '../models/payslip_model.dart';
import 'salary_api_paths.dart';

abstract class SalaryRemoteDataSource {
  Future<List<Payslip>> history(int year);
  Future<Payslip> detail(String id);
  Future<PayslipPdf> pdf(String id);
}

/// The payroll calls behind the salary-history screens, on the shared
/// authenticated [ApiClient].
class SalaryRemoteDataSourceImpl implements SalaryRemoteDataSource {
  /// The history page shows one year at a time and the backend pages at
  /// this size; `has_more` is not followed.
  static const int _pageSize = 10;

  /// `status=all` — the Paid/Pending chips filter locally on
  /// `payment_status`, so one call serves every chip.
  static const String _allStatuses = 'all';

  /// A `Failure.validation` message token the localizer knows, raised when
  /// the PDF endpoint answers 200 with something that isn't a PDF.
  static const String pdfInvalidToken = 'salaryPdfInvalid';

  static const _pdfMagic = [0x25, 0x50, 0x44, 0x46]; // %PDF

  final ApiClient _client;

  SalaryRemoteDataSourceImpl(this._client);

  @override
  Future<List<Payslip>> history(int year) async {
    final response = await _client.get<dynamic>(
      SalaryPaths.payslipsMy,
      queryParameters: {
        'year': year,
        'status': _allStatuses,
        'limit': _pageSize,
      },
    );
    final payslips = ApiEnvelope.unwrapList(
      response.data,
    ).map(PayslipModel.fromJson).toList();
    // Newest period first — the first row backs the highlighted summary card.
    payslips.sort((a, b) {
      final byYear = b.year.compareTo(a.year);
      return byYear != 0 ? byYear : b.month.compareTo(a.month);
    });
    return payslips;
  }

  @override
  Future<Payslip> detail(String id) async {
    final response = await _client.get<dynamic>(SalaryPaths.payslip(id));
    return PayslipModel.fromJson(ApiEnvelope.unwrapObject(response.data));
  }

  @override
  Future<PayslipPdf> pdf(String id) async {
    final response = await _client.get<List<int>>(
      SalaryPaths.payslipPdf(id),
      options: Options(responseType: ResponseType.bytes),
    );

    final data = response.data;
    final bytes = data == null ? Uint8List(0) : Uint8List.fromList(data);
    if (!_looksLikePdf(bytes)) {
      throw const Failure.validation(message: pdfInvalidToken);
    }

    return PayslipPdf(
      bytes: bytes,
      fileName: _fileNameOf(response.headers.value('content-disposition')),
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
