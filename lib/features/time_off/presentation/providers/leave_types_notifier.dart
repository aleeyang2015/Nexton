import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_type.dart';
import '../../time_off_providers.dart';

/// The leave-type list (`GET /leave/types`) shared by the history filter and
/// the request form. Cached for the session — the list rarely changes.
class LeaveTypesNotifier extends AutoDisposeAsyncNotifier<List<LeaveType>> {
  bool _disposed = false;

  @override
  Future<List<LeaveType>> build() {
    ref.onDispose(() => _disposed = true);
    return _load();
  }

  /// Asks for the list again and takes it only if it comes: a failed try
  /// leaves the list on screen as it is, so a form in use never loses its
  /// leave types to a weak signal. For a reload nobody asked for by hand
  /// (the server said a type is switched off or gone).
  Future<void> reloadKeepingList() async {
    final result = await ref.read(getLeaveTypesUseCaseProvider)();
    if (_disposed) return;
    result.fold((_) {}, (types) => state = AsyncValue.data(types));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<LeaveType>> _load() async {
    final result = await ref.read(getLeaveTypesUseCaseProvider)();
    return result.fold((failure) => throw failure, (types) => types);
  }
}

final leaveTypesNotifierProvider =
    AsyncNotifierProvider.autoDispose<LeaveTypesNotifier, List<LeaveType>>(
      LeaveTypesNotifier.new,
    );
