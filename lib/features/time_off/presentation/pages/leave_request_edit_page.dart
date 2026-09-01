import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_request.dart';
import '../providers/leave_request_form_notifier.dart';
import '../widgets/leave_request_form.dart';

/// Full-screen host for [LeaveRequestForm] in edit mode
/// (`PUT /leave/requests/:id`, leave-request-flutter.md §3.4). Seeds the
/// form's family instance (keyed by the request id) from [request], then pops
/// with `true` once the update goes through so the detail page can refresh.
class LeaveRequestEditPage extends ConsumerStatefulWidget {
  const LeaveRequestEditPage({super.key, required this.request});

  final LeaveRequest request;

  @override
  ConsumerState<LeaveRequestEditPage> createState() =>
      _LeaveRequestEditPageState();
}

class _LeaveRequestEditPageState extends ConsumerState<LeaveRequestEditPage> {
  @override
  void initState() {
    super.initState();
    // Seeding writes to the form provider, which Riverpod forbids during a
    // widget life-cycle. Defer it to just after this frame; `seed` is a no-op
    // once the form is already in edit mode, so the extra call is harmless.
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(leaveRequestFormNotifierProvider(widget.request.id).notifier)
          .seed(widget.request);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
            ),
            title: customText(
              l10n.leaveEditAction,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
          body: LeaveRequestForm(
            requestId: widget.request.id,
            onSubmitted: () => context.pop(true),
          ),
        ),
      ),
    );
  }
}
