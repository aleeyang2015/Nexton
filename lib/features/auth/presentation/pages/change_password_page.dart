import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/auth_session_notifier.dart';
import '../providers/change_password_notifier.dart';
import '../providers/change_password_state.dart';
import '../widgets/auth_password_field.dart';

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
      _showMessage(l10n.changePasswordSuccess, AppColors.success);
      // The session has already dropped the requirement; the redirect would
      // move us anyway, this just makes the intent explicit.
      context.go('/');
      return;
    }

    if (next.hasError) {
      final error = next.error;
      final message = error is Failure ? error.localize(l10n) : l10n.genericError;

      _showMessage(message, AppColors.error);
    }
  }

  void _showMessage(String message, Color background) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: background),
      );
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(forced, l10n),
                  heightBx(h: 30),
                  _form(state, notifier, l10n),
                  heightBx(h: 30),
                  _submit(state, notifier, l10n),
                  heightBx(h: 16),
                  _signOut(state, notifier, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool forced, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        assetImg(
          "assets/images/polygon.png",
          width: 56,
          height: 56,
          fit: BoxFit.contain,
        ),
        heightBx(h: 20),
        customText(
          l10n.changePassword,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 26,
        ),
        heightBx(h: 8),
        customText(
          forced
              ? l10n.changePasswordForcedNotice
              : l10n.changePasswordVoluntaryNotice,
          color: AppColors.textTertiary,
          maxLine: 2,
        ),
      ],
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
        heightBx(h: 20),
        AuthPasswordField(
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

    return button(notifier.submit, l10n.savePassword, enabled: state.canSubmit);
  }

  Widget _signOut(
    ChangePasswordState state,
    ChangePasswordNotifier notifier,
    AppLocalizations l10n,
  ) {
    return Center(
      child: TextButton(
        onPressed: state.isSubmitting ? null : notifier.signOut,
        child: underLineTxt(
          l10n.logout,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
