import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../domain/entities/ot_page.dart';
import '../../domain/entities/ot_request.dart';
import '../../domain/entities/ot_step.dart';
import '../../overtime_providers.dart';

/// What the approvals page's OT tab renders from (#48), in #19's shape: the
/// requests waiting at the head's step, then the ones they decided, one of
/// two chips at a time. Each list pages by number.
///
/// The lists hold the server's pages as they came, so paging stays right;
/// the rows a head may see ([pendingRows], [decidedRows]) leave out HR
/// steps, which the App does not decide (main-session call: OT's HR step
/// needs pay pieces the App cannot set).
class OtApprovalsState {
  const OtApprovalsState({
    this.pending = const AsyncValue.loading(),
    this.decided = const AsyncValue.loading(),
    this.decidedFilter = OtApprovalStatus.approved,
    this.employeeId,
  });

  final AsyncValue<PagedList<OtRequest>> pending;
  final AsyncValue<PagedList<OtRequest>> decided;

  /// [OtApprovalStatus.approved] or [OtApprovalStatus.rejected].
  final OtApprovalStatus decidedFilter;

  /// The signed-in head's employee id: whose decided step is whose.
  final String? employeeId;

  /// The waiting rows a head decides: the step waiting now is not HR's.
  List<OtRequest> get pendingRows => [
    for (final r in pending.valueOrNull?.items ?? const <OtRequest>[])
      if (keeps(r, OtApprovalStatus.pending, employeeId)) r,
  ];

  /// The decided rows: the step the head decided is not HR's.
  List<OtRequest> get decidedRows => [
    for (final r in decided.valueOrNull?.items ?? const <OtRequest>[])
      if (keeps(r, decidedFilter, employeeId)) r,
  ];

  /// Whether [request], from the [status] list, shows: an HR step never
  /// does.
  ///
  /// Waiting: the step waiting now is not HR's (none found: it shows, the
  /// server put it in this list). Decided: the step I decided is not HR's;
  /// when no step can be matched to me (no id, or the server names the
  /// approver another way), it shows only if no step decided that way is
  /// HR's — never an HR decision by mistake.
  static bool keeps(
    OtRequest request,
    OtApprovalStatus status,
    String? employeeId,
  ) {
    final stepStatus = switch (status) {
      OtApprovalStatus.pending => null,
      OtApprovalStatus.approved => OtStepStatus.approved,
      OtApprovalStatus.rejected => OtStepStatus.rejected,
    };
    if (stepStatus == null) {
      return request.pendingStep?.role != OtStepRole.hr;
    }
    final mine = _decidedBy(request, employeeId, stepStatus);
    if (mine != null) return mine.role != OtStepRole.hr;
    final decided = request.steps.where((s) => s.status == stepStatus);
    return decided.isNotEmpty && decided.every((s) => s.role != OtStepRole.hr);
  }

  static OtStep? _decidedBy(
    OtRequest request,
    String? employeeId,
    OtStepStatus status,
  ) {
    if (employeeId == null || employeeId.isEmpty) return null;
    for (final step in request.steps) {
      if (step.approverId == employeeId && step.status == status) return step;
    }
    return null;
  }

  OtApprovalsState copyWith({
    AsyncValue<PagedList<OtRequest>>? pending,
    AsyncValue<PagedList<OtRequest>>? decided,
    OtApprovalStatus? decidedFilter,
  }) => OtApprovalsState(
    pending: pending ?? this.pending,
    decided: decided ?? this.decided,
    decidedFilter: decidedFilter ?? this.decidedFilter,
    employeeId: employeeId,
  );
}

/// The approvals page's OT tab (#48): `GET ot-requests/my-approvals`, the
/// waiting list and the "decided by me" list in parallel, each a page at a
/// time by number. A page that leaves fewer rows than a page once HR steps
/// are hidden asks for the next one at once, so the tab never says "none"
/// while more pages exist.
class OtApprovalsNotifier extends AutoDisposeNotifier<OtApprovalsState> {
  bool _disposed = false;

  /// Loads started per list; an answer to an older one is dropped.
  int _pendingLoads = 0;
  int _decidedLoads = 0;

