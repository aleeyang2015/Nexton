import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/data/models/leave_draft_body.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request_draft.dart';
import 'package:next_on/features/time_off/domain/entities/leave_attachment.dart';

void main() {
  LeaveRequestDraft draft({
    List<DateTime>? dates,
    LeaveDurationType durationType = LeaveDurationType.fullDay,
    DateTime? returnDate,
    String reason = '',
    List<LeaveAttachment>? attachments,
  }) => LeaveRequestDraft(
    leaveTypeId: 'lt-annual',
    dates: dates ?? [DateTime(2026, 11, 18)],
    durationType: durationType,
    returnDate: returnDate,
    reason: reason,
    attachments: attachments,
  );

  test('dates are sent sorted, whatever order they were picked in', () {
    final body = LeaveDraftBody.from(
      draft(
        dates: [
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 18),
          DateTime(2026, 12, 1),
          DateTime(2026, 11, 19),
        ],
      ),
    );

    expect(body['dates'], [
      '2026-11-18',
      '2026-11-19',
      '2026-11-20',
      '2026-12-01',
    ]);
  });

  test('dates are YYYY-MM-DD, zero-padded, in Latin digits', () {
    final body = LeaveDraftBody.from(
      draft(dates: [DateTime(2026, 1, 5)], returnDate: DateTime(2026, 1, 6)),
    );

    expect(body['dates'], ['2026-01-05']);
    expect(body['return_date'], '2026-01-06');
    for (final text in [...body['dates'] as List, body['return_date']]) {
      expect(text, matches(r'^\d{4}-\d{2}-\d{2}$'));
    }
  });

  test('sending the draft does not reorder the caller\'s own list', () {
    final picked = [DateTime(2026, 11, 20), DateTime(2026, 11, 18)];

    LeaveDraftBody.from(draft(dates: picked));

    expect(picked, [DateTime(2026, 11, 20), DateTime(2026, 11, 18)]);
  });

  test('the leave type goes as leave_type_id', () {
    expect(LeaveDraftBody.from(draft())['leave_type_id'], 'lt-annual');
  });

  test('duration_type carries each wire value', () {
    String wire(LeaveDurationType type) =>
        LeaveDraftBody.from(draft(durationType: type))['duration_type']
            as String;

    expect(wire(LeaveDurationType.fullDay), 'full_day');
    expect(wire(LeaveDurationType.firstHalf), 'first_half');
    expect(wire(LeaveDurationType.secondHalf), 'second_half');
  });

  test('return_date is sent only when set', () {
    expect(LeaveDraftBody.from(draft()).containsKey('return_date'), isFalse);
    expect(
      LeaveDraftBody.from(
        draft(returnDate: DateTime(2026, 11, 19)),
      )['return_date'],
      '2026-11-19',
    );
  });

  test('a blank reason is left out; a real one is trimmed', () {
    expect(LeaveDraftBody.from(draft()).containsKey('reason'), isFalse);
    expect(
      LeaveDraftBody.from(draft(reason: '   ')).containsKey('reason'),
      isFalse,
    );
    expect(
      LeaveDraftBody.from(draft(reason: '  Family trip \n'))['reason'],
      'Family trip',
    );
  });

  group('attachments (a list of upload objects)', () {
    const medical = LeaveAttachment(
      url: 'https://files.nexton.work/a/medical.pdf',
      fileName: 'tenants/x/uploads/1_medical.pdf',
      originalName: 'medical.pdf',
      contentType: 'application/pdf',
      size: 20480,
    );
    const photo = LeaveAttachment(
      url: 'https://files.nexton.work/a/x.jpg',
      fileName: 'x.jpg',
      originalName: 'photo.jpg',
    );

    test('null: the body has no attachments key, so an edit keeps the files '
        'already on the request', () {
      expect(LeaveDraftBody.from(draft()).containsKey('attachments'), isFalse);
    });

    test('files: every one sent, as the server\'s upload object', () {
      final body = LeaveDraftBody.from(
        draft(attachments: [medical, photo]),
      );

      expect(body['attachments'], [
        {
          'url': 'https://files.nexton.work/a/medical.pdf',
          'file_name': 'tenants/x/uploads/1_medical.pdf',
          'original_name': 'medical.pdf',
          'content_type': 'application/pdf',
          'size': 20480,
        },
        {
          'url': 'https://files.nexton.work/a/x.jpg',
          'file_name': 'x.jpg',
          'original_name': 'photo.jpg',
        },
      ]);
    });

    test('an empty list is sent as []: on an edit it removes every file', () {
      expect(LeaveDraftBody.from(draft(attachments: const []))['attachments'],
          isEmpty);
      expect(
        LeaveDraftBody.from(
          draft(attachments: const []),
        ).containsKey('attachments'),
        isTrue,
      );
    });

    test('a file the server kept with no url goes back without one', () {
      final body = LeaveDraftBody.from(
        draft(
          attachments: const [
            LeaveAttachment(fileName: 'tenants/x/old.pdf', originalName: 'old.pdf'),
          ],
        ),
      );

      expect(body['attachments'], [
        {'file_name': 'tenants/x/old.pdf', 'original_name': 'old.pdf'},
      ]);
    });
  });

  test('the body has exactly the keys the form fills in', () {
    final body = LeaveDraftBody.from(
      draft(returnDate: DateTime(2026, 11, 19), reason: 'Trip'),
    );

    // Which keys, not their order.
    expect(body.keys.toSet(), {
      'leave_type_id',
      'dates',
      'duration_type',
      'return_date',
      'reason',
    });
  });

  group('a date range', () {
    LeaveRequestDraft range({DateTime? start, DateTime? end}) =>
        LeaveRequestDraft(
          leaveTypeId: 'lt-annual',
          dates: const [],
          startDate: start ?? DateTime(2026, 11, 20),
          endDate: end ?? DateTime(2026, 11, 23),
        );

    test('sends start_date and end_date, and no dates', () {
      final body = LeaveDraftBody.from(range());

      expect(body['start_date'], '2026-11-20');
      expect(body['end_date'], '2026-11-23');
      // Never both shapes: the server would charge every day in `dates`.
      expect(body.containsKey('dates'), isFalse);
    });

    test('the ends are YYYY-MM-DD, zero-padded, in Latin digits', () {
      final body = LeaveDraftBody.from(
        range(start: DateTime(2026, 1, 5), end: DateTime(2026, 1, 9)),
      );

      expect(body['start_date'], '2026-01-05');
      expect(body['end_date'], '2026-01-09');
    });

    test('carries the same other fields as separate days', () {
      final body = LeaveDraftBody.from(range());

      expect(body['leave_type_id'], 'lt-annual');
      expect(body['duration_type'], 'full_day');
    });
  });

  test('separate days send dates, and no range', () {
    final body = LeaveDraftBody.from(draft());

    expect(body.containsKey('dates'), isTrue);
    expect(body.containsKey('start_date'), isFalse);
    expect(body.containsKey('end_date'), isFalse);
  });

  test('a draft with only one end of a range is not a range', () {
    final body = LeaveDraftBody.from(
      LeaveRequestDraft(
        leaveTypeId: 'lt-annual',
        dates: [DateTime(2026, 11, 18)],
        startDate: DateTime(2026, 11, 18),
      ),
    );

    expect(body['dates'], ['2026-11-18']);
    expect(body.containsKey('start_date'), isFalse);
  });
}
