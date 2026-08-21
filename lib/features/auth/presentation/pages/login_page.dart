import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
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
      final error = next.error;
      final message = error is Failure
          ? error.message
          : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            heightBx(h: 50),
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
              "ເຂົ້າສູ່ລະບົບ",
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              fontSize: 20,
              alight: TextAlign.center,
            ),
            heightBx(h: 40),
            _form(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _form(LoginState state, LoginNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoginEmailField(
          controller: _emailController,
          errorText: state.emailError,
          onChanged: notifier.emailChanged,
        ),
        heightBx(h: 20),
        AuthPasswordField(
          label: "ລະຫັດຜ່ານ",
          hint: "ປ້ອນລະຫັດຜ່ານ",
          controller: _passwordController,
          obscure: state.obscurePassword,
          errorText: state.passwordError,
          onToggleObscure: notifier.togglePasswordVisibility,
          onChanged: notifier.passwordChanged,
          onSubmitted: (_) => notifier.submit(),
          trailing: customText(
            "ລືມລະຫັດຜ່ານ ?",
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
          button(notifier.submit, "ເຂົ້າສູ່ລະບົບ"),
      ],
    );
  }
}
