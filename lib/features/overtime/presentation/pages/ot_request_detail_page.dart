import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ot_request.dart';
import '../providers/ot_detail_notifier.dart';
import '../widgets/ot_copy.dart';
import '../widgets/ot_request_sections.dart';

/// One OT request, opened by its id from the OT list, another screen or a
/// push. [initial] is the list's row for it, shown while the page loads its
/// own copy.
///
/// A request that is gone, or not the caller's to see (`404`): a toast, and
/// back to the list, which refreshes.
class OtRequestDetailPage extends ConsumerWidget {
  final String requestId;
  final OtRequest? initial;

  const OtRequestDetailPage({super.key, required this.requestId, this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = otDetailNotifierProvider(requestId);
    final loaded = ref.watch(provider);
    final error = loaded.hasError ? loaded.error : null;
    final gone = OtDetailNotifier.isGone(error);
    final request = gone ? null : (loaded.valueOrNull ?? initial);

    ref.listen(provider, (previous, next) {
      if (!next.hasError || next.isLoading) return;
      if (OtDetailNotifier.isGone(next.error)) {
        AppToast.error(l10n.otRequestGone);
        _goBack(context);
      } else if (initial != null && previous?.hasError != true) {
        // The list's copy is on screen and the page's own load failed: say
        // so, or the old copy would pass for the current one.
        final failure = next.error;
        if (failure is Failure) AppToast.error(failure.localize(l10n));
      }
    });

    final Widget body;
    if (request != null) {
      body = RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final failure = await ref.read(provider.notifier).refresh();
          if (failure != null &&
              !OtDetailNotifier.isGone(failure) &&
              context.mounted) {
            AppToast.error(failure.localize(l10n));
          }
        },
        child: OtRequestSections(request: request),
      );
    } else if (error != null && !gone) {
      final shown = OtCopy.listError(l10n, error);
      body = _Failed(
        message: shown.message,
        // Loads it again from the start, with the spinner.
        onRetry: shown.canRetry ? () => ref.invalidate(provider) : null,
      );
    } else {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _goBack(context),
                      child: popBack(),
                    ),
                    widthBx(w: 4),
                    Expanded(
                      child: customText(
                        l10n.otMenu,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  /// Back to the page underneath; opened from a push there may be none, and
  /// the OT list is where to go.
  static void _goBack(BuildContext context) => context.canPop()
      ? context.pop()
      : context.go(AppRoutes.overtime);
}

class _Failed extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _Failed({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onRetry = this.onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customText(
              message,
              color: AppColors.subTitle,
              alight: TextAlign.center,
              maxLine: 4,
            ),
            if (onRetry != null) ...[
              heightBx(h: 12),
              TextButton(
                onPressed: onRetry,
                child: customText(
                  l10n.retry,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
