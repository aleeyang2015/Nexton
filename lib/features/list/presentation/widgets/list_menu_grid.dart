import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One tappable entry in [ListMenuGrid]
class ListMenuEntry {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const ListMenuEntry(this.label, this.icon, {this.onTap});
}

/// Grid of list shortcuts: 3 columns per row, sized to fit its entries.
///
/// [compact] switches to the shorter, smaller-radius tiles the home screen
/// uses; the "ລາຍການ" tab keeps the default tall tiles.
class ListMenuGrid extends StatelessWidget {
  final List<ListMenuEntry> entries;
  final bool compact;

  const ListMenuGrid({super.key, required this.entries, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: compact ? 12 : 14,
        mainAxisSpacing: compact ? 12 : 14,
        childAspectRatio: compact ? 0.94 : 0.8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) =>
          _MenuItem(entry: entries[index], compact: compact),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final ListMenuEntry entry;
  final bool compact;

  const _MenuItem({required this.entry, required this.compact});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 18 : 20);
    final circle = compact ? 48.0 : 60.0;

    return Material(
      color: Colors.white,
      borderRadius: radius,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: entry.onTap,
          borderRadius: radius,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: circle,
                width: circle,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.icon,
                  size: compact ? 24 : 28,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: compact ? 12 : 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
