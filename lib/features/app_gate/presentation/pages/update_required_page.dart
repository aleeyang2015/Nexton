import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../app_gate_providers.dart';
import '../../domain/app_gate_status.dart';
import '../providers/app_gate_notifier.dart';
import '../providers/store_launcher_provider.dart';
import '../widgets/app_gate_scaffold.dart';

/// "ມີເວີຊັນໃໝ່" (#57): this version is too old. The Update button opens
/// the store; there is no way past the screen.
class UpdateRequiredPage extends ConsumerWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gate = ref.watch(appGateProvider);
    final link = gate is AppGateUpdateRequired
        ? gate.storeLink(ref.watch(appPlatformProvider))
        : null;

    return AppGateScaffold(
      icon: Icons.system_update_outlined,
      title: l10n.updateRequiredTitle,
      body: l10n.updateRequiredBody,
      actions: [
        if (link != null)
          button(() async {
            final opened = await ref.read(storeLauncherProvider)(link);
            // A dead end otherwise: this screen has no way past it.
            if (!opened) AppToast.error(l10n.genericError);
          }, l10n.updateRequiredButton)
        else
          customText(
            l10n.updateFromAppStore,
            fontSize: 14,
            color: AppColors.primary,
            alight: TextAlign.center,
            maxLine: 2,
          ),
      ],
    );
  }
}
