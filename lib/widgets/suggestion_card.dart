import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionCard — Kartu reusable untuk menampilkan saran Big Five OCEAN
//
// Mendukung dua mode:
//   1. Multi-trait (v2): Saran dikelompokkan per trait dominan
//   2. Flat list (legacy): Saran dalam bentuk list datar
//
// Variant:
//   • isCollapsible: false → Static card (selalu terbuka)
//   • isCollapsible: true  → Card yang bisa dilipat/dibuka oleh user
// ─────────────────────────────────────────────────────────────────────────────
class SuggestionCard extends StatelessWidget {
  final String title;
  final List<String> suggestions;
  final List<TraitSuggestion>? traitSuggestions;
  final IconData icon;
  final Color color;
  final bool isCollapsible;

  const SuggestionCard({
    super.key,
    required this.title,
    this.suggestions = const [],
    this.traitSuggestions,
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
        traitSuggestions: traitSuggestions,
        icon: icon,
        color: color,
      );
    }
    return _StaticCard(
      title: title,
      suggestions: suggestions,
      traitSuggestions: traitSuggestions,
      icon: icon,
      color: color,
    );
  }
}

// ── Trait Colors ─────────────────────────────────────────────────────────────
Color _traitColor(String trait) {
  switch (trait) {
    case 'O':
      return const Color(0xFF8B5CF6); // Purple
    case 'C':
      return const Color(0xFF3B82F6); // Blue
    case 'E':
      return const Color(0xFFF59E0B); // Amber
    case 'A':
      return const Color(0xFF10B981); // Green
    case 'N':
      return const Color(0xFFEF4444); // Red
    default:
      return AppTheme.primaryColor;
  }
}

IconData _traitIcon(String trait) {
  switch (trait) {
    case 'O':
      return Icons.auto_awesome_rounded;
    case 'C':
      return Icons.check_circle_outline_rounded;
    case 'E':
      return Icons.people_outline_rounded;
    case 'A':
      return Icons.favorite_outline_rounded;
    case 'N':
      return Icons.psychology_rounded;
    default:
      return Icons.lightbulb_outline_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StaticCard — Versi non-collapsible
// ─────────────────────────────────────────────────────────────────────────────
class _StaticCard extends StatelessWidget {
  final String title;
  final List<String> suggestions;
  final List<TraitSuggestion>? traitSuggestions;
  final IconData icon;
  final Color color;

  const _StaticCard({
    required this.title,
    required this.suggestions,
    this.traitSuggestions,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasTraits = traitSuggestions != null && traitSuggestions!.isNotEmpty;

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
          _CardHeader(
            title: title,
            icon: icon,
            color: color,
            isExpanded: true,
            showArrow: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg, 0, AppTheme.spaceLg, AppTheme.spaceLg),
            child: hasTraits
                ? _buildTraitSections(traitSuggestions!, context)
                : _buildFlatList(suggestions, context),
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
  final List<TraitSuggestion>? traitSuggestions;
  final IconData icon;
  final Color color;

  const _CollapsibleCard({
    required this.title,
    required this.suggestions,
    this.traitSuggestions,
    required this.icon,
    required this.color,
  });

  @override
  State<_CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<_CollapsibleCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final hasTraits =
        widget.traitSuggestions != null && widget.traitSuggestions!.isNotEmpty;

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
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState:
                _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLg, 0, AppTheme.spaceLg, AppTheme.spaceLg),
              child: hasTraits
                  ? _buildTraitSections(widget.traitSuggestions!, context)
                  : _buildFlatList(widget.suggestions, context),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Shared Builders ──────────────────────────────────────────────────────────

Widget _buildTraitSections(List<TraitSuggestion> traits, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      ...traits.asMap().entries.map((entry) {
        final trait = entry.value;
        final tc = _traitColor(trait.trait);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tc.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trait header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tc.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_traitIcon(trait.trait), size: 14, color: tc),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          trait.traitName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tc,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tc.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trait.level,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tc,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Suggestions
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    children: trait.suggestions
                        .asMap()
                        .entries
                        .map((e) => _SuggestionItem(
                            number: e.key + 1,
                            text: e.value,
                            color: tc))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}

Widget _buildFlatList(List<String> suggestions, BuildContext context) {
  return Column(
    children: suggestions
        .asMap()
        .entries
        .map((e) => _SuggestionItem(
            number: e.key + 1, text: e.value, color: AppTheme.primaryColor))
        .toList(),
  );
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
          bottomLeft: Radius.circular(
              !showArrow || isExpanded ? 0 : AppTheme.radiusXl),
          bottomRight: Radius.circular(
              !showArrow || isExpanded ? 0 : AppTheme.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
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
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppTheme.textP(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
