import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../../../time_off/domain/entities/local_file.dart';
import '../../domain/entities/time_correction_request.dart';
import '../providers/time_correction_attachment_notifier.dart';
import '../providers/time_correction_form_notifier.dart';
import '../providers/time_correction_form_state.dart';
import '../widgets/attendance_copy.dart';
import '../widgets/time_correction_attachment.dart';
import '../widgets/time_correction_fields.dart';
import '../widgets/time_correction_section_card.dart';
import '../widgets/time_correction_shift_sheet.dart';

/// "ແກ້ໄຂເວລາເຂົ້າ ອອກວຽກ" — the time-correction request form behind the
/// "ລືມລົງເວລາ" menu tile. Fields and rules live in
/// [timeCorrectionFormNotifierProvider]; this page only renders them, opens
/// the pickers, and reports how the submission went.
class TimeCorrectionRequestPage extends ConsumerWidget {
  const TimeCorrectionRequestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(timeCorrectionFormNotifierProvider);
    final notifier = ref.read(timeCorrectionFormNotifierProvider.notifier);
    // Watched here too so the file stays held for the page's lifetime, and so
    // submit waits for an upload still in flight.
    final uploading = ref
        .watch(timeCorrectionAttachmentNotifierProvider)
        .isLoading;

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
                    const TimeCorrectionNotice(),
                    heightBx(h: 14),
                    TimeCorrectionSectionCard(
                      title: l10n.timeCorrectionDateLabel,
                      required: true,
                      errorText: _error(l10n, state, TimeCorrectionFields.date),
                      child: TimeCorrectionDateField(
                        date: state.date,
                        onTap: () => _pickDate(context, notifier, state.date),
                      ),
                    ),
                    heightBx(h: 14),
                    TimeCorrectionSectionCard(
                      title: l10n.timeCorrectionTypeLabel,
                      required: true,
                      child: TimeCorrectionTypeSelector(
                        selected: state.type,
                        onSelect: notifier.setType,
                      ),
                    ),
                    heightBx(h: 14),
                    _ShiftSection(state: state, notifier: notifier),
                    heightBx(h: 14),
                    _TimesRow(state: state, notifier: notifier),
                    heightBx(h: 14),
                    TimeCorrectionSectionCard(
                      title: l10n.timeCorrectionReasonLabel,
                      required: true,
                      errorText: _error(
                        l10n,
                        state,
                        TimeCorrectionFields.reason,
                      ),
                      trailing: customText(
                        '${state.reason.length} / '
                        '${TimeCorrectionFormState.reasonMaxLength}',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subTitle,
                      ),
                      child: _ReasonField(onChanged: notifier.setReason),
                    ),
                    heightBx(h: 14),
                    const _AttachmentSection(),
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

  Future<void> _pickDate(
    BuildContext context,
    TimeCorrectionFormNotifier notifier,
    DateTime current,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: today.subtract(
        const Duration(days: AppConstants.timeCorrectionMaxAgeDays),
      ),
      lastDate: today,
    );
    if (picked != null) notifier.setDate(picked);
  }

  /// Submits, then either leaves the page with a success toast or toasts
  /// why it didn't go through. Field errors also appear under their cards.
  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = timeCorrectionFormNotifierProvider;

    final ok = await ref.read(provider.notifier).submit();
    if (!context.mounted) return;

    if (ok) {
      AppToast.success(l10n.timeCorrectionSubmitSuccess);
      context.pop();
      return;
    }

    final error = ref.read(provider).submission.error;
    AppToast.error(error is Failure ? error.localize(l10n) : l10n.genericError);
  }
}

/// The evidence file card. Same workflow as the leave form: the file is
/// uploaded (`POST /uploads`) as soon as it is picked, and the outcome is
/// toasted; submit then sends the accepted file as `attachment_url`.
class _AttachmentSection extends ConsumerWidget {
  const _AttachmentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = timeCorrectionAttachmentNotifierProvider;
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
      title: l10n.timeCorrectionAttachmentLabel,
      child: TimeCorrectionAttachment(
        file: upload.valueOrNull,
        uploading: upload.isLoading,
        onChooseFile: () => _pickFile(ref, l10n),
        onTakePhoto: () => _takePhoto(context, ref, l10n),
        onRemove: ref.read(provider.notifier).clear,
      ),
    );
  }

  Future<void> _pickFile(WidgetRef ref, AppLocalizations l10n) async {
    _reportRejection(
      l10n,
      await ref
          .read(timeCorrectionAttachmentNotifierProvider.notifier)
          .pickAndUpload(),
    );
  }

  /// Opens the camera screen and uploads the photo it returns, exactly as a
  /// chosen file would be.
  Future<void> _takePhoto(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final photo = await context.push<LocalFile>(AppRoutes.cameraCapture);
    if (photo == null) return;
    _reportRejection(
      l10n,
      await ref
          .read(timeCorrectionAttachmentNotifierProvider.notifier)
          .upload(photo),
    );
  }

  void _reportRejection(
    AppLocalizations l10n,
    TimeCorrectionAttachmentError? error,
  ) {
    if (error == TimeCorrectionAttachmentError.tooLarge) {
      AppToast.error(l10n.timeCorrectionFileTooLarge);
    }
  }
}

