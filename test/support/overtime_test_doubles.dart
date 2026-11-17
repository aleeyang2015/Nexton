import 'dart:async';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/overtime/domain/entities/ot_draft.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_post.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/repositories/ot_repository.dart';

/// One `myRequests` call, as the fake saw it.
typedef OtListCall = ({OtStatus? status, DateTime? month, int page, int perPage});

/// Programmable OT repository: records each list call and answers it from
/// [myRequestsAnswer]; [holdMyRequests] keeps an answer back until it is
/// completed.
class FakeOtRepository implements OtRepository {
  final List<OtListCall> listCalls = [];

  /// The answer to a list call; by default an empty single page.
  Result<OtPage<OtRequest>> Function(OtListCall call) myRequestsAnswer =
      (call) => const Result.success(
        OtPage(items: [], page: 1, totalPages: 1),
      );

  /// When set, a list call waits for it (taken by the call that sees it).
  Completer<void>? holdMyRequests;

  /// Every draft the ask call was sent, in order.
  final List<OtDraft> asked = [];

  /// The answer to an ask; by default the new request, pending, as `ot-new`.
  Result<OtRequest> Function(OtDraft draft) askAnswer = (draft) =>
      Result.success(
        sampleOt(
          'ot-new',
          workDate: draft.workDate,
          start: draft.startTime,
          end: draft.endTime,
        ),
      );

  /// When set, an ask waits for it (taken by the call that sees it).
  Completer<void>? holdAsk;

  /// The ids the detail call was asked for, in order.
  final List<String> requestIds = [];

  /// The answer to a detail call; by default a pending request with that id.
  Result<OtRequest> Function(String id) requestAnswer = (id) =>
      Result.success(sampleOt(id));

  /// When set, a detail call waits for it (taken by the call that sees it).
  Completer<void>? holdRequest;

  @override
  FutureResult<OtPage<OtRequest>> myRequests({
    OtStatus? status,
    DateTime? month,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) async {
    final call = (status: status, month: month, page: page, perPage: perPage);
    listCalls.add(call);
    final answer = myRequestsAnswer(call);
    final hold = holdMyRequests;
    holdMyRequests = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OtRequest> ask(OtDraft draft) async {
    asked.add(draft);
    final answer = askAnswer(draft);
    final hold = holdAsk;
    holdAsk = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OtRequest> request(String id) async {
    requestIds.add(id);
    final answer = requestAnswer(id);
    final hold = holdRequest;
    holdRequest = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OtRequest> edit(String id, OtDraft draft) => _unused();

  @override
  FutureResult<OtRequest> cancel(String id) => _unused();

  @override
  FutureResult<OtPage<OtPost>> openPosts({
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) => _unused();

  @override
  FutureResult<OtRequest> join(String postId) => _unused();

  static Future<Result<T>> _unused<T>() async => const Result.failure(
    Failure.unknown(message: 'not used by this test'),
  );
}

/// An OT request for a list, with only what a row shows.
OtRequest sampleOt(
  String id, {
  DateTime? workDate,
  String start = '18:00',
  String end = '20:00',
  bool endsNextDay = false,
  OtStatus status = OtStatus.pending,
  String? announcementId,
  bool didNotCome = false,
}) => OtRequest(
  id: id,
  employeeId: 'emp-noy',
  workDate: workDate ?? DateTime(2026, 11, 14),
  startTime: start,
  endTime: end,
  endsNextDay: endsNextDay,
  status: status,
  announcementId: announcementId,
  didNotCome: didNotCome,
);

/// [total] requests served [perPage] at a time: page n holds ids
/// `ot-<(n-1)*perPage>` onward.
Result<OtPage<OtRequest>> pagedOt(OtListCall call, {required int total}) {
  final pages = (total / call.perPage).ceil();
  final from = (call.page - 1) * call.perPage;
  final to = (from + call.perPage).clamp(0, total);
  return Result.success(
    OtPage(
      items: [for (var i = from; i < to; i++) sampleOt('ot-$i')],
      page: call.page,
      totalPages: pages,
    ),
  );
}
