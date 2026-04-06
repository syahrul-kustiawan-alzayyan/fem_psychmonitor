import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// Animation Utilities - Modern Animation Patterns
/// ─────────────────────────────────────────────────────────────

class AnimationUtils {
  /// Staggered animation for list items
  static Animation<double> staggeredAnimation(
    AnimationController controller,
    int index,
    double staggerDelay,
  ) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          index * staggerDelay,
          (index * staggerDelay) + 0.6,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  /// Slide up animation with fade
  static Animation<Offset> slideUpAnimation(
    AnimationController controller,
    int index,
    double staggerDelay,
  ) {
    return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          index * staggerDelay,
          (index * staggerDelay) + 0.5,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  /// Scale animation
  static Animation<double> scaleAnimation(
    AnimationController controller,
    int index,
    double staggerDelay,
  ) {
    return Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          index * staggerDelay,
          (index * staggerDelay) + 0.5,
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  /// Fade in animation
  static Animation<double> fadeInAnimation(
    AnimationController controller,
    int index,
    double staggerDelay,
  ) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          index * staggerDelay,
          (index * staggerDelay) + 0.4,
          curve: Curves.easeIn,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Glassmorphism Card Widget
/// ─────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? gradientStart;
  final Color? gradientEnd;
  final bool useBlur; // Add option to disable blur

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.padding,
    this.borderRadius = 24,
    this.onTap,
    this.gradientStart,
    this.gradientEnd,
    this.useBlur = true, // Default to true for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientStart ??
                (isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.7)),
            gradientEnd ??
                (isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.5)),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF3B82F6).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: useBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: child,
            )
          : child,
    );

    return GestureDetector(onTap: onTap, child: cardContent);
  }
}

/// ─────────────────────────────────────────────────────────────
/// Animated Counter Widget
/// ─────────────────────────────────────────────────────────────
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value.toStringAsFixed(1)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Shimmer Loading Effect
/// ─────────────────────────────────────────────────────────────
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9),
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ],
              transform: GradientRotation(_animation.value),
            ),
          ),
        );
      },
    );
  }
}