/// [field]'s validation message in the active language, or null.
String? _error(
  AppLocalizations l10n,
  TimeCorrectionFormState state,
  String field,
) => localizeFieldError(l10n, state.errorFor(field));

/// The employee's assigned shift and the segment picked for the correction.
/// Nothing shows while the profile is loading; an employee with no shift
/// sees a notice instead, and submitting explains it can't be filed.
class _ShiftSection extends ConsumerWidget {
  final TimeCorrectionFormState state;
  final TimeCorrectionFormNotifier notifier;

  const _ShiftSection({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final profile = ref.watch(profileNotifierProvider);
    final detail = state.shiftDetail;
    final error = _error(l10n, state, TimeCorrectionFields.shift);

    if (detail == null) {
      if (profile.isLoading && error == null) return const SizedBox.shrink();
      return TimeCorrectionSectionCard(
        title: l10n.timeCorrectionShiftLabel,
        required: true,
        errorText: error,
        child: customText(
          l10n.timeCorrectionNoShift,
          fontSize: 14,
          color: AppColors.secondaryTxt,
        ),
      );
    }

    final value = profile.valueOrNull;
    final details = value?.shiftDetails ?? const [];
    final shiftName =
        AttendanceCopy.employeeShiftName(
          locale,
          value?.shiftName,
          value?.shiftNameLo,
        ) ??
        AttendanceCopy.shiftDetailName(locale, detail);
    final segmentName = AttendanceCopy.shiftDetailName(locale, detail);

    return TimeCorrectionSectionCard(
      title: l10n.timeCorrectionShiftLabel,
      required: true,
      errorText: error,
      trailing: segmentName.isEmpty
          ? null
          : TimeCorrectionBadge(label: segmentName),
      child: TimeCorrectionShiftCard(
        name: shiftName,
        hours: AttendanceCopy.shiftDetailHours(detail),
        onChange: details.length < 2
            ? null
            : () async {
                final picked = await showTimeCorrectionShiftSheet(
                  context,
                  details: details,
                  selected: detail,
                );
                if (picked != null) notifier.selectShiftDetail(picked);
              },
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
              l10n.timeCorrectionTitle,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Material(
            color: AppColors.primaryVariant,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => context.push(AppRoutes.profile),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The clock-in / clock-out cards side by side. Only the times the chosen
/// correction type needs are shown.
class _TimesRow extends StatelessWidget {
  final TimeCorrectionFormState state;
  final TimeCorrectionFormNotifier notifier;

  const _TimesRow({required this.state, required this.notifier});

  Future<void> _pick(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = state.type;
    final timesError = _error(l10n, state, TimeCorrectionFields.times);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type.needsClockIn)
              Expanded(
                child: TimeCorrectionSectionCard(
                  title: l10n.timeCorrectionClockInLabel,
                  required: true,
                  child: TimeCorrectionTimeField(
                    time: state.clockIn,
                    icon: Icons.alarm_on,
                    onTap: () =>
                        _pick(context, state.clockIn, notifier.setClockIn),
                  ),
                ),
              ),
            if (type.needsClockIn && type.needsClockOut) widthBx(w: 12),
            if (type.needsClockOut)
              Expanded(
                child: TimeCorrectionSectionCard(
                  title: l10n.timeCorrectionClockOutLabel,
                  required: true,
                  child: TimeCorrectionTimeField(
                    time: state.clockOut,
                    icon: Icons.alarm_off,
                    onTap: () =>
                        _pick(context, state.clockOut, notifier.setClockOut),
                  ),
                ),
              ),
          ],
        ),
        if (timesError != null) ...[
          heightBx(h: 8),
          customText(timesError, fontSize: 13, color: AppColors.danger),
        ],
      ],
    );
  }
}

/// The reason text box. Stateful only to own its [TextEditingController];
/// the text itself lives in the form notifier.
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
      minLines: 4,
      maxLines: 6,
      maxLength: TimeCorrectionFormState.reasonMaxLength,
      onChanged: widget.onChanged,
      style: AppTextStyles.inputStyle,
      decoration: InputDecoration(
        hintText: l10n.timeCorrectionReasonHint,
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

/// Always tappable so a blocked submit can explain itself; disabled only
/// while a submission is in flight.
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
                    l10n.timeCorrectionSubmit,
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
