import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app/app_version.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// App name, version and tagline pinned to the bottom of the login screen.
class LoginFooter extends ConsumerWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return customText(
      l10n.loginFooter(ref.watch(appVersionProvider)),
      fontSize: 12,
      color: AppColors.subTitle,
      alight: TextAlign.center,
      maxLine: 2,
    );
  }
}
