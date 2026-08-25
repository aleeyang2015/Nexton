import 'package:flutter/material.dart';

import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Stand-in for [HomePage] while the cold-start session is still resolving —
/// same silhouette (avatar, name lines, bell, one card) so the swap to real
/// content on/off the shimmer doesn't jump.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Shimmer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              heightBx(),
              _headerRow(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 60),
                  children: [
                    ShimmerBox(
                      width: double.infinity,
                      height: 160,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        widthBx(w: 15),
        const ShimmerBox.circle(size: 60),
        widthBx(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 6),
              const ShimmerBox(width: 120, height: 16),
              heightBx(h: 8),
              const ShimmerBox(width: 90, height: 14),
            ],
          ),
        ),
        widthBx(),
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 15),
          child: const ShimmerBox(width: 30, height: 30),
        ),
      ],
    );
  }
}
