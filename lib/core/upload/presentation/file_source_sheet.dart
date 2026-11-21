import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/global_widgets.dart';
import '../domain/capture_policy.dart';
import '../upload_providers.dart';

/// Asks where the file comes from, offering only what [policy] allows, then
/// takes or picks it. With [CapturePolicy.cameraOnly] there is nothing to
/// ask: the camera opens at once.
///
/// Resolves to the file, [CaptureCancelled] when the user backs out (of the
/// sheet or the picker), or [CaptureDenied] when the phone refused.
class FileSourceSheet {
  const FileSourceSheet._();

  ///
  /// One at a time: a second tap while the sheet or a picker is open asks
  /// for nothing more.
  static Future<CaptureResult> pick(
    BuildContext context,
    WidgetRef ref,
    CapturePolicy policy,
  ) async {
    final gate = ref.read(_pickGateProvider);
    if (gate.open) return const CaptureCancelled();
    gate.open = true;
    try {
      return await _pick(context, ref, policy);
    } finally {
      gate.open = false;
    }
  }

  static Future<CaptureResult> _pick(
    BuildContext context,
    WidgetRef ref,
    CapturePolicy policy,
  ) async {
    final capture = ref.read(fileCaptureProvider);
    final sources = policy.sources;
    final source = sources.length == 1
        ? sources.single
        : await showModalBottomSheet<CaptureSource>(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _Sources(sources: sources),
          );
    if (source == null || !context.mounted) return const CaptureCancelled();

    return switch (source) {
      CaptureSource.camera => capture.takePhoto(context),
      CaptureSource.gallery => capture.pickPhoto(
        compatible: policy.wantsCompatibleImage,
      ),
      CaptureSource.file => capture.pickFile(allowPdf: policy.allowsPdf),
    };
  }
}

class _Sources extends StatelessWidget {
  const _Sources({required this.sources});

  final List<CaptureSource> sources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final source in sources)
              ListTile(
                leading: Icon(_icon(source), color: AppColors.primary),
                title: customText(_label(l10n, source), fontSize: 15),
                onTap: () => Navigator.of(context).pop(source),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(CaptureSource source) => switch (source) {
    CaptureSource.camera => Icons.photo_camera_outlined,
    CaptureSource.gallery => Icons.photo_library_outlined,
    CaptureSource.file => Icons.attach_file,
  };

  static String _label(AppLocalizations l10n, CaptureSource source) =>
      switch (source) {
        CaptureSource.camera => l10n.uploadTakePhoto,
        CaptureSource.gallery => l10n.uploadPickPhoto,
        CaptureSource.file => l10n.uploadPickFile,
      };
}

/// Whether a sheet or a picker is open: one at a time per App.
class _PickGate {
  bool open = false;
}

final _pickGateProvider = Provider<_PickGate>((ref) => _PickGate());
