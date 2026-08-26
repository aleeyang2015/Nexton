import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/leave_category.dart';

part 'leave_request_form_state.freezed.dart';

/// The request-leave form's fields and submit status.
///
/// Leave days are picked individually (not a start/end range) via
/// [dates] — mirroring the "select specific leave dates" list the form
/// shows, each removable on its own. The return-to-work date defaults to
/// the day after the latest selected date until the user overrides it.
@freezed
class LeaveRequestFormState with _$LeaveRequestFormState {
  const LeaveRequestFormState._();

  const factory LeaveRequestFormState({
    @Default(LeaveCategory.annual) LeaveCategory category,
    @Default(<DateTime>[]) List<DateTime> dates,
    DateTime? returnToWorkOverride,
    @Default('') String reason,
    @Default(AsyncValue<Unit>.data(Unit.instance))
    AsyncValue<Unit> submission,
  }) = _LeaveRequestFormState;

  int get totalDays => dates.length;

  DateTime? get returnToWorkDate {
    if (returnToWorkOverride != null) return returnToWorkOverride;
    if (dates.isEmpty) return null;
    return dates.last.add(const Duration(days: 1));
  }

  bool get canSubmit =>
      dates.isNotEmpty && returnToWorkDate != null && !submission.isLoading;
}
