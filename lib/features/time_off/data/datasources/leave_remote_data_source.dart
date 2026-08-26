import '../../../../core/utils/result.dart';
import '../../domain/entities/leave_approval.dart';
import '../../domain/entities/leave_category.dart';
import '../../domain/entities/leave_history_query.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../domain/entities/leave_status.dart';
import '../../domain/entities/leave_summary.dart';

abstract class LeaveRemoteDataSource {
  Future<List<LeaveRequest>> history(LeaveHistoryQuery query);
  Future<LeaveSummary> summary(int year);
  Future<Unit> submit(LeaveRequestDraft draft);
  Future<List<LeaveApproval>> pendingApprovals();
  Future<List<LeaveApproval>> approvalHistory();
  Future<Unit> decideApproval({required String requestId, required bool approve});
}

/// Stand-in for the leave endpoints, which don't exist yet — returns fixed
/// sample data after a short delay so the UI has something real to render.
/// Swap the bodies below for Dio calls once the API is available; the
/// repository and everything above it never has to change.
class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  static final _requests = <LeaveRequest>[
    LeaveRequest(
      id: '1',
      category: LeaveCategory.annual,
      startDate: DateTime(2026, 8, 25),
      endDate: DateTime(2026, 8, 27),
      totalDays: 3,
      status: LeaveStatus.pending,
    ),
    LeaveRequest(
      id: '2',
      category: LeaveCategory.sick,
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 10),
      totalDays: 1,
      status: LeaveStatus.approved,
    ),
    LeaveRequest(
      id: '3',
      category: LeaveCategory.personal,
      startDate: DateTime(2026, 8, 3),
      endDate: DateTime(2026, 8, 3),
      totalDays: 1,
      status: LeaveStatus.rejected,
      reviewerComment: 'ມີປະຊຸມສຳຄັນໃນວັນດັ່ງກ່າວ',
    ),
  ];

  @override
  Future<List<LeaveRequest>> history(LeaveHistoryQuery query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _requests
        .where((r) => query.category == null || r.category == query.category)
        .where(
          (r) =>
              !r.endDate.isBefore(query.from) && !r.startDate.isAfter(query.to),
        )
        .toList();
  }

  @override
  Future<LeaveSummary> summary(int year) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return LeaveSummary(
      year: year,
      balances: const [
        LeaveCategoryBalance(
          category: LeaveCategory.annual,
          entitledDays: 15,
          usedDays: 3,
        ),
        LeaveCategoryBalance(
          category: LeaveCategory.sick,
          entitledDays: 30,
          usedDays: 1,
        ),
        LeaveCategoryBalance(
          category: LeaveCategory.personal,
          entitledDays: 5,
          usedDays: 1,
        ),
        LeaveCategoryBalance(
          category: LeaveCategory.rest,
          entitledDays: 5,
          usedDays: 0,
        ),
      ],
    );
  }

  @override
  Future<Unit> submit(LeaveRequestDraft draft) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final sorted = [...draft.dates]..sort();
    _requests.insert(
      0,
      LeaveRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        category: draft.category,
        startDate: sorted.first,
        endDate: sorted.last,
        totalDays: sorted.length,
        status: LeaveStatus.pending,
      ),
    );
    return Unit.instance;
  }

  // "Alex Vang"'s entries mirror `_requests` above — this stands in for the
  // approver's view of the same employee's submissions plus a couple of
  // colleagues', so the two mock lists read as one coherent team.
  static final _approvals = <LeaveApproval>[
    LeaveApproval(
      id: 'a1',
      requesterName: 'Alex Vang',
      category: LeaveCategory.annual,
      startDate: DateTime(2026, 8, 25),
      endDate: DateTime(2026, 8, 27),
      totalDays: 3,
      reason: 'ພັກຜ່ອນກັບຄອບຄົວ',
      status: LeaveStatus.pending,
      isNew: true,
    ),
    LeaveApproval(
      id: 'a2',
      requesterName: 'Kham Souvanna',
      category: LeaveCategory.personal,
      startDate: DateTime(2026, 8, 24),
      endDate: DateTime(2026, 8, 24),
      totalDays: 1,
      reason: 'ໄປທຸລະກິດສ່ວນຕົວ',
      status: LeaveStatus.pending,
      isNew: true,
    ),
    LeaveApproval(
      id: 'a3',
      requesterName: 'Noy Phommachanh',
      category: LeaveCategory.sick,
      startDate: DateTime(2026, 8, 23),
      endDate: DateTime(2026, 8, 23),
      totalDays: 1,
      reason: 'ບໍ່ສະບາຍ',
      status: LeaveStatus.approved,
    ),
    LeaveApproval(
      id: 'a4',
      requesterName: 'Alex Vang',
      category: LeaveCategory.sick,
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 10),
      totalDays: 1,
      reason: 'ບໍ່ສະບາຍ',
      status: LeaveStatus.approved,
    ),
    LeaveApproval(
      id: 'a5',
      requesterName: 'Alex Vang',
      category: LeaveCategory.personal,
      startDate: DateTime(2026, 8, 3),
      endDate: DateTime(2026, 8, 3),
      totalDays: 1,
      reason: 'ມີປະຊຸມສຳຄັນໃນວັນດັ່ງກ່າວ',
      status: LeaveStatus.rejected,
    ),
    LeaveApproval(
      id: 'a6',
      requesterName: 'Kham Souvanna',
      category: LeaveCategory.annual,
      startDate: DateTime(2026, 8, 5),
      endDate: DateTime(2026, 8, 6),
      totalDays: 2,
      reason: 'ໄປວຽກບ້ານ',
      status: LeaveStatus.approved,
    ),
  ];

  @override
  Future<List<LeaveApproval>> pendingApprovals() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _approvals.where((a) => a.status == LeaveStatus.pending).toList();
  }

  @override
  Future<List<LeaveApproval>> approvalHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _approvals.where((a) => a.status != LeaveStatus.pending).toList();
  }

  @override
  Future<Unit> decideApproval({
    required String requestId,
    required bool approve,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _approvals.indexWhere((a) => a.id == requestId);
    if (index == -1) return Unit.instance;

    final current = _approvals[index];
    _approvals[index] = LeaveApproval(
      id: current.id,
      requesterName: current.requesterName,
      category: current.category,
      startDate: current.startDate,
      endDate: current.endDate,
      totalDays: current.totalDays,
      reason: current.reason,
      status: approve ? LeaveStatus.approved : LeaveStatus.rejected,
    );
    return Unit.instance;
  }
}
