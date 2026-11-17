import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/ot_ask_notifier.dart';
import '../widgets/ot_copy.dart';

/// "ຂໍໂອທີ": the day, the start and end, and a reason. Send asks the
/// server; when it saves, this page is replaced by the new request's page.
/// Everything comes from [otAskNotifierProvider].
class OtAskPage extends ConsumerWidget {
  const OtAskPage({super.key});

  /// How a reason may be; the server's own limit.
  static const int reasonMaxLength = 2000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Everything the page shows but the reason, which the text field holds
    // itself: typing does not rebuild the form.
    final state = ref.watch(
      otAskNotifierProvider.select(
        (s) => (
          workDate: s.workDate,
          today: s.today,
          startTime: s.startTime,
          endTime: s.endTime,
          sending: s.sending,
          endError: s.endError,
          refusal: s.refusal,
          endsNextDay: s.endsNextDay,
          isPastDate: s.isPastDate,
          canSend: s.canSend,
        ),
      ),
    );
    final form = ref.read(otAskNotifierProvider.notifier);
    final refusal = state.refusal;

    // While a request is on its way the page stays: leaving would lose the
    // answer, and the OT list would not learn of a request that was saved.
    return PopScope(
      canPop: !state.sending,
      child: Container(
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
                        onTap: state.sending
                            ? null
                            : () => context.canPop()
                                  ? context.pop()
                                  : context.go(AppRoutes.overtime),
                        child: popBack(),
                      ),
                      widthBx(w: 4),
                      Expanded(
                        child: customText(
                          l10n.otAsk,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 40),
                    children: [
                      _Field(
                        label: l10n.otDateLabel,
                        value: OtCopy.date(state.workDate),
                        icon: Icons.calendar_today_outlined,
                        onTap: state.sending
                            ? null
                            : () => _pickDate(
                                context,
                                form,
                                workDate: state.workDate,
                                today: state.today,
                              ),
                      ),
                      if (state.isPastDate) ...[
                        heightBx(h: 8),
                        _Warning(text: l10n.otPastDateWarning),
                      ],
                      heightBx(h: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              label: l10n.otStartLabel,
                              value: state.startTime ?? '--:--',
                              icon: Icons.schedule,
                              onTap: state.sending
                                  ? null
                                  : () => _pickTime(
                                      context,
                                      ref.read(otAskNotifierProvider).start,
                                      form.setStart,
                                    ),
                            ),
                          ),
                          widthBx(w: 12),
                          Expanded(
                            child: _Field(
                              label: l10n.otEndLabel,
                              value: state.endTime ?? '--:--',
                              suffix: state.endsNextDay ? l10n.otNextDay : null,
                              icon: Icons.schedule,
                              error: state.endError
                                  ? l10n.otEndEqualsStart
                                  : null,
                              onTap: state.sending
                                  ? null
                                  : () {
                                      final now = ref.read(
                                        otAskNotifierProvider,
                                      );
                                      // End opens on itself, else on Start.
                                      _pickTime(
                                        context,
                                        now.end ?? now.start,
                                        form.setEnd,
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                      heightBx(h: 12),
                      TextField(
                        enabled: !state.sending,
                        maxLength: reasonMaxLength,
                        // maxLength counts what is seen; a Lao letter with its
                        // marks is several code points. This keeps the text
                        // within the server's 2000 however it counts them.
                        inputFormatters: const [_RuneLimit(reasonMaxLength)],
                        maxLines: 4,
                        minLines: 2,
                        onChanged: form.setReason,
                        decoration: InputDecoration(
                          labelText: l10n.otReasonOptional,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (refusal != null) ...[
                        heightBx(h: 12),
                        customText(
                          refusal.localize(l10n),
                          color: AppColors.danger,
                          maxLine: 6,
                        ),
                      ],
                      heightBx(h: 16),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: state.canSend
                              ? () => _send(context, ref)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: state.sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : customText(
                                  l10n.leaveRequestSubmit,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The picker allows a year back and a year ahead; the server decides
  /// what it takes.
  Future<void> _pickDate(
    BuildContext context,
    OtAskNotifier form, {
    required DateTime workDate,
    required DateTime today,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: workDate,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (picked != null) form.setDate(picked);
  }

  Future<void> _pickTime(
    BuildContext context,
    ({int hour, int minute})? current,
    void Function(int hour, int minute) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 18, minute: 0)
          : TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked.hour, picked.minute);
  }

  /// Sends; on success says so and replaces this page with the new
  /// request's page.
  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final sent = await ref.read(otAskNotifierProvider.notifier).submit();
    if (sent == null || !context.mounted) return;
    AppToast.success(l10n.otAskSent);
    context.pushReplacement(AppRoutes.otRequest(sent.id), extra: sent);
  }
}

/// Keeps a text within [max] code points (runes), whatever it looks like.
class _RuneLimit extends TextInputFormatter {
  final int max;

  const _RuneLimit(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= max) return newValue;
    final text = String.fromCharCodes(newValue.text.runes.take(max));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// A labelled box that opens a picker.
class _Field extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? suffix;
  final String? error;
  final VoidCallback? onTap;

  const _Field({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix,
    this.error,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final suffix = this.suffix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customText(
          label,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.subTitle,
        ),
        heightBx(h: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error == null ? AppColors.border : AppColors.danger,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                widthBx(w: 8),
                Flexible(
                  child: customText(
                    value,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (suffix != null) ...[
                  widthBx(w: 4),
                  Flexible(
                    child: customText(
                      suffix,
                      fontSize: 12,
                      color: AppColors.subTitle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (error != null) ...[
          heightBx(h: 4),
          customText(error, fontSize: 12, color: AppColors.danger, maxLine: 3),
        ],
      ],
    );
  }
}

/// The amber past-date note: a warning only.
class _Warning extends StatelessWidget {
  final String text;

  const _Warning({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.attendanceLate.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: AppColors.attendanceLate,
        ),
        widthBx(w: 8),
        Expanded(
          child: customText(
            text,
            fontSize: 13,
            color: AppColors.textPrimary,
            maxLine: 6,
          ),
        ),
      ],
    ),
  );
}
