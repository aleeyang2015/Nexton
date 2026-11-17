import '../../domain/entities/ot_post.dart';
import '../../domain/entities/ot_request.dart';
import 'ot_parse.dart';
import 'ot_piece_model.dart';
import 'ot_request_model.dart';

/// Reads an open HR OT post (`OTOpenAnnouncement`).
///
/// Tolerant, as [OtRequestModel]: the one thing refused is a post with no
/// id ([FormatException]). A `my_join` object that cannot be read as a
/// request still counts as joined ([OtPost.joined]); only a missing or
/// null `my_join` is "not joined".
class OtPostModel {
  OtPostModel._();

  /// [fromJson], or null for a row that cannot be read: a list skips it
  /// rather than losing the whole page.
  static OtPost? tryFromJson(Map<String, dynamic> json) {
    try {
      return fromJson(json);
    } on FormatException {
      return null;
    }
  }

  static OtPost fromJson(Map<String, dynamic> json) {
    final id = OtJson.nonEmpty(json['id']);
    if (id == null) throw const FormatException('An OT post without an id');

    return OtPost(
      id: id,
      departmentId: OtJson.str(json['department_id']) ?? '',
      departmentName: OtJson.nonEmpty(json['department_name']),
      workDate: OtJson.date(json['work_date']),
      startTime: OtJson.str(json['start_time']) ?? '',
      endTime: OtJson.str(json['end_time']) ?? '',
      endsNextDay: OtJson.boolOf(json['ends_next_day']),
      startsAt: OtJson.instant(json['starts_at']),
      endsAt: OtJson.instant(json['ends_at']),
      seats: OtJson.intOf(json['seats']),
      joinDeadline: OtJson.instant(json['join_deadline']),
      reason: OtJson.nonEmpty(json['reason']),
      status: switch (json['status']) {
        'open' => OtPostStatus.open,
        'cancelled' => OtPostStatus.cancelled,
        _ => OtPostStatus.unknown,
      },
      accepted: OtJson.intOf(json['accepted']) ?? 0,
      waiting: OtJson.intOf(json['waiting']) ?? 0,
      createdAt: OtJson.wallClock(json['created_at']),
      updatedAt: OtJson.wallClock(json['updated_at']),
      pieces: OtJson.objects(json['pieces']).map(OtPieceModel.fromJson).toList(),
      full: OtJson.boolOf(json['full']),
      joinOpen: OtJson.boolOf(json['join_open']),
      myJoin: _myJoin(json['my_join']),
      joined: json['my_join'] is Map,
    );
  }

  static OtRequest? _myJoin(dynamic value) {
    final json = OtJson.object(value);
    if (json == null) return null;
    return OtRequestModel.tryFromJson(json);
  }
}
