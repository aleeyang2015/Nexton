import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Sweeps a soft highlight across [child], left to right, on a loop — the
/// standard "shimmer" loading effect. Built on [ShaderMask]/[AnimationController]
/// rather than a package: the effect is one gradient and one animation, not
/// worth a dependency.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final sweep = _controller.value;
            return LinearGradient(
              colors: [
                AppColors.gray200,
                AppColors.gray100,
                AppColors.gray200,
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 - sweep * 2, 0),
              end: Alignment(1 - sweep * 2, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// A single shimmering placeholder block — a rounded rect standing in for
/// text, an avatar, or a card while real content loads.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  const ShimmerBox.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: borderRadius,
      ),
    );
  }
}