  @override
  OtApprovalsState build() {
    // Another login starts from nothing.
    final employeeId = ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user?.employeeId),
    );
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Not before the session says who is signed in: the lists depend on it
    // (and the Approvals place needs a staff record anyway).
    if (employeeId != null && employeeId.isNotEmpty) {
      Future.microtask(refresh);
    }
    return OtApprovalsState(employeeId: employeeId);
  }

  /// Both lists from their first page: pull to refresh. Rows already shown
  /// stay while they load; a failure is returned for the tab to say.
  Future<Failure?> refresh() async {
    await Future.wait([_loadFirst(_pendingList), _loadFirst(_decidedList)]);
    for (final list in [state.pending, state.decided]) {
      final error = list.error;
      if (error is Failure) return error;
    }
    return null;
  }

  /// The "decided by me" chip: that list from its first page.
  void selectDecided(OtApprovalStatus status) {
    if (status == state.decidedFilter || status == OtApprovalStatus.pending) {
      return;
    }
    state = state.copyWith(
      decidedFilter: status,
      decided: const AsyncValue.loading(),
    );
    _loadFirst(_decidedList);
  }

  /// Takes request [id] out of the waiting list at once: decided (#49).
  /// The reload after it says the rest.
  void dropWaiting(String id) {
    final list = state.pending.valueOrNull;
    if (_disposed || list == null) return;
    state = state.copyWith(
      pending: AsyncValue.data(
        list.withItems([
          for (final r in list.items)
            if (r.id != id) r,
        ]),
      ),
    );
  }

  Future<void> retryPending() => _loadFirst(_pendingList);
  Future<void> retryDecided() => _loadFirst(_decidedList);
  Future<void> loadMorePending() => _loadMore(_pendingList);
  Future<void> loadMoreDecided() => _loadMore(_decidedList);
  Future<void> retryLoadMorePending() => _retryLoadMore(_pendingList);
  Future<void> retryLoadMoreDecided() => _retryLoadMore(_decidedList);

  late final _OtList _pendingList = _OtList(
    status: () => OtApprovalStatus.pending,
    read: () => state.pending,
    write: (value) => state = state.copyWith(pending: value),
    nextLoad: () => ++_pendingLoads,
    currentLoad: () => _pendingLoads,
  );

  late final _OtList _decidedList = _OtList(
    status: () => state.decidedFilter,
    read: () => state.decided,
    write: (value) => state = state.copyWith(decided: value),
    nextLoad: () => ++_decidedLoads,
    currentLoad: () => _decidedLoads,
  );

  Future<void> _loadFirst(_OtList list) async {
    final load = list.nextLoad();
    final shown = list.read().valueOrNull;
    list.write(
      const AsyncLoading<PagedList<OtRequest>>().copyWithPrevious(list.read()),
    );
    final status = list.status();
    final result = await _fetch(status, 1);
    if (_disposed || load != list.currentLoad()) return;

    result.fold(
      // A failure keeps the rows shown, ready to load more again (a next
      // page that was on its way was dropped).
      (failure) => list.write(
        AsyncValue<PagedList<OtRequest>>.error(
          failure,
          StackTrace.current,
        ).copyWithPrevious(
          shown == null ? list.read() : AsyncValue.data(shown.retryable),
        ),
      ),
      (page) => list.write(
        AsyncValue.data(
          PagedList.firstNumbered(
            items: page.items,
            page: page.page,
            totalPages: page.totalPages,
            keyOf: _id,
          ),
        ),
      ),
    );
    if (result.isSuccess) await _fillUp(list, status, result.dataOrNull!);
  }

  Future<void> _loadMore(_OtList list) async {
    final value = list.read();
    final current = value.valueOrNull;
    final next = current?.nextPage;
    if (current == null ||
        next == null ||
        !current.canLoadMore ||
        value.isLoading) {
      return;
    }
    final load = list.currentLoad();
    final status = list.status();
    list.write(AsyncValue.data(current.startLoadingMore()));

    final result = await _fetch(status, next);
    if (_disposed || load != list.currentLoad()) return;
    final now = list.read().valueOrNull ?? current;
    list.write(
      AsyncValue.data(
        result.fold(
          now.failLoadingMore,
          (page) => now.appendNumbered(
            items: page.items,
            page: page.page,
            totalPages: page.totalPages,
            keyOf: _id,
          ),
        ),
      ),
    );
    if (result.isSuccess) await _fillUp(list, status, result.dataOrNull!);
  }

  /// A page that left fewer rows than a page once HR steps are hidden asks
  /// for the next one at once (the spinner still showing), so the list is
  /// never "empty" while more pages exist.
  Future<void> _fillUp(
    _OtList list,
    OtApprovalStatus status,
    OtPage<OtRequest> page,
  ) async {
    final shown = page.items
        .where((r) => OtApprovalsState.keeps(r, status, state.employeeId))
        .length;
    if (shown >= OtPage.defaultPerPage) return;
    await _loadMore(list);
  }

  Future<void> _retryLoadMore(_OtList list) async {
    final current = list.read().valueOrNull;
    if (current == null || current.loadMoreError == null) return;
    list.write(AsyncValue.data(current.retryable));
    await _loadMore(list);
  }

  static Object _id(OtRequest request) => request.id;

  Future<Result<OtPage<OtRequest>>> _fetch(OtApprovalStatus status, int page) =>
      ref.read(getOtApprovalsUseCaseProvider)(status, page: page);
}

/// One of the tab's two lists: the status it asks for, where it lives in
/// the state, and its load count.
class _OtList {
  final OtApprovalStatus Function() status;
  final AsyncValue<PagedList<OtRequest>> Function() read;
  final void Function(AsyncValue<PagedList<OtRequest>> value) write;
  final int Function() nextLoad;
  final int Function() currentLoad;

  _OtList({
    required this.status,
    required this.read,
    required this.write,
    required this.nextLoad,
    required this.currentLoad,
  });
}

final otApprovalsNotifierProvider =
    NotifierProvider.autoDispose<OtApprovalsNotifier, OtApprovalsState>(
      OtApprovalsNotifier.new,
    );
