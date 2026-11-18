import 'entities/app_notification.dart';

/// How close in time two copies of one push are (#54).
const Duration repeatWindow = Duration(seconds: 60);

/// [rows] (newest first) without the copies a user with two phones gets:
/// the server logs one row per phone, not per push (until
/// Nexton-Backend#190). A row is left out when a row already kept, created
/// within [repeatWindow] of it, matches it — the same type, title, body and
/// data (the data's own `notification_type` aside: the first copy of a push
/// is logged without it). So copies collapse whether they come next to each
/// other or interleaved with another push's copies, and identical pushes a
/// minute or more apart all stay (a run never chains past the window). Pure:
/// run over every row loaded so far, so a pair split across two pages
/// collapses too.
List<AppNotification> collapseRepeats(List<AppNotification> rows) {
  final kept = <AppNotification>[];
  for (final row in rows) {
    var copy = false;
    // Newest first: the kept rows within the window are the last ones.
    for (var i = kept.length - 1; i >= 0; i--) {
      final other = kept[i];
      if (other.createdAt.difference(row.createdAt).abs() >= repeatWindow) {
        break;
      }
      if (_sameSend(other, row)) {
        copy = true;
        break;
      }
    }
    if (!copy) kept.add(row);
  }
  return kept;
}

bool _sameSend(AppNotification a, AppNotification b) =>
    a.type == b.type &&
    a.title == b.title &&
    a.body == b.body &&
    _sameData(a.data, b.data);

bool _sameData(Map<String, String> a, Map<String, String> b) {
  const ignored = 'notification_type';
  final keys = {...a.keys, ...b.keys}..remove(ignored);
  return keys.every((k) => a[k] == b[k]);
}
