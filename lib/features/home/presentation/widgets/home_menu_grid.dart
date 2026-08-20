import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One tappable entry in [HomeMenuGrid]
class HomeMenuEntry {
  final String label;
  final IconData icon;

  const HomeMenuEntry(this.label, this.icon);
}

/// Responsive grid of home shortcuts: 5 columns on tablets, 4 on phones
class HomeMenuGrid extends StatelessWidget {
  final List<HomeMenuEntry> entries;

  const HomeMenuGrid({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return SizedBox(
      height: 300,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 5 : 4,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) => _MenuItem(entry: entries[index]),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final HomeMenuEntry entry;

  const _MenuItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Icon(entry.icon, size: 24, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              entry.label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
