import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_request.dart';
import '../providers/leave_request_detail_notifier.dart';
import '../providers/leave_request_form_notifier.dart';
import '../widgets/leave_request_form.dart';
import '../widgets/leave_request_unavailable.dart';

/// Full-screen host for [LeaveRequestForm] in edit mode
/// (`PUT /leave/requests/:id`), opened by the request's id.
///
/// The form's family instance (keyed by the id) is seeded once: from
/// [initial] when the caller handed the request in, else from the request
/// loaded by id when it arrives. Pops with `true` once the update goes
/// through, or is refused as out of date, so the detail page reloads.
class LeaveRequestEditPage extends ConsumerStatefulWidget {
  const LeaveRequestEditPage({
    super.key,
    required this.requestId,
    this.initial,
  });

  final String requestId;
  final LeaveRequest? initial;

  @override
  ConsumerState<LeaveRequestEditPage> createState() =>
      _LeaveRequestEditPageState();
}

class _LeaveRequestEditPageState extends ConsumerState<LeaveRequestEditPage> {
  /// The request the form was seeded from; null until there is one.
  LeaveRequest? _seededFrom;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;
    if (initial != null) {
      _seed(initial);
      return;
    }

    // No request was handed in: wait for the one loaded by id, and seed from
    // the first that arrives. Later reloads do not seed again; they would
    // wipe what the user has typed.
    ref.listenManual(
      leaveRequestDetailNotifierProvider(widget.requestId),
      (_, next) {
        final request = next.valueOrNull;
        if (request != null && _seededFrom == null) _seed(request);
      },
      fireImmediately: true,
    );
  }

  void _seed(LeaveRequest request) {
    _seededFrom = request;
    // A request that can no longer be edited gets no form; the page says so.
    if (!request.canEdit) {
      Future.microtask(() {
        if (mounted) setState(() {});
      });
      return;
    }
    // Seeding writes to the form provider, which Riverpod forbids during a
    // widget life-cycle. Defer it to just after this frame; `seed` keeps a
    // form already in edit mode, so the extra call is harmless.
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(leaveRequestFormNotifierProvider(widget.requestId).notifier)
          .seed(request);
      setState(() {});
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
          body: _body(l10n),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    final request = _seededFrom;
    if (request == null) {
      // Opened by id alone, and the request is not here yet (or never came).
      final loaded = ref.watch(
        leaveRequestDetailNotifierProvider(widget.requestId),
      );
      if (loaded.hasError) {
        return LeaveRequestUnavailable(
          error: loaded.error,
          onRetry: () => ref.invalidate(
            leaveRequestDetailNotifierProvider(widget.requestId),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Only a pending request can be edited; one opened by a link may not be.
    if (!request.canEdit) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: customText(
            l10n.leaveInvalidStatus,
            color: AppColors.subTitle,
            alight: TextAlign.center,
            maxLine: 4,
          ),
        ),
      );
    }

    return LeaveRequestForm(
      requestId: widget.requestId,
      onSubmitted: () => context.pop(true),
    );
  }
}
