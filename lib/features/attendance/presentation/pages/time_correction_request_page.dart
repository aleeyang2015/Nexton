import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/time_correction_form_notifier.dart';
import '../providers/time_correction_form_state.dart';
import '../widgets/time_correction_attachment.dart';
import '../widgets/time_correction_fields.dart';
import '../widgets/time_correction_section_card.dart';

/// "ແກ້ໄຂເວລາເຂົ້າ ອອກວຽກ" — the time-correction request form behind the
/// "ລືມລົງເວລາ" menu tile. Fields and rules live in
/// [timeCorrectionFormNotifierProvider]; this page only renders them and
/// opens the pickers.
///
/// No time-correction endpoint exists yet, so submitting only shows the
/// "coming soon" toast.
class TimeCorrectionRequestPage extends ConsumerWidget {
  const TimeCorrectionRequestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(timeCorrectionFormNotifierProvider);
    final notifier = ref.read(timeCorrectionFormNotifierProvider.notifier);

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
                    if (state.shift != null) ...[
                      heightBx(h: 14),
                      TimeCorrectionSectionCard(
                        title: l10n.timeCorrectionShiftLabel,
                        required: true,
                        trailing: TimeCorrectionBadge(label: state.shift!.code),
                        child: TimeCorrectionShiftCard(
                          shift: state.shift!,
                          onChange: () => AppToast.info(l10n.comingSoon),
                        ),
                      ),
                    ],
                    heightBx(h: 14),
                    _TimesRow(state: state, notifier: notifier),
                    heightBx(h: 14),
                    TimeCorrectionSectionCard(
                      title: l10n.timeCorrectionReasonLabel,
                      required: true,
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
                    TimeCorrectionSectionCard(
                      title: l10n.timeCorrectionAttachmentLabel,
                      child: TimeCorrectionAttachment(
                        file: state.attachment,
                        fileBytes: state.attachmentBytes,
                        onChooseFile: () => _pickFile(l10n, notifier),
                        // Camera capture needs a package the app doesn't
                        // ship yet (e.g. image_picker).
                        onTakePhoto: () => AppToast.info(l10n.comingSoon),
                        onRemove: notifier.clearAttachment,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
            child: _SubmitButton(
              enabled: state.canSubmit,
              onTap: () => AppToast.info(l10n.comingSoon),
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
      firstDate: today.subtract(const Duration(days: 90)),
      lastDate: today,
    );
    if (picked != null) notifier.setDate(picked);
  }

  Future<void> _pickFile(
    AppLocalizations l10n,
    TimeCorrectionFormNotifier notifier,
  ) async {
    final error = await notifier.pickAttachment();
    if (error == TimeCorrectionAttachmentError.tooLarge) {
      AppToast.error(l10n.timeCorrectionFileTooLarge);
    }
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
        if (!state.hasValidTimes) ...[
          heightBx(h: 8),
          customText(
            l10n.timeCorrectionInvalidTimes,
            fontSize: 13,
            color: AppColors.danger,
          ),
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

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SubmitButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
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
        child: Row(
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
