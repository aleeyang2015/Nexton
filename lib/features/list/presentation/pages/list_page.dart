import 'package:flutter/material.dart';

import '../../../../core/widgets/coming_soon_page.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "ລາຍການ" tab. Placeholder until this feature has real content.
class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ComingSoonPage(title: l10n.navList, icon: Icons.list_alt);
  }
}
