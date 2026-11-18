import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/ot_draft.dart';
import '../../domain/entities/ot_page.dart';
import '../../domain/entities/ot_post.dart';
import '../../domain/entities/ot_request.dart';
import '../models/ot_parse.dart';
import '../models/ot_post_model.dart';
import '../models/ot_request_model.dart';
import 'ot_api_paths.dart';
import 'ot_error_code.dart';

/// The employee's OT calls. Each sends the call and shows the answer: no
/// backend rule is checked in the App.
abstract class OtRemoteDataSource {
  Future<OtRequest> ask(OtDraft draft);

  Future<OtPage<OtRequest>> myRequests({
    OtStatus? status,
    DateTime? month,
    int page,
    int perPage,
  });

  Future<OtRequest> request(String id);

  /// The OT requests at the signed-in approver's steps (#48), one page by
  /// number: `GET ot-requests/my-approvals?status=&page=&per_page=`.
  /// [status] is read against the caller's own step: `pending` waits on
  /// them, `approved` / `rejected` they decided. Never `limit` (the server
  /// reads it as `per_page`, and pages by number only).
  Future<OtPage<OtRequest>> myApprovals({
    required OtApprovalStatus status,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  });

  Future<OtRequest> edit(String id, OtDraft draft);

  Future<OtRequest> cancel(String id);

  /// A head approves the waiting step [stepId] of request [id] (#49), with
  /// [comment] when one was typed. The body is `step_id` and `comment` only:
  /// never `pieces` (a head step refuses them). Answers the request; its
  /// `warnings` (HR's limits) are not read.
  Future<OtRequest> approve(String id, {required String stepId, String? comment});

  /// A head rejects the waiting step [stepId] with [comment], the reason
  /// (required).
  Future<OtRequest> reject(
    String id, {
    required String stepId,
    required String comment,
  });

  Future<OtPage<OtPost>> openPosts({int page, int perPage});

  Future<OtRequest> join(String postId);
}

class OtRemoteDataSourceImpl implements OtRemoteDataSource {
  final ApiClient _client;

  OtRemoteDataSourceImpl(this._client);

  @override
  Future<OtRequest> ask(OtDraft draft) => _business(() async {
    final response = await _client.post<dynamic>(
      OtPaths.requests,
      data: _body(draft),
    );
    return _request(response.data);
  });

