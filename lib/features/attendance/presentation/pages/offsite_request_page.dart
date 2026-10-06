import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/local_file.dart';
import '../../domain/entities/offsite_method.dart';
import '../../domain/entities/offsite_outcome.dart';
import '../../domain/entities/offsite_request.dart';
import '../providers/offsite_form_notifier.dart';
import '../providers/offsite_form_state.dart';
import '../providers/offsite_photo_notifier.dart';
import '../widgets/offsite_fields.dart';
import '../widgets/offsite_photo_field.dart';
import '../widgets/offsite_copy.dart';
import '../widgets/time_correction_section_card.dart';

/// "ສະແກນນອກພື້ນທີ່" — the off-site scan request form behind its menu tile.
///
/// Reached when a punch lands outside every geofence: the employee files the
/// scan with their position, a photo and a reason, and the backend either
/// records the punch straight away (they hold `can_work_offsite`) or holds the
/// request for HR. Fields and rules live in [offsiteFormNotifierProvider]; this
/// page renders them, opens the camera, and reports how it went.
///
/// [method] is the direction the form opens on — the punch that was refused,
/// when [PunchFlow] sent the employee here, so they don't have to restate it.
class OffsiteRequestPage extends ConsumerWidget {
  /// Which punch the scan stands in for when the form opens. Defaults to
  /// clocking out: that is the direction the history page's "new scan" button
  /// implies no answer about, and the commonest reason to file one by hand.
  final OffsiteMethod method;

  const OffsiteRequestPage({super.key, this.method = OffsiteMethod.checkOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = offsiteFormNotifierProvider(method);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    // Watched here too so the photo stays held for the page's lifetime, and so
    // submit waits for an upload still in flight.
    final uploading = ref.watch(offsitePhotoNotifierProvider).isLoading;

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              const _Header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                  children: [
                    const _Notice(),
                    heightBx(h: 14),
                    TimeCorrectionSectionCard(
                      title: l10n.offsiteMethodLabel,
                      required: true,
                      child: OffsiteMethodSelector(
                        selected: state.method,
                        onSelect: notifier.setMethod,
                      ),
                    ),
                    heightBx(h: 14),
                    TimeCorrectionSectionCard(
                      title: l10n.offsiteLocationLabel,
                      required: true,
                      errorText: _error(l10n, state, OffsiteFields.location),
                      child: OffsiteLocationCard(
                        location: state.location,
                        onRetry: notifier.readLocation,
                      ),
                    ),
                    heightBx(h: 14),
                    TimeCorrectionSectionCard(
                      title: l10n.offsiteReasonLabel,
                      required: true,
                      errorText: _error(l10n, state, OffsiteFields.reason),
                      trailing: customText(
                        '${state.reason.length} / '
                        '${OffsiteFormState.reasonMaxLength}',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subTitle,
                      ),
                      child: _ReasonField(onChanged: notifier.setReason),
                    ),
                    heightBx(h: 14),
                    _PhotoSection(
                      errorText: _error(l10n, state, OffsiteFields.photo),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
            child: _SubmitButton(
              loading: state.isSubmitting || uploading,
              onTap: () => _submit(context, ref),
            ),
          ),
        ),
      ),
    );
  }

  /// Submits, then either leaves the page or says why the scan didn't count.
  ///
  /// The three answers are kept apart on purpose: a filed request leaves with
  /// a success toast, a session rule's refusal is a warning the user stays on
  /// the page to act on (switch direction, come back later), and only a
  /// request that never reached a verdict reads as an error.
  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = offsiteFormNotifierProvider(method);

    final outcome = await ref.read(provider.notifier).submit();
    if (!context.mounted) return;

    switch (outcome) {
      case OffsiteFiled(:final submission):
        AppToast.success(OffsiteCopy.filed(l10n, submission));
        context.pop();
      case OffsiteBlocked():
        AppToast.warning(OffsiteCopy.blocked(l10n, outcome));
      case null:
        final error = ref.read(provider).submission.error;
        AppToast.error(
          error is Failure ? error.localize(l10n) : l10n.genericError,
        );
    }
  }
}

