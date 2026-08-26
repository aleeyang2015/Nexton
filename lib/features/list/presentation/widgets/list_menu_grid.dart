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
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1,
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
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Icon(entry.icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                entry.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
