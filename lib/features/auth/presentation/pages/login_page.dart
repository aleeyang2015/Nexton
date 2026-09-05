import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/auth_session.dart';
import '../providers/login_notifier.dart';
import '../providers/login_state.dart';
import '../widgets/login_email_field.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/remember_me_checkbox.dart';

/// Login screen. Holds only text controllers — every decision lives in
/// [LoginNotifier].
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// React to the outcome of a submit: navigate on success, surface errors.
  void _onSubmissionChanged(
    AsyncValue<AuthSession?>? previous,
    AsyncValue<AuthSession?> next,
  ) {
    final session = next.valueOrNull;
    if (session != null) {
      // A session flagged `must_change_password` goes straight to the change
      // screen; the router redirect enforces the same rule if this is missed.
      context.go(session.mustChangePassword ? '/change-password' : '/');
      return;
    }

    if (next.hasError) {
      final l10n = AppLocalizations.of(context)!;
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
      loginNotifierProvider.select((state) => state.submission),
      _onSubmissionChanged,
    );

    // The notifier decides when a rejected password must be re-typed; the page
    // only carries that decision to its controller.
    ref.listen(
      loginNotifierProvider.select((state) => state.passwordClearTick),
      (_, __) => _passwordController.clear(),
    );

    final state = ref.watch(loginNotifierProvider);
    final notifier = ref.read(loginNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: _LanguageToggleButton(
                locale: locale,
                onTap: () {
                  final next = locale == AppLocales.lao
                      ? AppLocales.english
                      : AppLocales.lao;
                  ref.read(localeProvider.notifier).setLocale(next);
                },
              ),
            ),
            heightBx(h: 10),
            assetImg(
              "assets/images/polygon.png",
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            heightBx(h: 20),
            customText(
              "NEXTON",
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 40,
            ),
            heightBx(h: 40),
            customText(
              l10n.login,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              fontSize: 20,
              alight: TextAlign.center,
            ),
            heightBx(h: 40),
            _form(state, notifier, l10n),
          ],
        ),
      ),
    );
  }

  Widget _form(LoginState state, LoginNotifier notifier, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoginEmailField(
          controller: _emailController,
          errorText: localizeFieldError(l10n, state.emailError),
          onChanged: notifier.emailChanged,
        ),
        heightBx(h: 20),
        AuthPasswordField(
          label: l10n.password,
          hint: l10n.passwordHint,
          controller: _passwordController,
          obscure: state.obscurePassword,
          errorText: localizeFieldError(l10n, state.passwordError),
          onToggleObscure: notifier.togglePasswordVisibility,
          onChanged: notifier.passwordChanged,
          onSubmitted: (_) => notifier.submit(),
          trailing: customText(
            l10n.forgotPassword,
            color: Colors.blueAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
        heightBx(h: 30),
        RememberMeCheckbox(
          value: state.rememberMe,
          onTap: notifier.toggleRememberMe,
        ),
        heightBx(h: 20),
        if (state.isSubmitting)
          const Center(child: CircularProgressIndicator())
        else
          button(notifier.submit, l10n.login),
      ],
    );
  }
}

/// Switches between Lao and English right from the login screen — the only
/// screen an unauthenticated user can reach, so it can't wait for Settings.
/// Labeled with the language it switches *to*, not the current one.
class _LanguageToggleButton extends StatelessWidget {
  final Locale locale;
  final VoidCallback onTap;

  const _LanguageToggleButton({required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final targetLabel = locale == AppLocales.lao ? l10n.english : l10n.lao;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: AppColors.primary),
            widthBx(w: 4),
            customText(
              targetLabel,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
