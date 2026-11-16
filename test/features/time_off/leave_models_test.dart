import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/data/models/leave_attachment_model.dart';
import 'package:next_on/features/time_off/data/models/leave_request_model.dart';
import 'package:next_on/features/time_off/data/models/leave_type_model.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';

/// A `LeaveRequestResponse` as the App reads it today.
Map<String, dynamic> _request({
  String status = 'pending',
  Object? steps,
  Object? attachments,
}) => {
  'id': 'req-1',
  'employee': {
    'name': 'Noy Phommachanh',
    'employee_number': 'EMP-001',
    'department': {'id': 'dep-1', 'name': 'Sales'},
  },
  'leave_type': {
    'id': 'lt-annual',
    'code': 'annual',
    'name': 'Annual Leave',
    'name_lo': 'ລາພັກປະຈຳປີ',
    'color': '#3386FF',
  },
  'start_date': '2026-11-18',
  'end_date': '2026-11-20',
  'request_days': ['2026-11-18', '2026-11-19', '2026-11-20'],
  'return_date': '2026-11-23',
  'total_days': 3,
  'duration_type': 'full_day',
  'reason': 'Family trip',
  'status': status,
  'current_step_no': 1,
  'steps':
      steps ??
      [
        {
          'id': 'step-1',
          'step_no': 1,
          'step_role': 'dept_head',
          'approver': {'name': 'Bounmy Sisavath'},
          'status': 'pending',
          'note': null,
        },
        {
          'id': 'step-2',
          'step_no': 2,
          'step_role': 'hr',
          'approver': null,
          'status': 'waiting',
        },
      ],
  'attachments':
      attachments ??
      [
        {
          'id': 'att-1',
          'url': 'https://files.nexton.work/a/medical.pdf',
          'file_name': 'tenants/x/uploads/1_medical.pdf',
          'original_name': 'medical.pdf',
          'content_type': 'application/pdf',
          'size': 20480,
        },
      ],
  'created_at': '2026-11-10T02:15:00Z',
};

