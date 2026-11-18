import 'dart:async';

import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/overtime/domain/entities/ot_draft.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_piece.dart';
import 'package:next_on/features/overtime/domain/entities/ot_post.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';
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

  /// Every my-approvals call (#48): the status and page asked for.
  final List<({OtApprovalStatus status, int page, int perPage})>
  approvalCalls = [];

  /// The answer to a my-approvals call; by default an empty single page.
  Result<OtPage<OtRequest>> Function(OtApprovalStatus status, int page)
  approvalsAnswer = (status, page) =>
      const Result.success(OtPage(items: [], page: 1, totalPages: 1));

  /// When set, a my-approvals call waits for it (taken by the call that
  /// sees it).
  Completer<void>? holdApprovals;

  /// A page number whose my-approvals answer waits for its completer.
  final Map<int, Completer<void>> holdApprovalPages = {};

  @override
  FutureResult<OtPage<OtRequest>> myApprovals({
    required OtApprovalStatus status,
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) async {
    approvalCalls.add((status: status, page: page, perPage: perPage));
    final answer = approvalsAnswer(status, page);
    final hold = holdApprovals;
    holdApprovals = null;
    await hold?.future;
    await holdApprovalPages[page]?.future;
    return answer;
  }

  /// Every head decision sent (#49): approve or reject, the request, its
  /// step and comment.
  final List<({String kind, String id, String stepId, String? comment})>
  decisions = [];

  /// The answer to a decision; by default the request with that step
  /// decided (approved: still pending at HR; rejected: rejected).
  Result<OtRequest> Function(String kind, String id) decisionAnswer =
      (kind, id) => Result.success(
        sampleOt(
          id,
          status: kind == 'reject' ? OtStatus.rejected : OtStatus.pending,
        ),
      );

  /// When set, a decision waits for it (taken by the call that sees it).
  Completer<void>? holdDecision;

  Future<Result<OtRequest>> _decide(
    String kind,
    String id,
    String stepId,
    String? comment,
  ) async {
    decisions.add((kind: kind, id: id, stepId: stepId, comment: comment));
    final answer = decisionAnswer(kind, id);
    final hold = holdDecision;
    holdDecision = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OtRequest> approve(
    String id, {
    required String stepId,
    String? comment,
  }) => _decide('approve', id, stepId, comment);

  @override
  FutureResult<OtRequest> reject(
    String id, {
    required String stepId,
    required String comment,
  }) => _decide('reject', id, stepId, comment);

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

  /// Every edit sent: the request's id and the new draft.
  final List<({String id, OtDraft draft})> edits = [];

  /// The answer to an edit; by default the request with the new day and
  /// times, its steps started again.
  Result<OtRequest> Function(String id, OtDraft draft) editAnswer =
      (id, draft) => Result.success(
        sampleOt(
          id,
          workDate: draft.workDate,
          start: draft.startTime,
          end: draft.endTime,
        ),
      );

  /// When set, an edit waits for it (taken by the call that sees it).
  Completer<void>? holdEdit;

  /// The ids cancel was asked for, in order.
  final List<String> cancels = [];

  /// The answer to a cancel; by default the request, cancelled.
  Result<OtRequest> Function(String id) cancelAnswer = (id) =>
      Result.success(sampleOt(id, status: OtStatus.cancelled));

  /// When set, a cancel waits for it (taken by the call that sees it).
  Completer<void>? holdCancel;

  /// The pages of open posts asked for, in order.
  final List<int> postPages = [];

  /// The answer to a page of open posts; by default none.
  Result<OtPage<OtPost>> Function(int page) postsAnswer = (page) =>
      Result.success(OtPage(items: const [], page: page, totalPages: 1));

  /// When set, a page of posts waits for it (taken by the call that sees it).
  Completer<void>? holdPosts;

  /// The posts joined, in order.
  final List<String> joins = [];

  /// The answer to a join; by default the new request, pending, for HR.
  Result<OtRequest> Function(String postId) joinAnswer = (postId) =>
      Result.success(sampleOt('ot-join-$postId', announcementId: postId));

  /// When set, a join waits for it (taken by the call that sees it).
  Completer<void>? holdJoin;

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
  FutureResult<OtRequest> edit(String id, OtDraft draft) async {
    edits.add((id: id, draft: draft));
    final answer = editAnswer(id, draft);
    final hold = holdEdit;
    holdEdit = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OtRequest> cancel(String id) async {
    cancels.add(id);
    final answer = cancelAnswer(id);
    final hold = holdCancel;
    holdCancel = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OtPage<OtPost>> openPosts({
    int page = 1,
    int perPage = OtPage.defaultPerPage,
  }) async {
    postPages.add(page);
    final answer = postsAnswer(page);
    final hold = holdPosts;
    holdPosts = null;
    await hold?.future;
    return answer;
  }

  @override
  FutureResult<OtRequest> join(String postId) async {
    joins.add(postId);
    final answer = joinAnswer(postId);
    final hold = holdJoin;
    holdJoin = null;
    await hold?.future;
    return answer;
  }
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
  String employeeId = 'emp-noy',
  String? reason,
  List<OtStep> steps = const [],
}) => OtRequest(
  id: id,
  employeeId: employeeId,
  reason: reason,
  steps: steps,
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

/// HR's post for the kitchen: Saturday 7 November 08:00–12:00 at 200%,
/// 5 places, 2 accepted, closes Friday 6 November 17:00.
OtPost samplePost(
  String id, {
  int? seats = 5,
  int accepted = 2,
  bool full = false,
  bool joinOpen = true,
  OtRequest? myJoin,
  bool? joined,
  DateTime? joinDeadline,
  bool noDeadline = false,
  String? reason = 'Banquet prep',
}) => OtPost(
  id: id,
  departmentId: 'dep-kitchen',
  departmentName: 'Kitchen',
  workDate: DateTime(2026, 11, 7),
  startTime: '08:00',
  endTime: '12:00',
  startsAt: DateTime(2026, 11, 7, 8),
  endsAt: DateTime(2026, 11, 7, 12),
  seats: seats,
  accepted: accepted,
  joinDeadline: noDeadline ? null : (joinDeadline ?? DateTime(2026, 11, 6, 17)),
  reason: reason,
  status: OtPostStatus.open,
  full: full,
  joinOpen: joinOpen,
  myJoin: myJoin,
  joined: joined,
  pieces: [
    OtPiece(
      id: '$id-p1',
      pieceNo: 1,
      startsAt: DateTime(2026, 11, 7, 8),
      endsAt: DateTime(2026, 11, 7, 12),
      payType: OtPayType.percent,
      payValue: 200,
    ),
  ],
);
