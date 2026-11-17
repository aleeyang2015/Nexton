import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/ot_pay_type.dart';
import 'package:next_on/features/overtime/data/models/ot_post_model.dart';
import 'package:next_on/features/overtime/domain/entities/ot_post.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';

import '../../support/overtime_json.dart';

/// An open HR OT post (`OTOpenAnnouncement`), read exactly as the server
/// sends it.
void main() {
  OtPost read(Map<String, dynamic> json) => OtPostModel.fromJson(json);

  test('reads every field of a post', () {
    final post = read(otPostJson());

    expect(post.id, 'post-1');
    expect(post.departmentId, 'dep-kitchen');
    expect(post.departmentName, 'Kitchen');
    expect(post.workDate, DateTime(2026, 11, 21));
    expect(post.startTime, '22:00');
    expect(post.endTime, '02:00');
    expect(post.endsNextDay, isTrue);
    expect(post.startsAt!.toUtc(), DateTime.utc(2026, 11, 21, 15));
    expect(post.endsAt!.toUtc(), DateTime.utc(2026, 11, 21, 19));
    expect(post.seats, 3);
    expect(post.joinDeadline!.toUtc(), DateTime.utc(2026, 11, 20, 10));
    expect(post.reason, 'Night banquet');
    expect(post.status, OtPostStatus.open);
    expect(post.accepted, 1);
    expect(post.waiting, 1);
    expect(post.createdAt, DateTime(2026, 11, 12, 8));
    expect(post.updatedAt, DateTime(2026, 11, 12, 8));
    expect(post.full, isFalse);
    expect(post.joinOpen, isTrue);
    expect(post.myJoin, isNull);
    expect(post.pieces.single.payType, OtPayType.percent);
    expect(post.pieces.single.payValue, 200);
  });

  test('seats null is no limit; join_deadline null is none; no department '
      'name', () {
    final post = read({
      ...otPostJson(),
      'seats': null,
      'join_deadline': null,
      'department_name': null,
    });

    expect(post.seats, isNull);
    expect(post.hasSeatLimit, isFalse);
    expect(post.joinDeadline, isNull);
    expect(post.departmentName, isNull);
  });

  test('my_join set: my own request for this post, read as an OT request',
      () {
    final post = read({
      ...otPostJson(),
      'my_join': {
        ...otRequestJson(),
        'id': 'ot-join',
        'announcement_id': 'post-1',
      },
    });

    expect(post.myJoin, isA<OtRequest>());
    expect(post.myJoin!.id, 'ot-join');
    expect(post.myJoin!.announcementId, 'post-1');
    expect(post.myJoin!.createdAt, DateTime(2026, 11, 11, 9, 30));
  });

  test('not joined: my_join null or missing', () {
    expect(read(otPostJson()).joined, isFalse);
    expect(read(otPostJson()..remove('my_join')).joined, isFalse);
  });

  test('joined: my_join set, read as a request', () {
    final post = read({
      ...otPostJson(),
      'my_join': {...otRequestJson(), 'id': 'ot-join'},
    });

    expect(post.joined, isTrue);
  });

  test('a my_join object that cannot be read still counts as joined: Join '
      'is never offered again', () {
    final post = read({
      ...otPostJson(),
      'my_join': {...otRequestJson(), 'id': 7},
    });

    expect(post.myJoin, isNull);
    expect(post.joined, isTrue);
    expect(read({...otPostJson(), 'my_join': <String, dynamic>{}}).joined,
        isTrue);
  });

  test('a my_join that is not an object is not a join', () {
    final post = read({...otPostJson(), 'my_join': 'yes'});

    expect(post.myJoin, isNull);
    expect(post.joined, isFalse);
  });

  test('tryFromJson: a row with no id is null, for a list to skip', () {
    expect(OtPostModel.tryFromJson(otPostJson()), isNotNull);
    expect(OtPostModel.tryFromJson(otPostJson()..remove('id')), isNull);
  });

  test('a cancelled post, and a status the App does not know', () {
    expect(read({...otPostJson(), 'status': 'cancelled'}).status,
        OtPostStatus.cancelled);
    expect(read({...otPostJson(), 'status': 'archived'}).status,
        OtPostStatus.unknown);
  });

  test('full and closed to joining', () {
    final post = read({...otPostJson(), 'full': true, 'join_open': false});

    expect(post.full, isTrue);
    expect(post.joinOpen, isFalse);
  });

  test('fields of the wrong type do not crash the read', () {
    final post = read({
      ...otPostJson(),
      'seats': 'three',
      'accepted': null,
      'waiting': '1',
      'full': 'no',
      'join_open': null,
      'join_deadline': 5,
      'pieces': null,
      'created_at': '12/11/2026',
    });

    expect(post.seats, isNull);
    expect(post.accepted, 0);
    expect(post.waiting, 0);
    expect(post.full, isFalse);
    expect(post.joinOpen, isFalse);
    expect(post.joinDeadline, isNull);
    expect(post.pieces, isEmpty);
    expect(post.createdAt, isNull);
  });

  test('a post with no id is refused: nothing could open it', () {
    final json = otPostJson()..remove('id');

    expect(() => read(json), throwsFormatException);
  });
}
