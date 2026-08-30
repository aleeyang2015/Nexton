import 'package:flutter/material.dart';

import 'leave_request_form.dart';

/// "ຂໍລາພັກ" — the new-leave-request tab. All of the form lives in the shared
/// [LeaveRequestForm] (the edit page reuses it); this tab just hosts the
/// `null`-keyed instance.
class LeaveRequestTab extends StatelessWidget {
  const LeaveRequestTab({super.key});

  @override
  Widget build(BuildContext context) => const LeaveRequestForm();
}
