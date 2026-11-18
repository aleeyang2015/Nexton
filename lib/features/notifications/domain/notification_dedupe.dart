import 'entities/app_notification.dart';

/// How close in time two copies of one push are (#54).
const Duration repeatWindow = Duration(seconds: 60);

/// [rows] (newest first) without the copies a user with two phones gets:
/// the server logs one row per phone, not per push (until
/// Nexton-Backend#190). A row is left out when it matches the row just
/// before it — the same type, title, body and data (the data's own
/// `notification_type` aside: the first copy of a push is logged without it)
/// — and was created within [repeatWindow] of it. Two real pushes a minute
/// or more apart both stay. Pure: run over every row loaded so far, so a
/// pair split across two pages collapses too.
List<AppNotification> collapseRepeats(List<AppNotification> rows) {
  final kept = <AppNotification>[];
  AppNotification? previous;
  for (final row in rows) {
    final before = previous;
    previous = row;
    if (before != null && _sameSend(before, row)) continue;
    kept.add(row);
  }
  return kept;
}

bool _sameSend(AppNotification a, AppNotification b) =>
    a.type == b.type &&
    a.title == b.title &&
    a.body == b.body &&
    a.createdAt.difference(b.createdAt).abs() < repeatWindow &&
    _sameData(a.data, b.data);

bool _sameData(Map<String, String> a, Map<String, String> b) {
  const ignored = 'notification_type';
  final keys = {...a.keys, ...b.keys}..remove(ignored);
  return keys.every((k) => a[k] == b[k]);
}