/// [field]'s validation message in the active language, or null.
String? _error(AppLocalizations l10n, OffsiteFormState state, String field) =>
    localizeFieldError(l10n, state.errorFor(field));

/// The photo card. The file is uploaded (`POST /uploads`) as soon as it is
/// taken and the outcome is toasted; submit then sends the accepted file as
/// §3's `attachments` object.
class _PhotoSection extends ConsumerWidget {
  final String? errorText;

  const _PhotoSection({this.errorText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = offsitePhotoNotifierProvider;
    final upload = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        final error = next.error;
        AppToast.error(
          error is Failure
              ? error.localize(l10n)
              : l10n.leaveAttachUploadFailed,
        );
      } else if (next.valueOrNull != null &&
          next.valueOrNull != previous?.valueOrNull) {
        AppToast.success(l10n.leaveAttachUploaded);
      }
    });

    return TimeCorrectionSectionCard(
      title: l10n.offsitePhotoLabel,
      required: true,
      errorText: errorText,
      child: OffsitePhotoField(
        photo: upload.valueOrNull,
        uploading: upload.isLoading,
        onTakePhoto: () => _takePhoto(context, ref, l10n),
        onChooseImage: () => _chooseImage(ref, l10n),
        onRemove: ref.read(provider.notifier).clear,
      ),
    );
  }

  /// Opens the camera screen and uploads the photo it returns.
  Future<void> _takePhoto(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final photo = await context.push<LocalFile>(AppRoutes.cameraCapture);
    if (photo == null) return;
    _reportRejection(
      l10n,
      await ref.read(offsitePhotoNotifierProvider.notifier).upload(photo),
    );
  }

  Future<void> _chooseImage(WidgetRef ref, AppLocalizations l10n) async {
    _reportRejection(
      l10n,
      await ref.read(offsitePhotoNotifierProvider.notifier).pickAndUpload(),
    );
  }

  void _reportRejection(AppLocalizations l10n, OffsitePhotoError? error) {
    if (error == OffsitePhotoError.tooLarge) {
      AppToast.error(l10n.timeCorrectionFileTooLarge);
    }
  }
}

/// Why this form exists and what happens to what it files — including that an
/// employee cleared for off-site work has their punch recorded immediately.
class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.wrong_location_outlined,
              color: AppColors.primaryVariant,
              size: 22,
            ),
          ),
          widthBx(w: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  l10n.offsiteNoticeTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                heightBx(h: 2),
                customText(
                  l10n.offsiteNoticeBody,
                  fontSize: 13,
                  color: AppColors.secondaryTxt,
                  maxLine: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
      child: Row(
        children: [
          GestureDetector(onTap: () => context.pop(), child: popBack()),
          widthBx(w: 4),
          Expanded(
            child: customText(
              l10n.offsiteTitle,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The reason text box. Stateful only to own its [TextEditingController]; the
/// text itself lives in the form notifier.
class _ReasonField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const _ReasonField({required this.onChanged});

  @override
  State<_ReasonField> createState() => _ReasonFieldState();
}

class _ReasonFieldState extends State<_ReasonField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: _controller,
      minLines: 3,
      maxLines: 5,
      maxLength: OffsiteFormState.reasonMaxLength,
      onChanged: widget.onChanged,
      style: AppTextStyles.inputStyle,
      decoration: InputDecoration(
        hintText: l10n.offsiteReasonHint,
        hintStyle: AppTextStyles.hintStyle,
        counterText: '',
        filled: true,
        fillColor: AppColors.primaryTint,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Always tappable so a blocked submit can explain itself; disabled only while
/// a submission or an upload is in flight.
class _SubmitButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _SubmitButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryVariant,
          disabledBackgroundColor: AppColors.gray400,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  customText(
                    l10n.offsiteSubmit,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  widthBx(w: 8),
                  const Icon(Icons.send_outlined, size: 20),
                ],
              ),
      ),
    );
  }
}
