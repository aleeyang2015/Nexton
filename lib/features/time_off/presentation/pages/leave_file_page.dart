import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/pdf_file_view.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_attachment.dart';
import '../providers/leave_file_notifier.dart';

/// A leave file inside the App, with Share: a PDF in the shared viewer
/// (owner's decision on #25), anything else as a Share sheet only.
class LeaveFilePage extends ConsumerWidget {
  const LeaveFilePage({super.key, required this.file});

  final LeaveAttachment file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = leaveFileNotifierProvider(file);
    final loaded = ref.watch(provider);
    final path = loaded.isLoading ? null : loaded.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: customText(
          file.displayName,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 16,
        ),
        actions: [
          if (path != null)
            Builder(
              builder: (buttonContext) => IconButton(
                icon: const Icon(Icons.ios_share, color: AppColors.primary),
                onPressed: () async {
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  final origin = box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size;
                  final shared = await ref
                      .read(provider.notifier)
                      .share(origin: origin);
                  if (!shared) AppToast.error(l10n.leaveFileOpenFailed);
                },
              ),
            ),
        ],
      ),
      body: loaded.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : loaded.hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  customText(
                    l10n.leaveFileOpenFailed,
                    color: AppColors.subTitle,
                  ),
                  heightBx(h: 12),
                  TextButton(
                    onPressed: () => ref.read(provider.notifier).retry(),
                    child: customText(l10n.retry, color: AppColors.primary),
                  ),
                ],
              ),
            )
          : file.isPdf
          ? ref.watch(pdfFileViewProvider)(path!, l10n.leaveFileOpenFailed)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 56,
                      color: AppColors.subTitle,
                    ),
                    heightBx(h: 12),
                    customText(
                      file.displayName,
                      alight: TextAlign.center,
                      maxLine: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
