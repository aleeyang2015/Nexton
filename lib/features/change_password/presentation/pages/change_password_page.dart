import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../../auth/presentation/widgets/auth_password_field.dart';
import '../providers/change_password_notifier.dart';
import '../providers/change_password_state.dart';

/// Change-password screen. Holds only text controllers and focus nodes —
/// every decision lives in [ChangePasswordNotifier].
///
/// Reached two ways: a login that came back `must_change_password: true`
/// (the router pins the user here until it is done), or a voluntary change.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// React to the outcome of a submit: leave on success, surface errors.
  void _onSubmissionChanged(AsyncValue<bool>? previous, AsyncValue<bool> next) {
    final l10n = AppLocalizations.of(context)!;

    if (next.valueOrNull == true) {
      AppToast.success(l10n.changePasswordSuccess);
      // The session has already dropped the requirement; the redirect would
      // move us anyway, this just makes the intent explicit.
      context.go('/');
      return;
    }

    if (next.hasError) {
      final error = next.error;
      final message = error is Failure
          ? error.localize(l10n)
          : l10n.genericError;

      AppToast.error(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      changePasswordNotifierProvider.select((state) => state.submission),
      _onSubmissionChanged,
    );

    ref.listen(
      changePasswordNotifierProvider.select(
        (state) => state.currentPasswordClearTick,
      ),
      (_, __) => _currentController.clear(),
    );

    final state = ref.watch(changePasswordNotifierProvider);
    final notifier = ref.read(changePasswordNotifierProvider.notifier);
    final forced = ref.watch(
      authSessionProvider.select(
        (session) => session.valueOrNull?.mustChangePassword ?? false,
      ),
    );
    final l10n = AppLocalizations.of(context)!;

    // While the change is mandatory there is no back destination — signing
    // out is the only way off this screen.
    return PopScope(
      canPop: !forced,
      child: Scaffold(
        backgroundColor: AppColors.homeBackground,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryTint, Colors.white],
            ),
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  _TopBar(showBack: !forced),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SecurityBanner(forced: forced),
                          heightBx(h: 20),
                          _form(state, notifier, l10n),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      children: [
                        _submit(state, notifier, l10n),
                        if (forced) ...[
                          heightBx(h: 8),
                          TextButton(
                            onPressed: notifier.signOut,
                            child: customText(
                              l10n.logout,
                              color: AppColors.subTitle,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(
    ChangePasswordState state,
    ChangePasswordNotifier notifier,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthPasswordField(
          soft: true,
          prefixIcon: Icons.key_outlined,
          label: l10n.currentPassword,
          hint: l10n.currentPasswordHint,
          controller: _currentController,
          focusNode: _currentFocus,
          obscure: state.obscureCurrent,
          errorText: localizeFieldError(l10n, state.currentError),
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
          onToggleObscure: notifier.toggleCurrentVisibility,
          onChanged: notifier.currentPasswordChanged,
          onSubmitted: (_) => _newFocus.requestFocus(),
        ),
        heightBx(h: 20),
        AuthPasswordField(
          soft: true,
          prefixIcon: Icons.lock_outline,
          label: l10n.newPassword,
          hint: l10n.newPasswordHint,
          controller: _newController,
          focusNode: _newFocus,
          obscure: state.obscureNew,
          errorText: localizeFieldError(l10n, state.newError),
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
          onToggleObscure: notifier.toggleNewVisibility,
          onChanged: notifier.newPasswordChanged,
          onSubmitted: (_) => _confirmFocus.requestFocus(),
        ),
        heightBx(h: 10),
        _PasswordRule(
          label: l10n.newPasswordHint,
          met: state.newPasswordLongEnough,
        ),
        heightBx(h: 20),
        AuthPasswordField(
          soft: true,
          prefixIcon: Icons.verified_user_outlined,
          label: l10n.confirmNewPassword,
          hint: l10n.confirmNewPasswordHint,
          controller: _confirmController,
          focusNode: _confirmFocus,
          obscure: state.obscureConfirm,
          errorText: localizeFieldError(l10n, state.confirmError),
          enabled: !state.isSubmitting,
          onToggleObscure: notifier.toggleConfirmVisibility,
          onChanged: notifier.confirmPasswordChanged,
          onSubmitted: (_) => notifier.submit(),
        ),
      ],
    );
  }

  Widget _submit(
    ChangePasswordState state,
    ChangePasswordNotifier notifier,
    AppLocalizations l10n,
  ) {
    if (state.isSubmitting) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return _SaveButton(
      label: l10n.savePassword,
      onPressed: notifier.submit,
      enabled: state.canSubmit,
    );
  }
}

/// Round white back button, centered title, and a small shield mark opposite
/// it. The back button is left out while the change is mandatory, since there
/// is nowhere to go back to; the space is kept so the title stays centered.
class _TopBar extends StatelessWidget {
  final bool showBack;

  const _TopBar({required this.showBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: showBack
                ? GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: customText(
              l10n.changePassword,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              alight: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lock tile plus a short heading and line of guidance, on a soft blue card.
/// The body says why the user is here: mandatory first-login change or a
/// voluntary one.
class _SecurityBanner extends StatelessWidget {
  final bool forced;

  const _SecurityBanner({required this.forced});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryTint, Colors.white.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 22,
              color: Colors.white,
            ),
          ),
          widthBx(w: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  l10n.changePasswordSecurityTitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  maxLine: 2,
                ),
                heightBx(h: 4),
                customText(
                  forced
                      ? l10n.changePasswordForcedNotice
                      : l10n.changePasswordVoluntaryNotice,
                  fontSize: 12,
                  color: AppColors.subTitle,
                  maxLine: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One requirement under the new-password field — a small tick that lights up
/// blue once [met].
class _PasswordRule extends StatelessWidget {
  final String label;
  final bool met;

  const _PasswordRule({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: met ? AppColors.primaryTint : AppColors.gray100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: met
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.gray300,
              ),
            ),
            child: met
                ? const Icon(Icons.check, size: 13, color: AppColors.primary)
                : null,
          ),
          widthBx(w: 8),
          Expanded(
            child: customText(
              label,
              fontSize: 12,
              color: AppColors.secondaryTxt,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width blue gradient "save" button. Stays an
/// [ElevatedButton] underneath — the gradient sits behind its transparent
/// surface — and greys out while [enabled] is false.
class _SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _SaveButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.primary, AppColors.primaryVariant],
              )
            : null,
        color: enabled ? null : AppColors.gray400,
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: customText(
            label,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
