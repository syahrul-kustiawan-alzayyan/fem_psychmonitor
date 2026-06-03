import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionCard — Kartu reusable untuk menampilkan daftar saran / rekomendasi
//
// Digunakan di:
//   • HomeScreen        → Saran psikis keseluruhan (collapsible)
//   • VoiceDetectionScreen → Saran spesifik per-emosi (collapsible)
//
// Variant:
//   • isCollapsible: false → Static card (selalu terbuka)
//   • isCollapsible: true  → Card yang bisa dilipat/dibuka oleh user
// ─────────────────────────────────────────────────────────────────────────────
class SuggestionCard extends StatelessWidget {
  final String title;
  final List<String> suggestions;
  final IconData icon;
  final Color color;
  final bool isCollapsible;

  const SuggestionCard({
    super.key,
    required this.title,
    required this.suggestions,
    this.icon = Icons.lightbulb_rounded,
    this.color = AppTheme.primaryDark,
    this.isCollapsible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsible) {
      return _CollapsibleCard(
        title: title,
        suggestions: suggestions,
        icon: icon,
        color: color,
      );
    }
    return _StaticCard(
      title: title,
      suggestions: suggestions,
      icon: icon,
      color: color,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StaticCard — Versi non-collapsible
// ─────────────────────────────────────────────────────────────────────────────
class _StaticCard extends StatelessWidget {
  final String title;
  final List<String> suggestions;
  final IconData icon;
  final Color color;

  const _StaticCard({
    required this.title,
    required this.suggestions,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header strip berwarna
          _CardHeader(title: title, icon: icon, color: color, isExpanded: true, showArrow: false),
          // Daftar saran
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg, 0, AppTheme.spaceLg, AppTheme.spaceLg),
            child: Column(
              children: suggestions
                  .asMap()
                  .entries
                  .map((e) => _SuggestionItem(
                      number: e.key + 1, text: e.value, color: color))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CollapsibleCard — Versi collapsible dengan animasi expand/collapse
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleCard extends StatefulWidget {
  final String title;
  final List<String> suggestions;
  final IconData icon;
  final Color color;

  const _CollapsibleCard({
    required this.title,
    required this.suggestions,
    required this.icon,
    required this.color,
  });

  @override
  State<_CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<_CollapsibleCard> {
  bool _expanded = true; // default terbuka

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: widget.color.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header yang bisa diklik
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: _CardHeader(
              title: widget.title,
              icon: widget.icon,
              color: widget.color,
              isExpanded: _expanded,
              showArrow: true,
            ),
          ),
          // Konten animasi
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLg, 0, AppTheme.spaceLg, AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: widget.color.withValues(alpha: 0.15),
                    height: 16,
                  ),
                  ...widget.suggestions
                      .asMap()
                      .entries
                      .map((e) => _SuggestionItem(
                          number: e.key + 1,
                          text: e.value,
                          color: widget.color)),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardHeader — Header strip dengan gradien tipis + ikon + judul
// ─────────────────────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isExpanded;
  final bool showArrow;

  const _CardHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.showArrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLg, 14, AppTheme.spaceLg, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppTheme.radiusXl),
          topRight: const Radius.circular(AppTheme.radiusXl),
          // Bila collapsed, radius bawah juga terbuka
          bottomLeft: Radius.circular(!showArrow || isExpanded ? 0 : AppTheme.radiusXl),
          bottomRight: Radius.circular(!showArrow || isExpanded ? 0 : AppTheme.radiusXl),
        ),
      ),
      child: Row(
        children: [
          // Icon dalam container kecil
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          // Judul
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
                height: 1.3,
              ),
            ),
          ),
          // Panah expand/collapse (bila collapsible)
          if (showArrow)
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: color,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuggestionItem — Satu baris saran dengan nomor circle + teks
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionItem extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _SuggestionItem({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nomor circle
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Teks saran
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textP(context),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
