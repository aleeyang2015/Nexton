import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/offsite_outcome.dart';
import '../../domain/entities/offsite_request.dart';
import '../../domain/entities/time_correction_status.dart';
import '../models/offsite_detail_model.dart';
import '../models/offsite_request_body.dart';
import '../models/offsite_submission_model.dart';
import '../models/punch_block_details_model.dart';
import 'attendance_api_paths.dart';
import 'offsite_error_code.dart';

/// The off-site scan request calls ("ສະແກນນອກພື້ນທີ່").
///
/// Like the punch endpoints, filing a request answers an [OffsiteOutcome]
/// rather than throwing on a business refusal: a 409 from here is a normal
/// answer — "you already clocked in for the morning", "a request is already
/// pending" — not a failed request. Only genuine failures (offline, 401, 422,
/// 5xx) leave as exceptions, for the repository to turn into a
/// `Result.failure`.
abstract class OffsiteRemoteDataSource {
  Future<OffsiteOutcome> submit(OffsiteRequest request);

  /// The requests the signed-in approver decides on, newest first — the
  /// endpoint scopes to the caller, so a non-approver gets an empty list.
  ///
  /// [status] is passed straight to the endpoint, which reads it against the
  /// caller's own step rather than the request as a whole (§5). That
  /// distinction can't be made on the client — a request this approver cleared
  /// stays `pending` overall while it sits with HR — so the filter belongs on
  /// the query.
  Future<List<OffsiteRequestDetail>> approvals({TimeCorrectionStatus? status});

  /// Approves the request's current step. [stepId] is the step the caller saw
  /// pending; the backend refuses with `STEP_CHANGED` when it has moved on
  /// since. The body isn't read.
  Future<void> approve(String id, {String? stepId});

  /// Rejects a pending request. [note] is required by the endpoint (§8) — it is
  /// what the employee is told. The body isn't read.
  Future<void> reject(String id, {required String note, String? stepId});
}

class OffsiteRemoteDataSourceImpl implements OffsiteRemoteDataSource {
  /// One page covers the approver's inbox comfortably — the same ceiling the
  /// correction approvals use, and the endpoint's documented maximum.
  static const int _pageSize = 100;

  final ApiClient _client;

  OffsiteRemoteDataSourceImpl(this._client);

  @override
  Future<OffsiteOutcome> submit(OffsiteRequest request) async {
    final body = OffsiteRequestBody(request).toJson();
    _debugLog('POST ${AttendancePaths.offsiteRequests} body', body);

    try {
      final response = await _client.post<dynamic>(
        AttendancePaths.offsiteRequests,
        data: body,
      );
      _debugLog('response ${response.statusCode}', response.data);

      return OffsiteFiled(
        OffsiteSubmissionModel.fromJson(
          ApiEnvelope.unwrapObject(response.data),
        ),
      );
    } on DioException catch (error) {
      _debugLog('error ${error.response?.statusCode}', error.response?.data);

      final blocked = _asBlocked(error);
      if (blocked != null) return blocked;
      // Not a documented rule — let the repository map it to a Failure. A 422
      // in particular is already mapped to a field-scoped validation failure
      // by `ApiErrorMapper`, which is what the form wants.
      rethrow;
    }
  }

  @override
  Future<List<OffsiteRequestDetail>> approvals({
    TimeCorrectionStatus? status,
  }) async {
    final response = await _client.get<dynamic>(
      AttendancePaths.myOffsiteApprovals,
      queryParameters: {
        if (status != null) 'status': status.wireValue,
        'page': 1,
        'per_page': _pageSize,
      },
    );
    _debugLog(
      'GET ${AttendancePaths.myOffsiteApprovals} response',
      response.data,
    );

    final requests = ApiEnvelope.unwrapList(
      response.data,
    ).map(_detailOrNull).whereType<OffsiteRequestDetail>().toList();
    requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return requests;
  }

  @override
  Future<void> approve(String id, {String? stepId}) => _decide(
    AttendancePaths.approveOffsiteRequest(id),
    {if (stepId != null) 'step_id': stepId},
  );

  /// §8 names the rejection reason `note`, and rejects the call with a 422
  /// without it.
  @override
  Future<void> reject(
    String id, {
    required String note,
    String? stepId,
  }) => _decide(AttendancePaths.rejectOffsiteRequest(id), {
    'note': note.trim(),
    if (stepId != null) 'step_id': stepId,
  });

  /// An entry missing its id or method is dropped rather than shown
  /// half-empty — same policy as the correction approvals list.
  static OffsiteRequestDetail? _detailOrNull(Map<String, dynamic> json) {
    try {
      return OffsiteDetailModel.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  /// `PUT` an approver's decision, logging the answer either way.
  ///
  /// A refusal §7/§8 document leaves as a validation failure carrying a client
  /// token the localizer can translate — the same contract the correction
  /// decisions use. Anything else rethrows for the repository to map.
  Future<void> _decide(String path, Map<String, dynamic> body) async {
    _debugLog('PUT $path body', body);
    try {
      final response = await _client.put<dynamic>(path, data: body);
      _debugLog('PUT $path response ${response.statusCode}', response.data);
    } on DioException catch (error) {
      _debugLog(
        'PUT $path error ${error.response?.statusCode}',
        error.response?.data,
      );

      final code = ApiError.tryParse(error.response?.data)?.code;
      final token = OffsiteErrorCode.decisionTokenByWire[code];
      if (token != null) throw Failure.validation(message: token);
      rethrow;
    }
  }

  /// Recognises the refusals from §3's error table that the user can respond
  /// to.
  ///
  /// Returns null for everything else — an unknown code, a 422, a 5xx, an
  /// expired session — so an unrecognised answer is never dressed up as a rule
  /// the app claims to understand.
  OffsiteBlocked? _asBlocked(DioException error) {
    final response = error.response;
    final apiError = ApiError.tryParse(response?.data);
    final rule = OffsiteErrorCode.ruleByWire[apiError?.code];
    if (rule == null) return null;

    // Guard against a code that only *looks* familiar: §3's refusals arrive as
    // 400 or 409, never as a server fault.
    final status = response?.statusCode;
    if (status == null || status >= 500) return null;

    return OffsiteBlocked(
      rule: rule,
      message: apiError?.bestMessage ?? '',
      details: PunchBlockDetailsModel.fromErrorBody(response?.data),
    );
  }

  /// Pretty-prints a payload under one tag, so it can be found among the
  /// client's general request log. Debug builds only — the body carries the
  /// employee's position, reason and photo URL.
  static void _debugLog(String label, Object? data) {
    if (!kDebugMode) return;
    final text = data is Map || data is List
        ? const JsonEncoder.withIndent('  ').convert(data)
        : '$data';
    debugPrint('[Offsite] $label:\n$text', wrapWidth: 1024);
  }
}
