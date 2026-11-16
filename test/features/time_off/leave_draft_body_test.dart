import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/data/models/leave_draft_body.dart';
import 'package:next_on/features/time_off/domain/entities/leave_duration_type.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request_draft.dart';
import 'package:next_on/features/time_off/domain/entities/uploaded_attachment.dart';

void main() {
  LeaveRequestDraft draft({
    List<DateTime>? dates,
    LeaveDurationType durationType = LeaveDurationType.fullDay,
    DateTime? returnDate,
    String reason = '',
    UploadedAttachment? attachment,
  }) => LeaveRequestDraft(
    leaveTypeId: 'lt-annual',
    dates: dates ?? [DateTime(2026, 11, 18)],
    durationType: durationType,
    returnDate: returnDate,
    reason: reason,
    attachment: attachment,
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

  group('attachments', () {
    const uploaded = UploadedAttachment(
      url: 'https://files.nexton.work/a/medical.pdf',
      fileName: 'tenants/x/uploads/1_medical.pdf',
      originalName: 'medical.pdf',
      contentType: 'application/pdf',
      size: 20480,
    );

    test('no file: the body has no attachments key, so an edit keeps the '
        'files already on the request', () {
      expect(LeaveDraftBody.from(draft()).containsKey('attachments'), isFalse);
    });

    test('a file: attachments is sent, as the one uploaded object', () {
      final body = LeaveDraftBody.from(draft(attachment: uploaded));

      // Today this is a single object, not a list of them.
      expect(body['attachments'], {
        'url': 'https://files.nexton.work/a/medical.pdf',
        'file_name': 'tenants/x/uploads/1_medical.pdf',
        'original_name': 'medical.pdf',
        'content_type': 'application/pdf',
        'size': 20480,
      });
    });

    test('content_type and size are left out when the upload gave none', () {
      final body = LeaveDraftBody.from(
        draft(
          attachment: const UploadedAttachment(
            url: 'https://files.nexton.work/a/x.jpg',
            fileName: 'x.jpg',
            originalName: 'photo.jpg',
          ),
        ),
      );

      expect(body['attachments'], {
        'url': 'https://files.nexton.work/a/x.jpg',
        'file_name': 'x.jpg',
        'original_name': 'photo.jpg',
      });
    });
  });

  test('the body has exactly the keys the form fills in', () {
    final body = LeaveDraftBody.from(
      draft(returnDate: DateTime(2026, 11, 19), reason: 'Trip'),
    );

    expect(body.keys, [
      'leave_type_id',
      'dates',
      'duration_type',
      'return_date',
      'reason',
    ]);
  });
}
