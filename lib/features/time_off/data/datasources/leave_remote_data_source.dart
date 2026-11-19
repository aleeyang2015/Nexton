import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/paged_list.dart';
import '../../domain/entities/company_days_off.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_history_query.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../domain/entities/leave_status.dart';
import '../../domain/entities/leave_type.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_draft_body.dart';
import '../models/leave_request_model.dart';
import '../models/leave_type_model.dart';
import '../models/rest_day_model.dart';
import 'leave_api_paths.dart';
import 'leave_error_code.dart';
import 'leave_rule_code.dart';

/// The leave calls the time-off screen can make (leave-request-flutter.md §3).
abstract class LeaveRemoteDataSource {
  Future<List<LeaveType>> types();

  /// The company's days off, read to the last page.
  Future<CompanyDaysOff> restDays();
  Future<List<LeaveBalance>> balances(int year);
  /// One page of the caller's requests for [query], newest first. [cursor]
  /// is the last page's `nextCursor`; leave it out for the first page.
  Future<CursorPage<LeaveRequest>> myRequests(
    LeaveHistoryQuery query, {
    String? cursor,
  });
  /// The caller's request that is waiting for a decision, or null when
  /// there is none.
  Future<LeaveRequest?> pendingRequest();
  Future<LeaveRequest> requestDetail(String id);
  Future<LeaveRequest> submit(LeaveRequestDraft draft);
  Future<LeaveRequest> update(String id, LeaveRequestDraft draft);
  Future<LeaveRequest> cancel(String id);
  /// One page of the requests the caller decides, newest updated first.
  /// [status] filters by the caller's own step, not the request's status;
  /// [cursor] is the page before's `nextCursor`.
  Future<CursorPage<LeaveRequest>> myApprovals({
    LeaveStatus? status,
    String? cursor,
  });
  /// One page of the requests of the head's team (#50,
  /// `GET /leave/requests/team`), any status, newest first; [status] filters
  /// by the request's own status. HR rights get the whole company (the
  /// notifier keeps the departments the login heads).
  Future<CursorPage<LeaveRequest>> teamRequests({
    LeaveStatus? status,
    String? cursor,
  });
  Future<LeaveRequest> approve({
    required String id,
    String? stepId,
    String? note,
  });
  Future<LeaveRequest> reject({
    required String id,
    required String reason,
    String? stepId,
    String? note,
  });
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  /// How many requests each approvals list asks for at a time.
  static const int approvalsPageSize = 20;

  /// The most the server sends in one page. Used by the lists read in one go
  /// (leave types, rest days).
  static const int _pageSize = 100;

  /// How many requests the history asks for at a time; it loads the next
  /// page as the user scrolls.
  static const int historyPageSize = 20;

  final ApiClient _client;

  LeaveRemoteDataSourceImpl(this._client);

  @override
  Future<List<LeaveType>> types() async {
    // The endpoint sends 20 rows unless asked for more, and a company can
    // have more types than that. No `is_active` filter: a switched-off type is
    // still needed to name the requests made on it.
    final response = await _client.get<dynamic>(
      LeavePaths.types,
      queryParameters: {'per_page': _pageSize},
    );
    return ApiEnvelope.unwrapList(
      response.data,
    ).map(LeaveTypeModel.fromJson).toList();
  }

  /// A company can have more rules than one page holds (20 by default, 100 at
  /// most), and a day off missing from the list is a day the form would let
  /// someone pick and be charged for. So every page is read, following
  /// `meta.total_pages`.
  @override
  Future<CompanyDaysOff> restDays() async {
    final rules = <RestDayRule>[];

    for (var page = 1; page <= _maxRestDayPages; page++) {
      final response = await _client.get<dynamic>(
        LeavePaths.restDays,
        queryParameters: {'page': page, 'per_page': _pageSize},
      );

      rules.addAll(
        ApiEnvelope.unwrapList(
          response.data,
        ).map(RestDayModel.fromJson).whereType<RestDayRule>(),
      );

      if (page >= _totalPagesOf(response.data)) break;
    }

    return CompanyDaysOff(rules);
  }

  /// A stop for a `total_pages` that is wrong, so a bad answer cannot keep
  /// the form asking for ever. 2,000 rules is far past any real company.
  static const int _maxRestDayPages = 20;

  /// `meta.total_pages` of a paged answer, or 1 when it carries none.
  static int _totalPagesOf(dynamic body) {
    if (body is! Map) return 1;
    final meta = body['meta'];
    if (meta is! Map) return 1;
    return (meta['total_pages'] as num?)?.toInt() ?? 1;
  }

  @override
  Future<List<LeaveBalance>> balances(int year) async {
    final response = await _client.get<dynamic>(
      LeavePaths.balancesMy,
      queryParameters: {'year': year},
    );
    return ApiEnvelope.unwrapList(
      response.data,
    ).map(LeaveBalanceModel.fromJson).toList();
  }

