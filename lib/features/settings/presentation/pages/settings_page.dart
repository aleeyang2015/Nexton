import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Settings screen. Currently hosts the language switcher; the natural place
/// to grow the rest of the app's settings.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: popBack(),
                  ),
                  widthBx(w: 8),
                  customText(
                    l10n.settings,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
            heightBx(h: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: customText(
                l10n.language,
                color: AppColors.subTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            heightBx(h: 8),
            _LanguageOption(
              label: l10n.lao,
              selected: locale == AppLocales.lao,
              onTap: () =>
                  ref.read(localeProvider.notifier).setLocale(AppLocales.lao),
            ),
            _LanguageOption(
              label: l10n.english,
              selected: locale == AppLocales.english,
              onTap: () => ref
                  .read(localeProvider.notifier)
                  .setLocale(AppLocales.english),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: customText(
                label,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primary : Colors.black,
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 22)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: AppColors.border,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
