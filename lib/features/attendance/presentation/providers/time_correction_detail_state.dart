import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/time_correction_detail.dart';

part 'time_correction_detail_state.freezed.dart';

/// The detail page's request, and which of its actions are in flight.
@freezed
class TimeCorrectionDetailState with _$TimeCorrectionDetailState {
  const factory TimeCorrectionDetailState({
    @Default(AsyncValue<TimeCorrectionDetail>.loading())
    AsyncValue<TimeCorrectionDetail> detail,
    @Default(false) bool cancelling,
    @Default(false) bool downloading,
  }) = _TimeCorrectionDetailState;
}
