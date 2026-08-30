import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
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
import 'leave_api_paths.dart';
import 'leave_error_code.dart';

/// The leave calls the time-off screen can make (leave-request-flutter.md §3).
abstract class LeaveRemoteDataSource {
  Future<List<LeaveType>> types();
  Future<List<LeaveBalance>> balances(int year);
  Future<List<LeaveRequest>> myRequests(LeaveHistoryQuery query);
  Future<LeaveRequest> requestDetail(String id);
  Future<LeaveRequest> submit(LeaveRequestDraft draft);
  Future<LeaveRequest> update(String id, LeaveRequestDraft draft);
  Future<LeaveRequest> cancel(String id);
  Future<List<LeaveRequest>> myApprovals({LeaveStatus? status});
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
  /// A calendar month of leave never has more rows than this, so one page is
  /// always the whole answer — same choice as `AttendanceRemoteDataSourceImpl`.
  static const int _pageSize = 100;

  final ApiClient _client;

  LeaveRemoteDataSourceImpl(this._client);

  @override
  Future<List<LeaveType>> types() async {
    final response = await _client.get<dynamic>(LeavePaths.types);
    return ApiEnvelope.unwrapList(
      response.data,
    ).map(LeaveTypeModel.fromJson).toList();
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
  Future<List<LeaveRequest>> myRequests(LeaveHistoryQuery query) async {
    final response = await _client.get<dynamic>(
      LeavePaths.requestsMy,
      queryParameters: {
        'start_date': _isoDate(query.from),
        'end_date': _isoDate(query.to),
        if (query.leaveTypeId != null) 'leave_type_id': query.leaveTypeId,
        if (query.status != null) 'status': query.status!.name,
        'page': 1,
        'per_page': _pageSize,
      },
    );
    return _parseList(response.data);
  }

  @override
  Future<LeaveRequest> requestDetail(String id) async {
    final response = await _client.get<dynamic>(LeavePaths.request(id));
    return LeaveRequestModel.fromJson(ApiEnvelope.unwrapObject(response.data));
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
    });
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
    });
  }

  @override
  Future<LeaveRequest> cancel(String id) {
    return _business(() async {
      final response = await _client.put<dynamic>(LeavePaths.cancel(id));
      return LeaveRequestModel.fromJson(
        ApiEnvelope.unwrapObject(response.data),
      );
    });
  }

  @override
  Future<List<LeaveRequest>> myApprovals({LeaveStatus? status}) async {
    final response = await _client.get<dynamic>(
      LeavePaths.myApprovals,
      queryParameters: {
        if (status != null) 'status': status.name,
        'page': 1,
        'per_page': _pageSize,
      },
    );
    return _parseList(response.data);
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
    });
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
    });
  }

  List<LeaveRequest> _parseList(dynamic body) =>
      ApiEnvelope.unwrapList(body).map(LeaveRequestModel.fromJson).toList();

  /// Turns a documented business refusal (§4) into a
  /// `Failure.validation(message: <token>)` the localizer can translate;
  /// everything else rethrows for `BaseRepository.toFailure`. Same pattern as
  /// `AttendanceRemoteDataSourceImpl._asBlocked`.
  Future<T> _business<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      final code = ApiError.tryParse(error.response?.data)?.code;
      final token = LeaveErrorCode.tokenByWire[code];
      if (token != null) {
        throw Failure.validation(message: token);
      }
      rethrow;
    }
  }

  static String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
