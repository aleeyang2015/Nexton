import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/list_menu_entries.dart';
import '../widgets/list_menu_grid.dart';
import '../widgets/list_page_header.dart';

/// "ລາຍການ" tab.
class ListPage extends ConsumerWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              ListPageHeader(title: l10n.navList),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 15),
                  child: ListMenuGrid(
                    entries: buildListMenuEntries(context, ref, l10n),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
