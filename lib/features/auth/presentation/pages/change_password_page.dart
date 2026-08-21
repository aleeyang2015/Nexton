import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
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
    if (next.valueOrNull == true) {
      _showMessage('ປ່ຽນລະຫັດຜ່ານສຳເລັດ', AppColors.success);
      // The session has already dropped the requirement; the redirect would
      // move us anyway, this just makes the intent explicit.
      context.go('/');
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
                  _header(forced),
                  heightBx(h: 30),
                  _form(state, notifier),
                  heightBx(h: 30),
                  _submit(state, notifier),
                  heightBx(h: 16),
                  _signOut(state, notifier),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool forced) {
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
          "ປ່ຽນລະຫັດຜ່ານ",
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 26,
        ),
        heightBx(h: 8),
        customText(
          forced
              ? "ກະລຸນາຕັ້ງລະຫັດຜ່ານໃໝ່ກ່ອນເຂົ້ານຳໃຊ້ລະບົບ"
              : "ຕັ້ງລະຫັດຜ່ານໃໝ່ສຳລັບບັນຊີຂອງທ່ານ",
          color: AppColors.textTertiary,
          maxLine: 2,
        ),
      ],
    );
  }

  Widget _form(ChangePasswordState state, ChangePasswordNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthPasswordField(
          label: "ລະຫັດຜ່ານປັດຈຸບັນ",
          hint: "ປ້ອນລະຫັດຜ່ານປັດຈຸບັນ",
          controller: _currentController,
          focusNode: _currentFocus,
          obscure: state.obscureCurrent,
          errorText: state.currentError,
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
          onToggleObscure: notifier.toggleCurrentVisibility,
          onChanged: notifier.currentPasswordChanged,
          onSubmitted: (_) => _newFocus.requestFocus(),
        ),
        heightBx(h: 20),
        AuthPasswordField(
          label: "ລະຫັດຜ່ານໃໝ່",
          hint: "ຢ່າງໜ້ອຍ 8 ຕົວອັກສອນ",
          controller: _newController,
          focusNode: _newFocus,
          obscure: state.obscureNew,
          errorText: state.newError,
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
          onToggleObscure: notifier.toggleNewVisibility,
          onChanged: notifier.newPasswordChanged,
          onSubmitted: (_) => _confirmFocus.requestFocus(),
        ),
        heightBx(h: 20),
        AuthPasswordField(
          label: "ຢືນຢັນລະຫັດຜ່ານໃໝ່",
          hint: "ປ້ອນລະຫັດຜ່ານໃໝ່ອີກຄັ້ງ",
          controller: _confirmController,
          focusNode: _confirmFocus,
          obscure: state.obscureConfirm,
          errorText: state.confirmError,
          enabled: !state.isSubmitting,
          onToggleObscure: notifier.toggleConfirmVisibility,
          onChanged: notifier.confirmPasswordChanged,
          onSubmitted: (_) => notifier.submit(),
        ),
      ],
    );
  }

  Widget _submit(ChangePasswordState state, ChangePasswordNotifier notifier) {
    if (state.isSubmitting) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return button(notifier.submit, "ບັນທຶກລະຫັດຜ່ານ", enabled: state.canSubmit);
  }

  Widget _signOut(ChangePasswordState state, ChangePasswordNotifier notifier) {
    return Center(
      child: TextButton(
        onPressed: state.isSubmitting ? null : notifier.signOut,
        child: underLineTxt(
          "ອອກຈາກລະບົບ",
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
