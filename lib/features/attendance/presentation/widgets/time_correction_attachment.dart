import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/local_file.dart';
import 'time_correction_copy.dart';

/// The upload area: a tappable drop box with "take photo" / "choose file"
/// buttons, and the picked file's row below it once there is one.
class TimeCorrectionAttachment extends StatelessWidget {
  final LocalFile? file;
  final int? fileBytes;
  final VoidCallback onChooseFile;
  final VoidCallback onTakePhoto;
  final VoidCallback onRemove;

  const TimeCorrectionAttachment({
    super.key,
    required this.file,
    required this.fileBytes,
    required this.onChooseFile,
    required this.onTakePhoto,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _UploadBox(onChooseFile: onChooseFile, onTakePhoto: onTakePhoto),
        if (file != null) ...[
          heightBx(h: 12),
          _FileRow(file: file!, bytes: fileBytes, onRemove: onRemove),
        ],
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final VoidCallback onChooseFile;
  final VoidCallback onTakePhoto;

  const _UploadBox({required this.onChooseFile, required this.onTakePhoto});

  @override
  Widget build(BuildContext context) {
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

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
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
  final LocalFile file;
  final int? bytes;
  final VoidCallback onRemove;

  const _FileRow({
    required this.file,
    required this.bytes,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = file.name.toLowerCase().endsWith('.pdf');

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
            child: customText(
              file.name,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          if (bytes != null) ...[
            widthBx(w: 6),
            customText(
              '(${TimeCorrectionCopy.fileSize(bytes!)})',
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
