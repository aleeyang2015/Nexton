/// Where a leave request stands in the submit → dept-head → HR approval chain.
///
/// Mirrors the whole-request `status` field of `LeaveRequestResponse`
/// (leave-request-flutter.md §2).
enum LeaveStatus { pending, approved, rejected, cancelled }
