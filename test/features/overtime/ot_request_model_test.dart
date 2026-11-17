import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/ot_pay_type.dart';
import 'package:next_on/features/overtime/data/models/ot_request_model.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';

import '../../support/overtime_json.dart';

/// An OT request (`OTRequestResponse`), read exactly as the server sends
/// it: the same shape from the list, the detail, ask, edit, join, approve,
/// reject and cancel.
void main() {
  OtRequest read(Map<String, dynamic> json) => OtRequestModel.fromJson(json);

  group('a full request', () {
    test('reads every field shown or used', () {
      final ot = read(otRequestJson());

      expect(ot.id, 'ot-1');
      expect(ot.employeeId, 'emp-noy');
      expect(ot.employeeName, 'Noy Phommachanh');
      expect(ot.employeeNumber, 'EMP-014');
      expect(ot.announcementId, isNull);
      expect(ot.workDate, DateTime(2026, 11, 14));
      expect(ot.startTime, '18:00');
      expect(ot.endTime, '20:00');
      expect(ot.endsNextDay, isFalse);
      expect(ot.reason, 'Wedding dinner for 120 guests');
      expect(ot.agreementNote, isNull);
      expect(ot.status, OtStatus.pending);
      expect(ot.currentStepNo, 2);
      expect(ot.hrOnly, isFalse);
      expect(ot.didNotCome, isFalse);
      expect(ot.paidByHandAt, isNull);
      expect(ot.steps, hasLength(2));
      expect(ot.pieces, isEmpty);
    });

    test('starts_at and ends_at are the moments sent, in +07:00', () {
      final ot = read(otRequestJson());

      expect(ot.startsAt!.toUtc(), DateTime.utc(2026, 11, 14, 11));
      expect(ot.endsAt!.toUtc(), DateTime.utc(2026, 11, 14, 13));
    });

    test('created_at "2026-11-11 09:30:00" is 09:30 on the phone\'s clock, '
        'not 16:30 or 02:30', () {
      final ot = read(otRequestJson());

      expect(ot.createdAt, DateTime(2026, 11, 11, 9, 30));
      expect(ot.createdAt!.isUtc, isFalse);
      expect(ot.updatedAt, DateTime(2026, 11, 11, 14, 5));
    });

    test('the steps: role, approver, status, note and when it was decided',
        () {
      final [head, hr] = read(otRequestJson()).steps;

      expect(head.id, 'step-1');
      expect(head.stepNo, 1);
      expect(head.role, OtStepRole.deptHead);
      expect(head.approverId, 'u-head');
      expect(head.approverName, 'Somchai K.');
      expect(head.status, OtStepStatus.approved);
      expect(head.note, 'OK');
      expect(head.actedAt, DateTime(2026, 11, 11, 14, 5));
      expect(head.createdAt, DateTime(2026, 11, 11, 9, 30));

      expect(hr.role, OtStepRole.hr);
      expect(hr.status, OtStepStatus.pending);
      expect(hr.approverId, isNull);
      expect(hr.approverName, isNull);
      expect(hr.actedAt, isNull);
    });

    test('once approved: the pieces, with their pay', () {
      final ot = read(approvedOtRequestJson());

      expect(ot.status, OtStatus.approved);
      final [first, second] = ot.pieces;
      expect(first.id, 'piece-1');
      expect(first.pieceNo, 1);
      expect(first.startsAt!.toUtc(), DateTime.utc(2026, 11, 14, 11));
      expect(first.endsAt!.toUtc(), DateTime.utc(2026, 11, 14, 12));
      expect(first.payType, OtPayType.percent);
      expect(first.payValue, 150);
      expect(second.payType, OtPayType.fixedPerHour);
      expect(second.payValue, 20000);
    });

    test('joined an HR post: announcement_id is kept', () {
      final ot = read({...otRequestJson(), 'announcement_id': 'post-1'});

      expect(ot.announcementId, 'post-1');
    });

    test('paid by hand: the wall-clock time, and never who paid', () {
      final ot = read({
        ...otRequestJson(),
        'paid_by_hand_at': '2026-11-15 10:00:00',
        'paid_by_hand_by': 'u-hr',
      });

      expect(ot.paidByHandAt, DateTime(2026, 11, 15, 10));
    });

    test('an OT past midnight keeps its own day and end time', () {
      final ot = read({
        ...otRequestJson(),
        'work_date': '2026-11-21',
        'start_time': '22:00',
        'end_time': '02:00',
        'ends_next_day': true,
      });

      expect(ot.workDate, DateTime(2026, 11, 21));
      expect(ot.endTime, '02:00');
      expect(ot.endsNextDay, isTrue);
    });
  });

  group('what the server leaves out, or sends oddly', () {
    test('approver null, employee without name or number, pieces empty', () {
      final ot = read({
        ...otRequestJson(),
        'employee': {'id': 'emp-noy'},
      });

      expect(ot.employeeName, isNull);
      expect(ot.employeeNumber, isNull);
      expect(ot.steps.last.approverName, isNull);
      expect(ot.pieces, isEmpty);
    });

    test('no employee object at all', () {
      final json = otRequestJson()..remove('employee');

      expect(read(json).employeeName, isNull);
    });

    test('an unknown status, role or step status is unknown, not a guess',
        () {
      final ot = read({
        ...otRequestJson(),
        'status': 'on_hold',
        'steps': [
          {
            'id': 's',
            'step_no': 1,
            'step_role': 'ceo',
            'status': 'paused',
          },
        ],
      });

      expect(ot.status, OtStatus.unknown);
      expect(ot.steps.single.role, OtStepRole.unknown);
      expect(ot.steps.single.status, OtStepStatus.unknown);
    });

    test('an unknown pay type is unknown, its value kept', () {
      final ot = read({
        ...otRequestJson(),
        'pieces': [
          {'id': 'p', 'piece_no': 1, 'pay_type': 'per_piece', 'pay_value': 7},
        ],
      });

      expect(ot.pieces.single.payType, OtPayType.unknown);
      expect(ot.pieces.single.payValue, 7);
    });

    test('a cancel answer with an extra warnings key is an OT request', () {
      final ot = read({
        ...otRequestJson(),
        'status': 'cancelled',
        'warnings': ['OT_ALREADY_PAID'],
      });

      expect(ot.status, OtStatus.cancelled);
      expect(ot.id, 'ot-1');
    });

    test('fields of the wrong type do not crash the read', () {
      final ot = read({
        ...otRequestJson(),
        'employee': 'Noy',
        'work_date': 14,
        'start_time': 1800,
        'ends_next_day': 'no',
        'starts_at': 'soon',
        'current_step_no': '2',
        'hr_only': 1,
        'created_at': 20261111,
        'steps': 'none',
        'pieces': [
          'x',
          {'id': 'p', 'piece_no': 'one', 'pay_value': '150'},
        ],
      });

      expect(ot.id, 'ot-1');
      expect(ot.employeeName, isNull);
      expect(ot.workDate, isNull);
      expect(ot.startTime, '');
      expect(ot.endsNextDay, isFalse);
      expect(ot.startsAt, isNull);
      expect(ot.currentStepNo, 0);
      expect(ot.hrOnly, isFalse);
      expect(ot.createdAt, isNull);
      expect(ot.steps, isEmpty);
      expect(ot.pieces.single.pieceNo, 0);
      // Not a whole number: no rate, never a made-up 0.
      expect(ot.pieces.single.payValue, isNull);
    });

    test('an empty employee_id falls back to employee.id', () {
      final ot = read({...otRequestJson(), 'employee_id': ''});

      expect(ot.employeeId, 'emp-noy');
    });

    test('an impossible work_date or created_at is null, not another day',
        () {
      final ot = read({
        ...otRequestJson(),
        'work_date': '2026-02-30',
        'created_at': '2026-11-11 25:99:00',
      });

      expect(ot.workDate, isNull);
      expect(ot.createdAt, isNull);
    });

    test('tryFromJson: a row with no id is null, for a list to skip', () {
      expect(OtRequestModel.tryFromJson(otRequestJson()), isNotNull);
      expect(
        OtRequestModel.tryFromJson(otRequestJson()..remove('id')),
        isNull,
      );
    });

    test('a request with no id is refused: nothing could open it', () {
      final json = otRequestJson()..remove('id');

      expect(() => read(json), throwsFormatException);
      expect(() => read({...otRequestJson(), 'id': ''}), throwsFormatException);
    });
  });

  group('helpers', () {
    test('pendingStep is the step waiting for a decision now', () {
      expect(read(otRequestJson()).pendingStep?.id, 'step-2');
      expect(read(approvedOtRequestJson()).pendingStep, isNull);
    });

    test('hasApprovedStep: any step approved yet', () {
      expect(read(otRequestJson()).hasApprovedStep, isTrue);
      expect(
        read({
          ...otRequestJson(),
          'steps': [
            {'id': 's', 'step_no': 1, 'step_role': 'dept_head', 'status': 'pending'},
          ],
        }).hasApprovedStep,
        isFalse,
      );
    });
  });
}
