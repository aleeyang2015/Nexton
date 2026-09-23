import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../time_off/presentation/services/attachment_picker.dart';
import '../../domain/entities/time_correction_type.dart';
import '../../domain/entities/work_shift.dart';
import 'time_correction_form_state.dart';

/// Why a picked attachment was turned away.
enum TimeCorrectionAttachmentError { tooLarge }

/// Fields and rules of the time-correction request form ("ລືມລົງເວລາ").
///
/// There is no shift or time-correction endpoint yet, so [build] seeds the
/// standard shift as a placeholder and the page doesn't submit anywhere —
/// swap both for real use cases once the API exists.
class TimeCorrectionFormNotifier
    extends AutoDisposeNotifier<TimeCorrectionFormState> {
  /// File types the correction form accepts, per the design: images and PDF.
  static const attachmentExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  static const _placeholderShift = WorkShift(
    id: 'standard',
    code: 'Shift A',
    name: 'ກະປົກກະຕິ (Standard Shift)',
    blocks: ['08:00 - 12:00', '13:00 - 17:00'],
  );

  @override
  TimeCorrectionFormState build() {
    final now = DateTime.now();
    return TimeCorrectionFormState(
      date: DateTime(now.year, now.month, now.day),
      shift: _placeholderShift,
    );
  }

  void setDate(DateTime date) =>
      state = state.copyWith(date: DateTime(date.year, date.month, date.day));

  void setType(TimeCorrectionType type) => state = state.copyWith(type: type);

  void setClockIn(TimeOfDay time) => state = state.copyWith(clockIn: time);

  void setClockOut(TimeOfDay time) => state = state.copyWith(clockOut: time);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// Opens the file chooser and keeps the pick. Returns an error when the
  /// file is over the size limit (and the previous pick is kept), null
  /// otherwise — including a back-out.
  Future<TimeCorrectionAttachmentError?> pickAttachment() async {
    final picked = await ref
        .read(attachmentPickerProvider)
        .pickAttachment(extensions: attachmentExtensions);
    if (picked == null) return null;

    final bytes = await File(picked.path).length();
    if (bytes > TimeCorrectionFormState.attachmentMaxBytes) {
      return TimeCorrectionAttachmentError.tooLarge;
    }
    state = state.copyWith(attachment: picked, attachmentBytes: bytes);
    return null;
  }

  void clearAttachment() =>
      state = state.copyWith(attachment: null, attachmentBytes: null);
}

final timeCorrectionFormNotifierProvider =
    NotifierProvider.autoDispose<
      TimeCorrectionFormNotifier,
      TimeCorrectionFormState
    >(TimeCorrectionFormNotifier.new);
