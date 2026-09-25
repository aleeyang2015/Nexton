import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../list/presentation/widgets/list_menu_entries.dart';
import '../../../list/presentation/widgets/list_menu_grid.dart';

/// The list shortcuts, shown on the home screen under the attendance history
/// card with a "ລາຍການ" heading. Entries come from [buildListMenuEntries],
/// the same source as the "ລາຍການ" tab.
class HomeMenuGrid extends ConsumerWidget {
  const HomeMenuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entries = buildListMenuEntries(context, ref, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MenuHeader(title: l10n.navList, count: entries.length),
        heightBx(h: 14),
        ListMenuGrid(entries: entries, compact: true),
      ],
    );
  }
}

/// Blue accent bar and title on the left, a pill counting the entries on
/// the right.
class _MenuHeader extends StatelessWidget {
  final String title;
  final int count;

  const _MenuHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 5,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        widthBx(w: 10),
        Expanded(
          child: customText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: customText(
            l10n.menuItemCount(count),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTxt,
          ),
        ),
      ],
    );
  }
}
