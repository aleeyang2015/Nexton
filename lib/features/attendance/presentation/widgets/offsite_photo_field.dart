import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/local_file.dart';
import '../providers/offsite_photo_notifier.dart';

/// The scan's photo: an empty prompt until one is taken, then the shot itself
/// with the buttons that replace it, and the upload's spinner below while it is
/// on its way.
///
/// Images only — §3 wants a photograph of where the employee is standing — so
/// there is none of the time-correction form's document handling here.
class OffsitePhotoField extends StatelessWidget {
  static const double _previewHeight = 180;

  final OffsitePhoto? photo;
  final bool uploading;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseImage;
  final VoidCallback onRemove;

  const OffsitePhotoField({
    super.key,
    required this.photo,
    required this.uploading,
    required this.onTakePhoto,
    required this.onChooseImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final current = photo;

    return Column(
      children: [
        if (current == null)
          _EmptyBox(onTakePhoto: onTakePhoto, onChooseImage: onChooseImage)
        else
          _Preview(
            file: current.local,
            height: _previewHeight,
            onTakePhoto: onTakePhoto,
            onChooseImage: onChooseImage,
          ),
        if (uploading) ...[
          heightBx(h: 12),
          const _UploadingRow(),
        ] else if (current != null) ...[
          heightBx(h: 12),
          _FileRow(name: current.uploaded.originalName, onRemove: onRemove),
        ],
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseImage;

  const _EmptyBox({required this.onTakePhoto, required this.onChooseImage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTakePhoto,
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
                  Icons.add_a_photo_outlined,
                  color: AppColors.primaryVariant,
                  size: 30,
                ),
              ),
              heightBx(h: 12),
              customText(
                l10n.offsitePhotoTitle,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                maxLine: 2,
                alight: TextAlign.center,
              ),
              heightBx(h: 4),
              customText(
                l10n.offsitePhotoHint,
                fontSize: 13,
                color: AppColors.secondaryTxt,
                maxLine: 3,
                alight: TextAlign.center,
              ),
              heightBx(h: 12),
              _Buttons(onTakePhoto: onTakePhoto, onChooseImage: onChooseImage),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shot itself, with the replace buttons over a darkened foot so they read
/// on any image.
class _Preview extends StatelessWidget {
  final LocalFile file;
  final double height;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseImage;

  const _Preview({
    required this.file,
    required this.height,
    required this.onTakePhoto,
    required this.onChooseImage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(file.path),
              fit: BoxFit.cover,
              // A shot the platform can't decode still gets a sensible
              // background instead of an error box.
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.primaryTint,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primaryVariant,
                  size: 40,
                ),
              ),
            ),
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
              child: InkWell(onTap: onTakePhoto),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: _Buttons(
                onTakePhoto: onTakePhoto,
                onChooseImage: onChooseImage,
                background: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseImage;

  /// Defaults to a light primary tint; the preview passes white.
  final Color? background;

  const _Buttons({
    required this.onTakePhoto,
    required this.onChooseImage,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SmallButton(
          icon: Icons.photo_camera_outlined,
          label: l10n.timeCorrectionTakePhoto,
          onTap: onTakePhoto,
          background: background,
        ),
        widthBx(w: 8),
        _SmallButton(
          icon: Icons.photo_library_outlined,
          label: l10n.offsiteChooseImage,
          onTap: onChooseImage,
          background: background,
        ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
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

class _FileRow extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _FileRow({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.image_outlined,
            size: 20,
            color: AppColors.primaryVariant,
          ),
          widthBx(w: 8),
          Flexible(
            child: customText(name, fontSize: 14, color: AppColors.textPrimary),
          ),
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
