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
class ListMenuGrid extends StatelessWidget {
  final List<ListMenuEntry> entries;

  const ListMenuGrid({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => _MenuItem(entry: entries[index]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final ListMenuEntry entry;

  const _MenuItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(entry.icon, size: 28, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    entry.label,
                    style: const TextStyle(
                      fontSize: 11,
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