  /// `status` is sent only as one of the four values the server knows; the
  /// list does not check it, and any other value would come back empty.
  /// None (all) and [OtStatus.unknown] send nothing.
  @override
  Future<OtPage<OtRequest>> myRequests({
    OtStatus? status,
    DateTime? month,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) => _business(() async {
    final wire = switch (status) {
      OtStatus.pending ||
      OtStatus.approved ||
      OtStatus.rejected ||
      OtStatus.cancelled => status!.name,
      OtStatus.unknown || null => null,
    };
    final response = await _client.get<dynamic>(
      OtPaths.requestsMy,
      queryParameters: {
        if (wire != null) 'status': wire,
        if (month != null) 'month': _yearMonth(month),
        'page': page,
        'per_page': perPage,
      },
    );
    return _page(response.data, page, OtRequestModel.tryFromJson);
  });

  @override
  Future<OtPage<OtRequest>> myApprovals({
    required OtApprovalStatus status,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) => _business(() async {
    try {
      final response = await _client.get<dynamic>(
        OtPaths.myApprovals,
        queryParameters: {
          'status': status.name,
          'page': page,
          'per_page': perPage,
        },
      );
      return _page(response.data, page, OtRequestModel.tryFromJson);
    } on DioException catch (error) {
      // A 422 here is the App's bug (a status or month it should never
      // send): say so in the log; the tab shows the shared load error.
      if (kDebugMode && error.response?.statusCode == 422) {
        debugPrint('[OT approvals] 422 for $status: ${error.response?.data}');
      }
      rethrow;
    }
  });

  @override
  Future<OtRequest> approve(
    String id, {
    required String stepId,
    String? comment,
  }) => _business(() async {
    final note = comment?.trim() ?? '';
    final response = await _client.put<dynamic>(
      OtPaths.approve(id),
      data: {'step_id': stepId, if (note.isNotEmpty) 'comment': note},
    );
    return _request(response.data);
  });

  @override
  Future<OtRequest> reject(
    String id, {
    required String stepId,
    required String comment,
  }) => _business(() async {
    try {
      final response = await _client.put<dynamic>(
        OtPaths.reject(id),
        data: {'step_id': stepId, 'comment': comment.trim()},
      );
      return _request(response.data);
    } on DioException catch (error) {
      // `422 errors.comment`: no reason (the dialog normally blocks that).
      final body = error.response?.data;
      final errors = body is Map ? body['errors'] : null;
      if (error.response?.statusCode == 422 &&
          errors is Map &&
          errors.containsKey('comment')) {
        throw const Failure.validation(
          message: OtErrorCode.tokenReasonRequired,
          code: 'VALIDATION_ERROR',
        );
      }
      rethrow;
    }
  });

  @override
  Future<OtRequest> request(String id) => _business(() async {
    final response = await _client.get<dynamic>(OtPaths.request(id));
    return _request(response.data);
  });

  @override
  Future<OtRequest> edit(String id, OtDraft draft) => _business(() async {
    final response = await _client.put<dynamic>(
      OtPaths.request(id),
      data: _body(draft),
    );
    return _request(response.data);
  });

  /// The answer carries `warnings`, which the App does not use.
  @override
  Future<OtRequest> cancel(String id) => _business(() async {
    final response = await _client.put<dynamic>(OtPaths.cancel(id));
    return _request(response.data);
  }, onCancel: true);

  @override
  Future<OtPage<OtPost>> openPosts({
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) => _business(() async {
    final response = await _client.get<dynamic>(
      OtPaths.openPosts,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return _page(response.data, page, OtPostModel.tryFromJson);
  });

  @override
  Future<OtRequest> join(String postId) => _business(() async {
    final response = await _client.post<dynamic>(OtPaths.join(postId));
    return _request(response.data);
  });

  /// The ask and edit body. `reason` is trimmed, and left out when empty.
  static Map<String, dynamic> _body(OtDraft draft) {
    final reason = draft.reason?.trim() ?? '';
    return {
      'work_date': _isoDate(draft.workDate),
      'start_time': draft.startTime,
      'end_time': draft.endTime,
      if (reason.isNotEmpty) 'reason': reason,
    };
  }

  static OtRequest _request(dynamic body) =>
      OtRequestModel.fromJson(ApiEnvelope.unwrapObject(body));

  /// A list and its `meta`. A row the App cannot read is skipped, not the
  /// whole page lost. A page number that is missing or not a whole number is
  /// the page asked for ([asked]), so a list never asks for a page twice; no
  /// `total_pages` is no page after this one.
  static OtPage<T> _page<T>(
    dynamic body,
    int asked,
    T? Function(Map<String, dynamic>) read,
  ) {
    final items = ApiEnvelope.unwrapList(body).map(read).whereType<T>().toList();
    final meta = body is Map ? OtJson.object(body['meta']) : null;
    final page = OtJson.intOf(meta?['page']) ?? asked;
    final totalPages = OtJson.intOf(meta?['total_pages']) ?? page;
    return OtPage<T>(items: items, page: page, totalPages: totalPages);
  }

  /// Turns a known OT refusal into a `Failure.validation` whose message is
  /// its token and whose code is the wire code; everything else rethrows for
  /// `BaseRepository.guard` (a `404` keeps its status, a `422` its field, an
  /// unknown code its message).
  ///
  /// Only a refusal is mapped (`400`, `403`, `409`): a `500` that carries an
  /// OT code is still a server failure, worth a Retry.
  ///
  /// `FORBIDDEN` means "reject it instead" only on cancel ([onCancel]).
  Future<T> _business<T>(
    Future<T> Function() call, {
    bool onCancel = false,
  }) async {
    try {
      return await call();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (!_refusals.contains(status)) rethrow;
      final code = ApiError.tryParse(error.response?.data)?.code;
      final token = (onCancel && code == OtErrorCode.forbidden)
          ? OtErrorCode.tokenCancelForbidden
          : OtErrorCode.tokenByWire[code];
      if (token != null) throw Failure.validation(message: token, code: code);
      rethrow;
    }
  }

  static const _refusals = {400, 403, 409};

  static String _isoDate(DateTime date) =>
      '${_yearMonth(date)}-${date.day.toString().padLeft(2, '0')}';

  static String _yearMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}
