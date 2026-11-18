import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/app_gate_status.dart';
import '../providers/app_gate_notifier.dart';
import '../widgets/app_gate_scaffold.dart';

/// "ລະບົບກຳລັງປັບປຸງ" (#57): the server's maintenance message, and Retry.
class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gate = ref.watch(appGateProvider);
    final message = gate is AppGateMaintenance ? gate.message : null;

    return AppGateScaffold(
      icon: Icons.construction_outlined,
      title: l10n.maintenanceTitle,
      body: message ?? l10n.maintenanceDefaultBody,
      actions: [
        button(() => ref.read(appGateProvider.notifier).retry(), l10n.retry),
      ],
    );
  }
}
