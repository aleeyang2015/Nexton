/// OT answers as the server sends them (`corehr/attendance`), built from
/// the field tables of issue #27 with the real time formats: RFC 3339 with
/// `+07:00` for `starts_at`, `ends_at`, piece times and `join_deadline`;
/// `"YYYY-MM-DD HH:MM:SS"` with no zone for `created_at`, `updated_at`,
/// `acted_at` and `paid_by_hand_at`.
library;

/// Noy's OT on Saturday 14 November 18:00–20:00: asked, approved by her
/// head, waiting for HR. Every field present.
Map<String, dynamic> otRequestJson() => {
  'id': 'ot-1',
  'employee_id': 'emp-noy',
  'employee': {
    'id': 'emp-noy',
    'name': 'Noy Phommachanh',
    'employee_number': 'EMP-014',
  },
  'announcement_id': null,
  'work_date': '2026-11-14',
  'start_time': '18:00',
  'end_time': '20:00',
  'ends_next_day': false,
  'starts_at': '2026-11-14T18:00:00+07:00',
  'ends_at': '2026-11-14T20:00:00+07:00',
  'reason': 'Wedding dinner for 120 guests',
  'agreement_note': null,
  'status': 'pending',
  'current_step_no': 2,
  'hr_only': false,
  'did_not_come': false,
  'paid_by_hand_at': null,
  'paid_by_hand_by': null,
  'created_at': '2026-11-11 09:30:00',
  'updated_at': '2026-11-11 14:05:00',
  'steps': [
    {
      'id': 'step-1',
      'step_no': 1,
      'step_role': 'dept_head',
      'approver': {'id': 'u-head', 'name': 'Somchai K.'},
      'status': 'approved',
      'note': 'OK',
      'acted_at': '2026-11-11 14:05:00',
      'created_at': '2026-11-11 09:30:00',
    },
    {
      'id': 'step-2',
      'step_no': 2,
      'step_role': 'hr',
      'approver': null,
      'status': 'pending',
      'note': null,
      'acted_at': null,
      'created_at': '2026-11-11 09:30:00',
    },
  ],
  'pieces': <Object>[],
};

/// The same OT once HR approved it: two pieces, one each side of 19:00.
Map<String, dynamic> approvedOtRequestJson() => {
  ...otRequestJson(),
  'status': 'approved',
  'steps': [
    for (final step in otRequestJson()['steps'] as List)
      {...(step as Map<String, dynamic>), 'status': 'approved'},
  ],
  'pieces': [
    {
      'id': 'piece-1',
      'piece_no': 1,
      'starts_at': '2026-11-14T18:00:00+07:00',
      'ends_at': '2026-11-14T19:00:00+07:00',
      'pay_type': 'percent',
      'pay_value': 150,
    },
    {
      'id': 'piece-2',
      'piece_no': 2,
      'starts_at': '2026-11-14T19:00:00+07:00',
      'ends_at': '2026-11-14T20:00:00+07:00',
      'pay_type': 'fixed_per_hour',
      'pay_value': 20000,
    },
  ],
};

/// HR's open post for the kitchen: Saturday 21 November 22:00 to 02:00 the
/// next day, 3 seats, join by Friday 20 November 17:00.
Map<String, dynamic> otPostJson() => {
  'id': 'post-1',
  'department_id': 'dep-kitchen',
  'department_name': 'Kitchen',
  'work_date': '2026-11-21',
  'start_time': '22:00',
  'end_time': '02:00',
  'ends_next_day': true,
  'starts_at': '2026-11-21T22:00:00+07:00',
  'ends_at': '2026-11-22T02:00:00+07:00',
  'seats': 3,
  'join_deadline': '2026-11-20T17:00:00+07:00',
  'reason': 'Night banquet',
  'status': 'open',
  'accepted': 1,
  'waiting': 1,
  'created_at': '2026-11-12 08:00:00',
  'updated_at': '2026-11-12 08:00:00',
  'pieces': [
    {
      'id': 'post-piece-1',
      'piece_no': 1,
      'starts_at': '2026-11-21T22:00:00+07:00',
      'ends_at': '2026-11-22T02:00:00+07:00',
      'pay_type': 'percent',
      'pay_value': 200,
    },
  ],
  'full': false,
  'join_open': true,
  'my_join': null,
};
