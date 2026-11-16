import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/validation_codes.dart';
import 'package:next_on/features/attendance/data/models/time_correction_request_model.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_request.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_type.dart';
import 'package:next_on/features/attendance/domain/usecases/submit_time_correction_usecase.dart';
import 'package:next_on/features/time_off/domain/entities/uploaded_attachment.dart';

import '../../support/attendance_test_doubles.dart';

void main() {
  final now = DateTime(2026, 9, 24, 10);

  TimeCorrectionRequest request({
    DateTime? date,
    TimeCorrectionType type = TimeCorrectionType.both,
    String? shiftDetailId = 'detail-1',
    Duration clockIn = const Duration(hours: 8),
    Duration clockOut = const Duration(hours: 12, minutes: 10),
    String reason = 'Forgot to scan out',
    UploadedAttachment? attachment,
  }) => TimeCorrectionRequest(
    date: date ?? DateTime(2026, 9, 18),
    type: type,
    shiftDetailId: shiftDetailId,
    clockIn: clockIn,
    clockOut: clockOut,
    reason: reason,
    attachment: attachment,
  );

  group('TimeCorrectionRequest.violations', () {
    test('a complete request passes', () {
      expect(request().violations(now: now), isEmpty);
      expect(request().validate(now: now).isSuccess, isTrue);
    });

    test('refuses a future date and one past the look-back window', () {
      expect(request(date: DateTime(2026, 9, 25)).violations(now: now), {
        TimeCorrectionFields.date: ValidationCode.correctionDateInFuture,
      });
      expect(request(date: DateTime(2026, 6, 25)).violations(now: now), {
        TimeCorrectionFields.date: ValidationCode.correctionDateTooOld,
      });
      // Today and exactly 90 days back are both allowed.
      expect(request(date: now).violations(now: now), isEmpty);
      expect(
        request(date: DateTime(2026, 6, 26)).violations(now: now),
        isEmpty,
      );
    });

    test('needs a shift segment', () {
      expect(request(shiftDetailId: null).violations(now: now), {
        TimeCorrectionFields.shift: ValidationCode.correctionShiftRequired,
      });
    });

    test('clock-out must follow clock-in only when both are sent', () {
      final reversed = request(
        clockIn: const Duration(hours: 17),
        clockOut: const Duration(hours: 8),
      );
      expect(reversed.violations(now: now), {
        TimeCorrectionFields.times: ValidationCode.correctionInvalidTimes,
      });

      final onlyIn = request(
        type: TimeCorrectionType.forgotClockIn,
        clockIn: const Duration(hours: 17),
        clockOut: const Duration(hours: 8),
      );
      expect(onlyIn.violations(now: now), isEmpty);
    });

    test('needs a non-blank reason within the length limit', () {
      expect(request(reason: '   ').violations(now: now), {
        TimeCorrectionFields.reason: ValidationCode.correctionReasonRequired,
      });
      expect(request(reason: 'x' * 201).violations(now: now), {
        TimeCorrectionFields.reason: ValidationCode.correctionReasonTooLong,
      });
    });
  });

  group('TimeCorrectionRequestModel.toJson', () {
    test('matches the documented body', () {
      final json = TimeCorrectionRequestModel(
        request(
          reason: '  late  ',
          attachment: const UploadedAttachment(
            url: 'http://minio/files/tenants/t/uploads/abc_scan.png',
            fileName: 'tenants/t/uploads/abc_scan.png',
            originalName: 'scan.png',
            contentType: 'image/png',
            size: 1007585,
          ),
        ),
      ).toJson();

      expect(json, {
        'request_date': '2026-09-18',
        'correction_type': 'both',
        'requested_clock_in': '08:00',
        'requested_clock_out': '12:10',
        'shift_detail_id': 'detail-1',
        'attachment_url': {
          'url': 'http://minio/files/tenants/t/uploads/abc_scan.png',
          'file_name': 'tenants/t/uploads/abc_scan.png',
          'original_name': 'scan.png',
          'content_type': 'image/png',
          'size': 1007585,
        },
        'reason': 'late',
      });
    });

    test('omits the time the type does not carry; no file is ""', () {
      final json = TimeCorrectionRequestModel(
        request(type: TimeCorrectionType.forgotClockOut),
      ).toJson();

      expect(json['correction_type'], 'missing_check_out');
      expect(json.containsKey('requested_clock_in'), isFalse);
      expect(json['requested_clock_out'], '12:10');
      expect(json['attachment_url'], '');
    });
  });

  test('the use case never sends an invalid request', () async {
    final repository = FakeAttendanceRepository();
    final result = await SubmitTimeCorrectionUseCase(repository)(
      request(reason: ''),
    );

    expect(result.isFailure, isTrue);
    expect(repository.timeCorrectionRequests, isEmpty);
  });
}
