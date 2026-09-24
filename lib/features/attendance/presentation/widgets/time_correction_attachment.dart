import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/local_file.dart';
import '../../../time_off/domain/entities/uploaded_attachment.dart';
import '../providers/time_correction_attachment_notifier.dart';
import 'time_correction_copy.dart';

/// The upload area: a tappable drop box with "take photo" / "choose file"
/// buttons — showing the accepted file as its background once there is one —
/// and below it either the in-flight upload's spinner or the file's row.
class TimeCorrectionAttachment extends StatelessWidget {
  final TimeCorrectionEvidence? file;
  final bool uploading;
  final VoidCallback onChooseFile;
  final VoidCallback onTakePhoto;
  final VoidCallback onRemove;

  const TimeCorrectionAttachment({
    super.key,
    required this.file,
    required this.uploading,
    required this.onChooseFile,
    required this.onTakePhoto,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _UploadBox(
          preview: file?.local,
          onChooseFile: onChooseFile,
          onTakePhoto: onTakePhoto,
        ),
        if (uploading) ...[
          heightBx(h: 12),
          const _UploadingRow(),
        ] else if (file != null) ...[
          heightBx(h: 12),
          _FileRow(file: file!.uploaded, onRemove: onRemove),
        ],
      ],
    );
  }
}

class _UploadingRow extends StatelessWidget {
  const _UploadingRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryVariant,
            ),
          ),
          widthBx(w: 10),
          customText(
            l10n.leaveAttachUploading,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  /// The accepted file, shown as the box's background; null for the empty
  /// "tap to upload" prompt.
  final LocalFile? preview;
  final VoidCallback onChooseFile;
  final VoidCallback onTakePhoto;

  const _UploadBox({
    required this.preview,
    required this.onChooseFile,
    required this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final file = preview;
    if (file != null) {
      return _PreviewBox(
        file: file,
        onChooseFile: onChooseFile,
        onTakePhoto: onTakePhoto,
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChooseFile,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.primaryVariant,
                  size: 30,
                ),
              ),
              heightBx(h: 12),
              customText(
                l10n.timeCorrectionUploadTitle,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                maxLine: 2,
                alight: TextAlign.center,
              ),
              heightBx(h: 4),
              customText(
                l10n.timeCorrectionUploadHint,
                fontSize: 13,
                color: AppColors.secondaryTxt,
                maxLine: 3,
                alight: TextAlign.center,
              ),
              heightBx(h: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallButton(
                    icon: Icons.photo_camera_outlined,
                    label: l10n.timeCorrectionTakePhoto,
                    onTap: onTakePhoto,
                  ),
                  widthBx(w: 8),
                  _SmallButton(
                    icon: Icons.attach_file,
                    label: l10n.timeCorrectionChooseFile,
                    onTap: onChooseFile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The drop box once a file is accepted: an image fills it, a PDF shows as a
/// large PDF mark with its name (the app ships no PDF renderer). Tapping it,
/// or the buttons along the bottom, replaces the file.
class _PreviewBox extends StatelessWidget {
  static const double _height = 180;

  final LocalFile file;
  final VoidCallback onChooseFile;
  final VoidCallback onTakePhoto;

  const _PreviewBox({
    required this.file,
    required this.onChooseFile,
    required this.onTakePhoto,
  });

  static const _imageExtensions = ['.jpg', '.jpeg', '.png'];

  bool get _isImage {
    final name = file.name.toLowerCase();
    return _imageExtensions.any(name.endsWith);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isImage)
              Image.file(
                File(file.path),
                fit: BoxFit.cover,
                // A picked image the platform can't decode still gets a
                // sensible background instead of an error box.
                errorBuilder: (_, _, _) => _DocumentBackground(file: file),
              )
            else
              _DocumentBackground(file: file),
            // Darkens the bottom so the buttons read on any image.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black45],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: onChooseFile),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallButton(
                    icon: Icons.photo_camera_outlined,
                    label: l10n.timeCorrectionTakePhoto,
                    onTap: onTakePhoto,
                    background: Colors.white,
                  ),
                  widthBx(w: 8),
                  _SmallButton(
                    icon: Icons.attach_file,
                    label: l10n.timeCorrectionChooseFile,
                    onTap: onChooseFile,
                    background: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A non-image file's stand-in background: its type mark and name.
class _DocumentBackground extends StatelessWidget {
  final LocalFile file;

  const _DocumentBackground({required this.file});

  @override
  Widget build(BuildContext context) {
    final isPdf = file.name.toLowerCase().endsWith('.pdf');

    return ColoredBox(
      color: AppColors.primaryTint,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 56),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined,
              size: 56,
              color: isPdf ? AppColors.danger : AppColors.primaryVariant,
            ),
            heightBx(h: 8),
            customText(
              file.name,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              maxLine: 2,
              alight: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Defaults to a light primary tint; a preview passes white so the button
  /// stays legible over an image.
  final Color? background;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.textPrimary),
              widthBx(w: 4),
              customText(
                label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final UploadedAttachment file;
  final VoidCallback onRemove;

  const _FileRow({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name = file.originalName;
    final bytes = file.size;
    final isPdf =
        name.toLowerCase().endsWith('.pdf') ||
        file.contentType == 'application/pdf';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            size: 20,
            color: AppColors.primaryVariant,
          ),
          widthBx(w: 8),
          Flexible(
            child: customText(name, fontSize: 14, color: AppColors.textPrimary),
          ),
          if (bytes != null) ...[
            widthBx(w: 6),
            customText(
              '(${TimeCorrectionCopy.fileSize(bytes)})',
              fontSize: 12,
              color: AppColors.subTitle,
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