  @override
  Future<CursorPage<LeaveRequest>> myRequests(
    LeaveHistoryQuery query, {
    String? cursor,
  }) async {
    final response = await _client.get<dynamic>(
      LeavePaths.requestsMy,
      queryParameters: {
        'start_date': _isoDate(query.from),
        'end_date': _isoDate(query.to),
        if (query.leaveTypeId != null) 'leave_type_id': query.leaveTypeId,
        if (query.status != null) 'status': query.status!.name,
        // Sending `limit` puts the endpoint in cursor mode.
        'limit': historyPageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return CursorPage.fromBody(response.data, LeaveRequestModel.fromJson);
  }

  /// `status=pending&limit=1` puts the list in cursor mode; `data` is still
  /// a list, of one request or none.
  @override
  Future<LeaveRequest?> pendingRequest() async {
    final response = await _client.get<dynamic>(
      LeavePaths.requestsMy,
      queryParameters: {'status': LeaveStatus.pending.name, 'limit': 1},
    );
    final list = _parseList(response.data);
    return list.isEmpty ? null : list.first;
  }

  /// Through [_business], so a `404` (the request is gone, is someone
  /// else's, or the id is not one) becomes the "request gone" token.
  @override
  Future<LeaveRequest> requestDetail(String id) {
    return _business(() async {
      final response = await _client.get<dynamic>(LeavePaths.request(id));
      return LeaveRequestModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    }, onRequest: true);
  }

  @override
  Future<LeaveRequest> submit(LeaveRequestDraft draft) {
    return _business(() async {
      final response = await _client.post<dynamic>(
        LeavePaths.requests,
        data: LeaveDraftBody.from(draft),
      );
      return LeaveRequestModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    }, asking: true);
  }

  @override
  Future<LeaveRequest> update(String id, LeaveRequestDraft draft) {
    return _business(() async {
      final response = await _client.put<dynamic>(
        LeavePaths.request(id),
        data: LeaveDraftBody.from(draft),
      );
      return LeaveRequestModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    }, onRequest: true, asking: true);
  }

  @override
  Future<LeaveRequest> cancel(String id) {
    return _business(() async {
      final response = await _client.put<dynamic>(LeavePaths.cancel(id));
      return LeaveRequestModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    }, onRequest: true);
  }

  @override
  Future<CursorPage<LeaveRequest>> myApprovals({
    LeaveStatus? status,
    String? cursor,
  }) async {
    final response = await _client.get<dynamic>(
      LeavePaths.myApprovals,
      queryParameters: {
        if (status != null) 'status': status.name,
        // Sending `limit` puts the endpoint in cursor mode.
        'limit': approvalsPageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return CursorPage.fromBody(response.data, LeaveRequestModel.fromJson);
  }

  @override
  Future<CursorPage<LeaveRequest>> teamRequests({
    LeaveStatus? status,
    String? cursor,
  }) async {
    final response = await _client.get<dynamic>(
      LeavePaths.requestsTeam,
      queryParameters: {
        if (status != null) 'status': status.name,
        // Sending `limit` puts the endpoint in cursor mode.
        'limit': approvalsPageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return CursorPage.fromBody(response.data, LeaveRequestModel.fromJson);
  }

  @override
  Future<LeaveRequest> approve({
    required String id,
    String? stepId,
    String? note,
  }) {
    return _business(() async {
      final response = await _client.put<dynamic>(
        LeavePaths.approve(id),
        data: {
          if (stepId != null) 'step_id': stepId,
          if (note != null && note.trim().isNotEmpty)
            'approver_note': note.trim(),
        },
      );
      return LeaveRequestModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    }, onRequest: true);
  }

  @override
  Future<LeaveRequest> reject({
    required String id,
    required String reason,
    String? stepId,
    String? note,
  }) {
    return _business(() async {
      final response = await _client.put<dynamic>(
        LeavePaths.reject(id),
        data: {
          'reason': reason.trim(),
          if (stepId != null) 'step_id': stepId,
          if (note != null && note.trim().isNotEmpty)
            'approver_note': note.trim(),
        },
      );
      return LeaveRequestModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    }, onRequest: true);
  }

  List<LeaveRequest> _parseList(dynamic body) =>
      ApiEnvelope.unwrapList(body).map(LeaveRequestModel.fromJson).toList();

  /// Turns a documented business refusal (§4) into a
  /// `Failure.validation(message: <token>)` the localizer can translate;
  /// everything else rethrows for `BaseRepository.toFailure`. Same pattern as
  /// `AttendanceRemoteDataSourceImpl._asBlocked`.
  ///
  /// [onRequest] is set by the calls about one existing request (edit,
  /// cancel, approve, reject): there a `NOT_FOUND` means that request is
  /// gone. Creating a request does not set it.
  ///
  /// [asking] is set by the two calls that ask for leave (create, edit):
  /// only those are checked against the leave type's rules
  /// ([LeaveRuleCode]).
  Future<T> _business<T>(
    Future<T> Function() call, {
    bool onRequest = false,
    bool asking = false,
  }) async {
    try {
      return await call();
    } on DioException catch (error) {
      final code = ApiError.tryParse(error.response?.data)?.code;
      // Asking for leave and short of days: when the server names the year
      // it is said with the year (#87). Otherwise the plain token below.
      if (asking && code == LeaveErrorCode.insufficientBalance) {
        final named = LeaveRuleCode.fromResponse(error);
        if (named != null) throw named;
      }
      final token = (onRequest && code == LeaveErrorCode.notFound)
          ? LeaveErrorCode.tokenRequestGone
          : LeaveErrorCode.tokenByWire[code];
      if (token != null) {
        throw Failure.validation(message: token);
      }
      final rule = asking ? LeaveRuleCode.fromResponse(error) : null;
      if (rule != null) throw rule;
      rethrow;
    }
  }

  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
