import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';
import '../providers/ot_detail_notifier.dart';
import '../widgets/ot_request_actions.dart';
import 'ot_ask_page.dart';
import 'ot_request_detail_page.dart';

/// Changes the waiting OT request [requestId]: the Ask form (#31) filled in
/// from it.
///
/// [initial] is the request as the request page showed it. Opened from a
/// link with no copy, it is loaded by its id first:
/// * gone (`404`): "not available", and the list;
/// * another failure: the request page, which says why;
/// * not the user's to change (approved, a join, someone else's, no day):
///   the request page, with its own buttons, instead of a form the server
///   would refuse.
///
/// The form works from the copy it opened with: a reload of the request
/// page underneath does not reset what was typed.
class OtEditPage extends ConsumerStatefulWidget {
  final String requestId;
  final OtRequest? initial;

  const OtEditPage({super.key, required this.requestId, this.initial});

  @override
  ConsumerState<OtEditPage> createState() => _OtEditPageState();
}

class _OtEditPageState extends ConsumerState<OtEditPage> {
  /// The copy the form opened with, kept once known.
  OtRequest? _editing;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _editing = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    if (editing != null) return OtAskPage(editing: editing);

    final loaded = ref.watch(otDetailNotifierProvider(widget.requestId));
    final request = loaded.valueOrNull;
    if (request != null) {
      final actions = OtRequestActions.of(
        request,
        ownEmployeeId: ref.read(otOwnEmployeeIdProvider),
      );
      if (!actions.canEdit) {
        return OtRequestDetailPage(
          requestId: widget.requestId,
          initial: request,
        );
      }
      _editing = request;
      return OtAskPage(editing: request);
    }

    if (loaded.hasError && !loaded.isLoading) {
      if (OtDetailNotifier.isGone(loaded.error)) {
        _leaveGone(context);
      } else {
        return OtRequestDetailPage(requestId: widget.requestId);
      }
    }
    return const ColoredBox(
      color: AppColors.homeBackground,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  /// The request is gone: say so once, and go to the list.
  void _leaveGone(BuildContext context) {
    if (_leaving) return;
    _leaving = true;
    final l10n = AppLocalizations.of(context)!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoutes.overtime);
      // Once the list is there: the toast needs a page to show on.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => AppToast.error(l10n.otRequestGone),
      );
    });
  }
}