void main() {
  group('LeaveRequestModel.fromJson', () {
    test('reads the request, its employee and its leave type', () {
      final request = LeaveRequestModel.fromJson(_request());

      expect(request.id, 'req-1');
      expect(request.employeeName, 'Noy Phommachanh');
      expect(request.employeeNumber, 'EMP-001');
      expect(request.departmentName, 'Sales');
      expect(request.leaveType.id, 'lt-annual');
      expect(request.leaveType.code, 'annual');
      expect(request.leaveType.name, 'Annual Leave');
      expect(request.leaveType.nameLo, 'ລາພັກປະຈຳປີ');
      expect(request.leaveType.color, '#3386FF');
      expect(request.reason, 'Family trip');
      expect(request.totalDays, 3);
      expect(request.durationType, LeaveDurationType.fullDay);
      expect(request.currentStepNo, 1);
    });

    test('the department is employee.department.name; null when the employee '
        'has none', () {
      final none = _request()
        ..['employee'] = {'name': 'Noy Phommachanh', 'department': null};
      final flat = _request()
        ..['employee'] = {
          'name': 'Noy Phommachanh',
          'department_name': 'Sales',
        };

      expect(LeaveRequestModel.fromJson(_request()).departmentName, 'Sales');
      expect(LeaveRequestModel.fromJson(none).departmentName, isNull);
      // `department_name` is not a key the backend sends.
      expect(LeaveRequestModel.fromJson(flat).departmentName, isNull);
    });

    test('the request\'s own leave type has no Lao name', () {
      final json = _request();
      (json['leave_type'] as Map).remove('name_lo');

      expect(LeaveRequestModel.fromJson(json).leaveType.nameLo, isNull);
    });

    test('reads request_days and return_date as calendar days', () {
      final request = LeaveRequestModel.fromJson(_request());

      expect(request.requestDays, [
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 20),
      ]);
      expect(request.startDate, DateTime(2026, 11, 18));
      expect(request.endDate, DateTime(2026, 11, 20));
      expect(request.returnDate, DateTime(2026, 11, 23));
    });

    // This can only catch a zone shift on a machine that is not on UTC, where
    // "local" and UTC are different days for these times.
    test('a date sent with a time is still that calendar day, with no zone '
        'shift', () {
      final json = _request()
        ..['start_date'] = '2026-11-18T00:00:00Z'
        ..['return_date'] = '2026-11-23T17:00:00Z';

      final request = LeaveRequestModel.fromJson(json);

      expect(request.startDate, DateTime(2026, 11, 18));
      expect(request.returnDate, DateTime(2026, 11, 23));
    });

    test('created_at is an instant: UTC in, local out', () {
      final request = LeaveRequestModel.fromJson(_request());

      expect(request.createdAt!.toUtc(), DateTime.utc(2026, 11, 10, 2, 15));
      expect(request.createdAt!.isUtc, isFalse);
    });

    test('reads steps[] in the order sent, with id, number, role, approver, '
        'status and note', () {
      final request = LeaveRequestModel.fromJson(
        _request(
          steps: [
            {
              'id': 'step-1',
              'step_no': 1,
              'step_role': 'dept_head',
              'approver': {'name': 'Bounmy Sisavath'},
              'status': 'approved',
              'note': 'ok',
            },
            {
              'id': 'step-2',
              'step_no': 2,
              'step_role': 'hr',
              'approver': {'name': 'Mai Vongsa'},
              'status': 'rejected',
              'note': 'No cover that week',
            },
          ],
        ),
      );

      expect(request.steps, const [
        LeaveApprovalStep(
          id: 'step-1',
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          approverName: 'Bounmy Sisavath',
          status: LeaveStepStatus.approved,
          note: 'ok',
        ),
        LeaveApprovalStep(
          id: 'step-2',
          stepNo: 2,
          role: LeaveStepRole.hr,
          approverName: 'Mai Vongsa',
          status: LeaveStepStatus.rejected,
          note: 'No cover that week',
        ),
      ]);
    });

    test('reads employee.id as who asked for the leave', () {
      final json = _request();
      (json['employee'] as Map<String, dynamic>)['id'] = 'emp-noy';

      expect(LeaveRequestModel.fromJson(json).employeeId, 'emp-noy');
    });

    test('no employee.id, an empty one, or no employee at all: no requester',
        () {
      expect(LeaveRequestModel.fromJson(_request()).employeeId, isNull);

      final empty = _request();
      (empty['employee'] as Map<String, dynamic>)['id'] = '';
      expect(LeaveRequestModel.fromJson(empty).employeeId, isNull);

      final none = _request()..remove('employee');
      expect(LeaveRequestModel.fromJson(none).employeeId, isNull);
    });

    test('a decided step reads updated_at as when it was decided, in local '
        'time', () {
      final request = LeaveRequestModel.fromJson(
        _request(
          status: 'rejected',
          steps: [
            {
              'id': 'step-1',
              'step_no': 1,
              'step_role': 'dept_head',
              'approver': {'name': 'Bounmy Sisavath'},
              'status': 'approved',
              'updated_at': '2026-11-12T07:05:00Z',
            },
            {
              'id': 'step-2',
              'step_no': 2,
              'step_role': 'hr',
              // HR with no staff record decided it: no approver is saved.
              'approver': null,
              'status': 'rejected',
              'updated_at': '2026-11-13T02:30:00Z',
            },
          ],
        ),
      );

      final decided = DateTime.utc(2026, 11, 12, 7, 5).toLocal();
      expect(request.steps[0].decidedAt, decided);
      expect(request.steps[0].decidedAt!.isUtc, isFalse);
      expect(request.steps[0].isDecided, isTrue);
      expect(
        request.steps[1].decidedAt,
        DateTime.utc(2026, 11, 13, 2, 30).toLocal(),
      );
      expect(request.steps[1].approverName, isNull);
    });

    test('a step not decided yet has no decision time, whatever its '
        'updated_at says', () {
      final request = LeaveRequestModel.fromJson(
        _request(
          steps: [
            {
              'id': 'step-1',
              'step_no': 1,
              'step_role': 'dept_head',
              'status': 'pending',
              'updated_at': '2026-11-12T07:05:00Z',
            },
            {
              'id': 'step-2',
              'step_no': 2,
              'step_role': 'hr',
              'status': 'waiting',
              'updated_at': '2026-11-12T07:05:00Z',
            },
          ],
        ),
      );

      expect(request.steps[0].decidedAt, isNull);
      expect(request.steps[0].isDecided, isFalse);
      expect(request.steps[1].decidedAt, isNull);
    });

    test('a decided step with no updated_at, or one that is not a time, has '
        'no decision time', () {
      final request = LeaveRequestModel.fromJson(
        _request(
          steps: [
            {'step_no': 1, 'step_role': 'dept_head', 'status': 'approved'},
            {
              'step_no': 2,
              'step_role': 'hr',
              'status': 'approved',
              'updated_at': 'yesterday',
            },
          ],
        ),
      );

      expect(request.steps[0].decidedAt, isNull);
      expect(request.steps[1].decidedAt, isNull);
    });

    test('a step with "approver": null gives a null name', () {
      final request = LeaveRequestModel.fromJson(_request());

      expect(request.steps[0].approverName, 'Bounmy Sisavath');
      expect(request.steps[1].approverName, isNull);
    });

    test('every step status and role is read; an unknown one falls back', () {
      Map<String, dynamic> step(String role, String status) => {
        'step_no': 1,
        'step_role': role,
        'status': status,
      };
      final request = LeaveRequestModel.fromJson(
        _request(
          steps: [
            step('dept_head', 'waiting'),
            step('hr', 'pending'),
            step('hr', 'approved'),
            step('hr', 'rejected'),
            step('team_lead', 'skipped'),
          ],
        ),
      );

      expect(request.steps.map((s) => s.status), [
        LeaveStepStatus.waiting,
        LeaveStepStatus.pending,
        LeaveStepStatus.approved,
        LeaveStepStatus.rejected,
        // Today an unknown status reads as "waiting".
        LeaveStepStatus.waiting,
      ]);
      expect(request.steps.first.role, LeaveStepRole.deptHead);
      expect(request.steps[1].role, LeaveStepRole.hr);
      // And an unknown role as "unknown".
      expect(request.steps.last.role, LeaveStepRole.unknown);
    });

    test('reads attachments[]', () {
      final attachment = LeaveRequestModel.fromJson(
        _request(),
      ).attachments.single;

      expect(attachment.id, 'att-1');
      expect(attachment.url, 'https://files.nexton.work/a/medical.pdf');
      expect(attachment.fileName, 'tenants/x/uploads/1_medical.pdf');
      expect(attachment.contentType, 'application/pdf');
      expect(attachment.size, 20480);
    });

    test('an attachment with no url is dropped', () {
      final request = LeaveRequestModel.fromJson(
        _request(
          attachments: [
            {'id': 'att-1', 'file_name': 'lost.pdf'},
            {'id': 'att-2', 'url': '', 'file_name': 'empty.pdf'},
            {'id': 'att-3', 'url': 'https://files.nexton.work/a/kept.pdf'},
          ],
        ),
      );

      expect(request.attachments.single.id, 'att-3');
    });

    test('every request status is read; an unknown one reads as pending', () {
      LeaveStatus statusOf(String wire) =>
          LeaveRequestModel.fromJson(_request(status: wire)).status;

      expect(statusOf('pending'), LeaveStatus.pending);
      expect(statusOf('approved'), LeaveStatus.approved);
      expect(statusOf('rejected'), LeaveStatus.rejected);
      expect(statusOf('cancelled'), LeaveStatus.cancelled);
      expect(statusOf('something_new'), LeaveStatus.pending);
    });

    test('every duration type is read; an unknown one reads as a full day', () {
      LeaveDurationType durationOf(String wire) => LeaveRequestModel.fromJson(
        _request()..['duration_type'] = wire,
      ).durationType;

      expect(durationOf('full_day'), LeaveDurationType.fullDay);
      expect(durationOf('first_half'), LeaveDurationType.firstHalf);
      expect(durationOf('second_half'), LeaveDurationType.secondHalf);
      expect(durationOf('quarter'), LeaveDurationType.fullDay);
    });

    test('a bare record reads without throwing: empty lists and defaults', () {
      final request = LeaveRequestModel.fromJson({
        'id': 'req-9',
        'start_date': '2026-11-18',
        'status': 'approved',
      });

      expect(request.id, 'req-9');
      expect(request.employeeName, '');
      expect(request.leaveType.id, '');
      // The end falls back to the start.
      expect(request.endDate, DateTime(2026, 11, 18));
      expect(request.requestDays, isEmpty);
      expect(request.returnDate, isNull);
      expect(request.totalDays, 0);
      expect(request.steps, isEmpty);
      expect(request.attachments, isEmpty);
      expect(request.currentStepNo, isNull);
    });
  });

  group('LeaveAttachmentModel.fromJson', () {
    test('the shown name is file_name, else original_name, else the url', () {
      const url = 'https://files.nexton.work/a/x.pdf';

      expect(
        LeaveAttachmentModel.fromJson({
          'url': url,
          'file_name': 'stored.pdf',
          'original_name': 'mine.pdf',
        })!.fileName,
        'stored.pdf',
      );
      expect(
        LeaveAttachmentModel.fromJson({
          'url': url,
          'original_name': 'mine.pdf',
        })!.fileName,
        'mine.pdf',
      );
      expect(LeaveAttachmentModel.fromJson({'url': url})!.fileName, url);
    });

    test('is null with no url', () {
      expect(LeaveAttachmentModel.fromJson({'file_name': 'x.pdf'}), isNull);
    });
  });

  group('LeaveTypeModel.fromJson', () {
    test('reads the names, the limits and the flags', () {
      final type = LeaveTypeModel.fromJson({
        'id': 'lt-sick',
        'code': 'sick',
        'name': 'Sick Leave',
        'name_lo': 'ລາປ່ວຍ',
        'color': '#F44336',
        'is_active': false,
        'max_days_per_request': 2.5,
        'max_consecutive_days': 3,
        'min_notice_days': 0,
        'allow_half_day': true,
        'requires_attachment': true,
        'allow_negative_balance': true,
        'is_paid': false,
      });

      expect(type.id, 'lt-sick');
      expect(type.code, 'sick');
      expect(type.name, 'Sick Leave');
      expect(type.nameLo, 'ລາປ່ວຍ');
      expect(type.color, '#F44336');
      expect(type.isActive, isFalse);
      // A decimal on the wire: a type can allow two and a half days.
      expect(type.maxDaysPerRequest, 2.5);
      expect(type.maxConsecutiveDays, 3.0);
      expect(type.minNoticeDays, 0);
      expect(type.allowHalfDay, isTrue);
      expect(type.requiresAttachment, isTrue);
      expect(type.allowNegativeBalance, isTrue);
      expect(type.isPaid, isFalse);
    });

    test('missing flags default to off, except is_paid, which defaults to '
        'paid', () {
      final type = LeaveTypeModel.fromJson({
        'id': 'lt-annual',
        'code': 'annual',
        'name': 'Annual Leave',
      });

      expect(type.allowHalfDay, isFalse);
      expect(type.requiresAttachment, isFalse);
      expect(type.allowNegativeBalance, isFalse);
      expect(type.isPaid, isTrue);
      // A list with no is_active reads as switched on.
      expect(type.isActive, isTrue);
      expect(type.nameLo, isNull);
      expect(type.maxDaysPerRequest, isNull);
    });
  });
}
