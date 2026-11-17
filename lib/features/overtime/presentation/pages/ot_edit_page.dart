import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ot_request.dart';
import '../providers/ot_detail_notifier.dart';
import 'ot_ask_page.dart';
import 'ot_request_detail_page.dart';

/// Changes the waiting OT request [requestId]: the Ask form (#31) filled in
/// from it.
///
/// [initial] is the request as the request page showed it. Opened from a
/// link with no copy, it is loaded by its id first; one that cannot be
/// loaded is shown by the request page (gone, or why it failed).
class OtEditPage extends ConsumerWidget {
  final String requestId;
  final OtRequest? initial;

  const OtEditPage({super.key, required this.requestId, this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = this.initial;
    if (initial != null) return OtAskPage(editing: initial);

    final loaded = ref.watch(otDetailNotifierProvider(requestId));
    final request = loaded.valueOrNull;
    if (request != null) return OtAskPage(editing: request);
    if (loaded.hasError && !loaded.isLoading) {
      return OtRequestDetailPage(requestId: requestId);
    }
    return const ColoredBox(
      color: AppColors.homeBackground,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
