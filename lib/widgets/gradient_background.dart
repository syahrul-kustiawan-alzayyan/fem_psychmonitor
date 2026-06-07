import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
/// GradientBackground - Wrapper dengan gradient biru-pink
/// 
/// Usage: Wrap screen content dengan widget ini untuk mendapatkan
/// gradient background yang konsisten di seluruh aplikasi.
/// ─────────────────────────────────────────────────────────────
class GradientBackground extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final bool useOverlay;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.useOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            (isDark
                ? AppTheme.darkGradientBackground
                : AppTheme.lightGradientBackground),
      ),
      child: useOverlay
          ? Stack(
              children: [
                // Decorative gradient circles
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.secondaryColor.withValues(alpha: 0.06),
                          AppTheme.secondaryColor.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content
                child,
              ],
            )
          : child,
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// GradientAppBar - AppBar dengan gradient biru-pink
/// ─────────────────────────────────────────────────────────────
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final double elevation;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.leading,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: elevation,
        centerTitle: centerTitle,
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: actions,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
