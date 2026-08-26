import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_summary.dart';
import '../../time_off_providers.dart';

/// The annual summary tab's entitlement/used/remaining rollup for the
/// current year.
class LeaveSummaryNotifier extends AsyncNotifier<LeaveSummary> {
  @override
  Future<LeaveSummary> build() => _load();

  /// Re-runs the fetch, e.g. after the user retries a failed load.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<LeaveSummary> _load() async {
    final result = await ref.read(
      getLeaveSummaryUseCaseProvider,
    )(DateTime.now().year);
    return result.fold((failure) => throw failure, (summary) => summary);
  }
}

final leaveSummaryNotifierProvider =
    AsyncNotifierProvider<LeaveSummaryNotifier, LeaveSummary>(
      LeaveSummaryNotifier.new,
    );
