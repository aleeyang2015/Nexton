/// Where a tapped push opens (#53). Read from the push's `data` only: the
/// push carries no owner, so "mine or not" is the opened page's call.
sealed class PushTarget {
  const PushTarget();
}

/// A leave request by id (the approver view when it is not the user's).
final class LeaveRequestTarget extends PushTarget {
  final String id;
  const LeaveRequestTarget(this.id);

  @override
  bool operator ==(Object other) =>
      other is LeaveRequestTarget && other.id == id;

  @override
  int get hashCode => Object.hash(LeaveRequestTarget, id);

  @override
  String toString() => 'LeaveRequestTarget($id)';
}

/// A "forgot to scan" request by id (the approver view when not the user's).
final class CorrectionTarget extends PushTarget {
  final String id;
  const CorrectionTarget(this.id);

  @override
  bool operator ==(Object other) => other is CorrectionTarget && other.id == id;

  @override
  int get hashCode => Object.hash(CorrectionTarget, id);

  @override
  String toString() => 'CorrectionTarget($id)';
}

/// An OT request by id; the page itself shows a head's actions.
final class OtRequestTarget extends PushTarget {
  final String id;
  const OtRequestTarget(this.id);

  @override
  bool operator ==(Object other) => other is OtRequestTarget && other.id == id;

  @override
  int get hashCode => Object.hash(OtRequestTarget, id);

  @override
  String toString() => 'OtRequestTarget($id)';
}

/// The OT posts page (staff cannot read one post by id).
final class OtPostsTarget extends PushTarget {
  const OtPostsTarget();
}

/// The user's own OT list (a post they joined was cancelled).
final class MyOtTarget extends PushTarget {
  const MyOtTarget();
}

/// Home: the clock card (a punch refused outside every area).
final class HomeTarget extends PushTarget {
  const HomeTarget();
}

/// The bell list (#54): a push this App does not know, or one missing the
/// id it needs.
final class NotificationsTarget extends PushTarget {
  const NotificationsTarget();
}

/// The push's `notification_type` and `reference_type` values the backend
/// sends today.
abstract final class PushTypes {
  static const String leaveRequest = 'leave_request';
  static const String correction = 'attendance_correction';
  static const String offsite = 'attendance_offsite';
  static const String attendance = 'attendance';
  static const String otAnnouncement = 'overtime_announcement';
  static const String otRequest = 'overtime_request';
}

/// The target for a push's [data] (`notification_type`, `reference_type`,
/// `reference_id`). Routed on the pair: an "OT post cancelled" push has
/// type `overtime_request` but points at the post.
PushTarget pushTarget(Map<String, Object?> data) {
  String read(String key) => (data[key]?.toString() ?? '').trim();
  final type = read('notification_type');
  final reference = read('reference_type');
  final id = read('reference_id');

  PushTarget byId(PushTarget Function(String id) target) =>
      id.isEmpty ? const NotificationsTarget() : target(id);

  return switch ((type, reference)) {
    (PushTypes.leaveRequest, PushTypes.leaveRequest) => byId(
      LeaveRequestTarget.new,
    ),
    (PushTypes.correction, PushTypes.correction) => byId(CorrectionTarget.new),
    (PushTypes.otRequest, PushTypes.otRequest) => byId(OtRequestTarget.new),
    (PushTypes.otAnnouncement, PushTypes.otAnnouncement) =>
      const OtPostsTarget(),
    (PushTypes.otRequest, PushTypes.otAnnouncement) => const MyOtTarget(),
    (PushTypes.offsite, _) => const HomeTarget(),
    _ => const NotificationsTarget(),
  };
}
