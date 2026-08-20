import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../providers/login_notifier.dart';
import '../providers/login_state.dart';
import '../widgets/login_email_field.dart';
import '../widgets/login_password_field.dart';
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
    AsyncValue<Object?>? previous,
    AsyncValue<Object?> next,
  ) {
    if (next.hasValue && next.value != null) {
      context.go('/');
      return;
    }

    if (next.hasError) {
      final error = next.error;
      final message =
          error is Failure ? error.message : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      loginNotifierProvider.select((state) => state.submission),
      _onSubmissionChanged,
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
        LoginPasswordField(
          controller: _passwordController,
          obscure: state.obscurePassword,
          errorText: state.passwordError,
          onToggleObscure: notifier.togglePasswordVisibility,
          onChanged: notifier.passwordChanged,
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
