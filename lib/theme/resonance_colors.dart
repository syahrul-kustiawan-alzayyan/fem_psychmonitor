import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────
/// ResonanceColors — Palet "Resonance" (turunan brand logo — rose magenta)
///
/// Dipakai oleh AuthScreen dan halaman Onboarding agar kedua
/// layar memiliki bahasa visual yang sama: background hangat,
/// hard offset shadow, tipografi Space Grotesk / Inter / JetBrains Mono.
/// ─────────────────────────────────────────────────────────────
class ResonanceColors {
  final Color background;
  final Color surfaceLowest;
  final Color surfaceVariant;
  final Color surfaceContainer;
  final Color outline;
  final Color outlineVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final Color primaryContainer;

  const ResonanceColors({
    required this.background,
    required this.surfaceLowest,
    required this.surfaceVariant,
    required this.surfaceContainer,
    required this.outline,
    required this.outlineVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.primaryContainer,
  });

  static const light = ResonanceColors(
    background: Color(0xFFFAF6F3),
    surfaceLowest: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1EAE6),
    surfaceContainer: Color(0xFFF1EAE6),
    outline: Color(0xFFBBA8A1),
    outlineVariant: Color(0xFFE2D7D1),
    onSurface: Color(0xFF24161C),
    onSurfaceVariant: Color(0xFF5E4B53),
    primary: Color(0xFFC77E8C),
    primaryContainer: Color(0xFFF0D9DE),
  );

  static const dark = ResonanceColors(
    background: Color(0xFF211B1E),
    surfaceLowest: Color(0xFF2A2226),
    surfaceVariant: Color(0xFF3A2E33),
    surfaceContainer: Color(0xFF332A2E),
    outline: Color(0xFF8C7075),
    outlineVariant: Color(0xFF4A3B41),
    onSurface: Color(0xFFF4EDF0),
    onSurfaceVariant: Color(0xFFCBBBC1),
    primary: Color(0xFFDFAAB6),
    primaryContainer: Color(0xFF6E3A46),
  );

  static ResonanceColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Chip data mengambang (emotion readout) — elemen 3D dari desain Resonance
class FloatingChip extends StatelessWidget {
  final String label;
  final ResonanceColors color;

  const FloatingChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.surfaceLowest,
        border: Border.all(color: color.outlineVariant),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24161C).withValues(alpha: 0.1),
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2E5F6E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.4,
              color: color.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris gelombang suara dekoratif (voice-emotion motif)
class WaveformBars extends StatelessWidget {
  final ResonanceColors c;
  final double height;

  const WaveformBars({super.key, required this.c, this.height = 34});

  @override
  Widget build(BuildContext context) {
    const heights = [
      12.0, 20.0, 28.0, 16.0, 24.0, 14.0, 26.0, 18.0, 22.0, 12.0,
      20.0, 28.0, 16.0, 24.0, 14.0, 26.0, 18.0, 22.0,
    ];
    const active = [1, 3, 5, 7, 9, 11, 13, 15, 17];
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(heights.length, (i) {
          final isActive = active.contains(i);
          return Container(
            width: isActive ? 3 : 2,
            height: heights[i],
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isActive ? c.primary : c.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}

/// Eyebrow langkah onboarding: satu warna, tanpa pola per-karakter
class ResonanceEyebrow extends StatelessWidget {
  final ResonanceColors c;
  final String label;

  const ResonanceEyebrow({super.key, required this.c, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Kartu berlapis ala halaman auth: primaryContainer di belakang + border
class ResonanceCard extends StatelessWidget {
  final ResonanceColors c;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool layered;
  final Color? accent;
  final double radius;

  const ResonanceCard({
    super.key,
    required this.c,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.layered = true,
    this.accent,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = accent ?? c.outlineVariant;
    final card = Container(
      decoration: BoxDecoration(
        color: c.surfaceLowest,
        border: Border.all(
          color: borderColor,
          width: accent != null ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: padding,
      child: child,
    );
    if (!layered) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 4,
          bottom: -4,
          child: Container(
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
        card,
      ],
    );
  }
}

/// Tombol pill utama (taktil: shadow keras 4,4 mengecil saat ditekan)
class ResonancePillButton extends StatefulWidget {
  final ResonanceColors c;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? trailingIcon;

  const ResonancePillButton({
    super.key,
    required this.c,
    required this.label,
    this.onTap,
    this.loading = false,
    this.trailingIcon,
  });

  @override
  State<ResonancePillButton> createState() => _ResonancePillButtonState();
}

class _ResonancePillButtonState extends State<ResonancePillButton> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return GestureDetector(
      onTap: _enabled ? widget.onTap : null,
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: !_enabled
                ? c.surfaceVariant
                : (_pressed ? c.primary.withValues(alpha: 0.85) : c.primary),
            borderRadius: BorderRadius.circular(999),
            boxShadow: (!_enabled || _pressed)
                ? []
                : const [
                    BoxShadow(
                      color: Color(0x4024161C),
                      offset: Offset(4, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _enabled ? Colors.white : c.onSurfaceVariant,
                        ),
                      ),
                      if (widget.trailingIcon != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          widget.trailingIcon,
                          size: 18,
                          color: _enabled ? Colors.white : c.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon lingkaran (nav back/home dll.)
class ResonanceIconButton extends StatelessWidget {
  final ResonanceColors c;
  final IconData icon;
  final VoidCallback? onTap;

  const ResonanceIconButton({
    super.key,
    required this.c,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: disabled ? c.surfaceVariant : c.surfaceLowest,
            shape: BoxShape.circle,
            border: disabled
                ? null
                : Border.all(color: c.outlineVariant),
            boxShadow: disabled
                ? []
                : const [
                    BoxShadow(
                      color: Color(0x1424161C),
                      offset: Offset(2, 2),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: disabled ? c.outline : c.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Bar progres (fill primary/dimension color)
class ResonanceProgressBar extends StatelessWidget {
  final ResonanceColors c;
  final double progress;
  final Color? color;
  final double height;

  const ResonanceProgressBar({
    super.key,
    required this.c,
    required this.progress,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(
                height: height,
                width: constraints.maxWidth,
                color: c.surfaceVariant,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: height,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: color ?? c.primary,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Chip pill mono — label langkah/progress/status
class ResonanceChip extends StatelessWidget {
  final ResonanceColors c;
  final String label;
  final Color? dotColor;
  final Color? textColor;
  final IconData? icon;

  const ResonanceChip({
    super.key,
    required this.c,
    required this.label,
    this.dotColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceLowest,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1424161C),
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? c.onSurfaceVariant),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: textColor ?? c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}