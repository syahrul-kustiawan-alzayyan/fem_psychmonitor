import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/emotion_model.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmotionBadge — Badge compact untuk menampilkan satu emosi
// Digunakan di list log, filter chips, dll.
// ─────────────────────────────────────────────────────────────────────────────
class EmotionBadge extends StatelessWidget {
  final EmotionType emotion;
  final double? confidence;
  final bool showLabel;
  final bool showConfidence;
  final double iconSize;

  const EmotionBadge({
    super.key,
    required this.emotion,
    this.confidence,
    this.showLabel = true,
    this.showConfidence = false,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emotion.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: emotion.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(emotion.icon, color: emotion.color, size: iconSize),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              '${emotion.emoji} ${emotion.displayName}',
              style: GoogleFonts.poppins(
                color: emotion.color,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
          if (showConfidence && confidence != null) ...[
            const SizedBox(width: 4),
            Text(
              '${(confidence! * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: emotion.color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EmotionResultCard — Kartu besar untuk menampilkan hasil deteksi emosi
// Digunakan di VoiceDetectionScreen setelah rekaman selesai.
//
// Fitur premium:
//   • Gradient background yang match dengan warna emosi
//   • Emoji besar di tengah dengan container circle
//   • Confidence indicator dengan CircularProgressIndicator ring
//   • Dekorasi blob latar belakang
// ─────────────────────────────────────────────────────────────────────────────
class EmotionResultCard extends StatelessWidget {
  final EmotionType emotion;
  final double confidence;

  const EmotionResultCard({
    super.key,
    required this.emotion,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            emotion.color.withValues(alpha: 0.18),
            emotion.color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: emotion.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: emotion.color.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Dekorasi blob latar ──────────────────────────────
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: emotion.color.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: emotion.color.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ── Konten Kartu ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceXl,
              vertical: 28,
            ),
            child: Column(
              children: [
                // Row: ikon + confidence ring
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ikon emosi dengan background circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ring confidence visual
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: confidence,
                            strokeWidth: 5,
                            backgroundColor:
                                emotion.color.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              emotion.color,
                            ),
                          ),
                        ),
                        // Inner circle + icon
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: emotion.color.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text(
                              emotion.emoji,
                              style: const TextStyle(fontSize: 34),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Teks di sebelah kanan ring
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terdeteksi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: emotion.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emotion.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Confidence badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: emotion.color.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: emotion.color,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Akurasi ${(confidence * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: emotion.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Divider
                Container(
                  height: 1,
                  color: emotion.color.withValues(alpha: 0.15),
                ),

                const SizedBox(height: 16),

                // Status psikis baris bawah
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      color: emotion.color,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Status Psikis: ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      emotion.psychStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
