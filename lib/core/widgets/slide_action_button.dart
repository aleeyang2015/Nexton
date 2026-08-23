import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// A drag-to-confirm control: the thumb must be dragged past [_thresholdRatio]
/// of the track before [onComplete] fires. Releasing early springs it back.
///
/// Unlike a typical slider, there is no looping/repeating animation here on
/// purpose — a repeating [AnimationController] never settles, which makes
/// `tester.pumpAndSettle()` hang in any widget test that renders this button.
class SlideActionButton extends StatefulWidget {
  const SlideActionButton({
    super.key,
    required this.label,
    required this.onComplete,
    this.icon = Icons.watch_later_outlined,
    this.enabled = true,
    this.resetAfterComplete = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;

  /// Sync handlers keep the completed (thumb-at-end) state. A throwing
  /// handler, or [resetAfterComplete], springs the thumb back to the start.
  final FutureOr<void> Function() onComplete;

  /// When true, the thumb always springs back after [onComplete] runs —
  /// for a control that has no real "done" state to lock into.
  final bool resetAfterComplete;

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with SingleTickerProviderStateMixin {
  static const double _height = 60;
  static const double _thumbSize = 48;
  static const double _pad = 6;
  static const double _thresholdRatio = 0.85;

  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );

  bool _completed = false;
  double _maxTravel = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _completed || _maxTravel <= 0) return;
    _controller.value = (_controller.value + details.delta.dx).clamp(
      0.0,
      _maxTravel,
    );
  }

  void _onDragEnd(DragEndDetails details) => _settle();

  void _onDragCancel() => _settle();

  void _settle() {
    if (!widget.enabled || _completed) return;
    final threshold = _maxTravel * _thresholdRatio;
    if (threshold > 0 && _controller.value >= threshold) {
      _completed = true;
      _controller.animateTo(
        _maxTravel,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
      );
      HapticFeedback.mediumImpact();
      _invokeComplete();
    } else {
      _springBack();
    }
  }

  Future<void> _invokeComplete() async {
    try {
      await widget.onComplete();
    } finally {
      if (mounted && widget.resetAfterComplete) {
        _completed = false;
        _springBack();
      }
    }
  }

  void _springBack() {
    _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        _maxTravel = (trackWidth - _thumbSize - _pad * 2).clamp(
          0.0,
          double.infinity,
        );

        return Container(
          height: _height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final x = _controller.value.clamp(0.0, _maxTravel);
              final progress = _maxTravel > 0 ? x / _maxTravel : 0.0;
              final labelOpacity = (1 - progress / 0.6).clamp(0.0, 1.0);
              final fillWidth = (x + _thumbSize + _pad * 2).clamp(
                0.0,
                trackWidth,
              );

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Fill trailing the thumb as it drags right.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: fillWidth,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(_height / 2),
                        ),
                      ),
                    ),
                  ),
                  // Directional chevron hint, right-anchored.
                  Positioned(
                    right: 18,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: labelOpacity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (i) => Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.secondary.withValues(
                                alpha: 0.25 + (i * 0.25),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Centered label, fading with drag progress.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _thumbSize + _pad * 2,
                        ),
                        child: Opacity(
                          opacity: labelOpacity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.icon,
                                size: 17,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Draggable thumb.
                  Positioned(
                    left: _pad + x,
                    top: _pad,
                    width: _thumbSize,
                    height: _thumbSize,
                    child: Semantics(
                      slider: true,
                      label: widget.label,
                      enabled: widget.enabled,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: widget.enabled
                            ? _onDragUpdate
                            : null,
                        onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
                        onHorizontalDragCancel: widget.enabled
                            ? _onDragCancel
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
