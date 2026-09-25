import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One tappable entry in [ListMenuGrid]
class ListMenuEntry {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// The entry's accent — its icon, icon outline and the tint of its tile
  /// in the [ListMenuGrid.compact] style.
  final Color color;

  const ListMenuEntry(
    this.label,
    this.icon, {
    this.onTap,
    this.color = AppColors.primary,
  });
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
        childAspectRatio: compact ? 0.9 : 0.8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => compact
          ? _CompactMenuItem(entry: entries[index])
          : _MenuItem(entry: entries[index]),
    );
  }
}

/// The home screen's tile: an outlined rounded-square icon in the entry's
/// accent, on white fading into a faint wash of that accent.
class _CompactMenuItem extends StatelessWidget {
  final ListMenuEntry entry;

  const _CompactMenuItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final color = entry.color;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(color.withValues(alpha: 0.05), Colors.white),
              Colors.white,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: entry.onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
            child: Column(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(entry.icon, size: 24, color: color),
                ),
                // Labels sit centred in the space under the icon, so one-
                // and two-line labels still line up across a row.
                Expanded(
                  child: Center(
                    child: Text(
                      entry.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.3,
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
      ),
    );
  }
}

/// The "ລາຍການ" tab's taller tile.
class _MenuItem extends StatelessWidget {
  final ListMenuEntry entry;

  const _MenuItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    const circle = 60.0;

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
