import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_type.dart';
import '../../time_off_providers.dart';

/// The leave-type list (`GET /leave/types`) shared by the history filter and
/// the request form. Cached for the session — the list rarely changes.
class LeaveTypesNotifier extends AsyncNotifier<List<LeaveType>> {
  @override
  Future<List<LeaveType>> build() => _load();

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
    AsyncNotifierProvider<LeaveTypesNotifier, List<LeaveType>>(
      LeaveTypesNotifier.new,
    );
