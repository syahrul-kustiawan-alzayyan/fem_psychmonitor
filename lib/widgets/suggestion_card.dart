import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/suggestion_service.dart';
import '../theme/resonance_colors.dart';
import 'decorative_painters.dart';

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
    this.icon = PhosphorIconsRegular.lightbulb,
    this.color = const Color(0xFFA05A6B),
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
      return const Color(0xFFC77E8C);
  }
}

IconData _traitIcon(String trait) {
  switch (trait) {
    case 'O':
      return PhosphorIconsRegular.sparkle;
    case 'C':
      return PhosphorIconsRegular.checkCircle;
    case 'E':
      return PhosphorIconsRegular.usersThree;
    case 'A':
      return PhosphorIconsRegular.heart;
    case 'N':
      return PhosphorIconsRegular.brain;
    default:
      return PhosphorIconsRegular.lightbulb;
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
    final c = ResonanceColors.of(context);
    final hasTraits = traitSuggestions != null && traitSuggestions!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: c.outlineVariant.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: hasTraits
                  ? _buildTraitSections(traitSuggestions!, context)
                  : _buildFlatList(suggestions, context),
            ),
          ],
        ),
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
    final c = ResonanceColors.of(context);
    final hasTraits =
        widget.traitSuggestions != null && widget.traitSuggestions!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: c.outlineVariant.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: widget.color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
              color: tc.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tc.withValues(alpha: 0.18),
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
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tc.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      topRight: Radius.circular(13),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_traitIcon(trait.trait), size: 15, color: tc),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trait.traitName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tc,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: tc.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trait.level,
                          style: GoogleFonts.jetBrainsMono(
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
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
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
            number: e.key + 1,
            text: e.value,
            color: const Color(0xFFC77E8C)))
        .toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardHeader — Header strip dengan ikon well + judul
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
    final c = ResonanceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(
              !showArrow || isExpanded ? 0 : 20),
          bottomRight: Radius.circular(
              !showArrow || isExpanded ? 0 : 20),
        ),
        border: Border(
          bottom: showArrow && isExpanded
              ? BorderSide(color: color.withValues(alpha: 0.12))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Decorative graphic instead of icon box
          CustomPaint(
            size: const Size(32, 32),
            painter: FlowerPainter(color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
                height: 1.3,
              ),
            ),
          ),
          if (showArrow)
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                PhosphorIconsRegular.caretDown,
                color: color,
                size: 20,
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
    final c = ResonanceColors.of(context);
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
                style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: c.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}