import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/resonance_colors.dart';
import 'onboarding/onboarding_state.dart';
import 'big_five_retake_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Edit Profil User
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  bool _isSaving = false;
  AppUser? _user;
  String? _photoPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _usernameCtrl = TextEditingController(text: auth.username);
    _emailCtrl = TextEditingController(text: auth.email);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseService.getUser();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('auth_email') ?? '';
    final savedPhoto = prefs.getString('profile_photo_$email');
    if (mounted) {
      setState(() {
        _user = user;
        _photoPath = savedPhoto;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final c = ResonanceColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.tr('select_profile_photo'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(PhosphorIconsRegular.camera,
                      color: c.onSurfaceVariant),
                ),
                title: Text(
                  AppLocalizations.tr('camera'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(PhosphorIconsRegular.image, color: c.primary),
                ),
                title: Text(
                  AppLocalizations.tr('gallery'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _getImage(ImageSource.gallery);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIconsRegular.trash,
                        color: Color(0xFFEF4444)),
                  ),
                  title: Text(
                    AppLocalizations.tr('delete_photo'),
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFEF4444)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      // Copy to app directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final savedFile = await File(picked.path).copy(p.join(appDir.path, fileName));

      // Save path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('auth_email') ?? '';

      // Delete old photo if exists
      final oldPath = prefs.getString('profile_photo_$email');
      if (oldPath != null) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) await oldFile.delete();
      }

      await prefs.setString('profile_photo_$email', savedFile.path);

      if (mounted) {
        setState(() => _photoPath = savedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.tr('profile_photo_updated'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.tr("failed_select_photo")}: $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('auth_email') ?? '';
    final oldPath = prefs.getString('profile_photo_$email');
    if (oldPath != null) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) await oldFile.delete();
      await prefs.remove('profile_photo_$email');
    }
    if (mounted) {
      setState(() => _photoPath = null);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await context.read<AuthProvider>().updateProfile(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );

    // Juga update username ke DatabaseService (SQLite)
    final user = await DatabaseService.getUser();
    if (user != null) {
      await DatabaseService.updateUser(
        user.copyWith(name: _usernameCtrl.text.trim()),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ResonanceColors.of(context).primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4024161C),
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Text(
            AppLocalizations.tr('profile_saved'),
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);
    final auth = context.watch<AuthProvider>();
    final initial = auth.username.isNotEmpty
        ? auth.username[0].toUpperCase()
        : (auth.email.isNotEmpty ? auth.email[0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: c.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIconsRegular.userCircle,
                color: c.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.tr('profile_title'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Banner ──────────────────────────────
            SizedBox(
              height: 205,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Background image with gradient overlay
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/bgimage/wmremove-transformed.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  c.primaryContainer.withValues(alpha: 0.35),
                                  c.primaryContainer.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 90,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.primary,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x4024161C),
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.surfaceLowest,
                                image: _photoPath != null && File(_photoPath!).existsSync()
                                    ? DecorationImage(
                                        image: FileImage(File(_photoPath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _photoPath == null || !File(_photoPath!).existsSync()
                                  ? Center(
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: c.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          // Camera badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.primary,
                                  border: Border.all(
                                    color: c.surfaceLowest,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  PhosphorIconsRegular.camera,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.tr('tap_to_change_photo'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Form Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.surfaceLowest,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1424161C),
                          offset: Offset(2, 2),
                        ),
                      ],
                      border: Border.all(color: c.outlineVariant),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          _buildFieldLabel(context, AppLocalizations.tr('username')),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameCtrl,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: c.onSurface,
                            ),
                            decoration: _inputDecoration(
                              hint: AppLocalizations.tr('username_hint'),
                              icon: PhosphorIconsRegular.user,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return AppLocalizations.tr('username_required');
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // Email
                          _buildFieldLabel(context, AppLocalizations.tr('email')),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: c.onSurface,
                            ),
                            decoration: _inputDecoration(
                              hint: AppLocalizations.tr('email_hint'),
                              icon: PhosphorIconsRegular.envelope,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!v.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Big Five Section ──────────────────────────
                  if (_user != null) _buildBigFiveCard(context, _user!),

                  const SizedBox(height: 12),

                  // Retake Big Five button
                  if (_user != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => OnboardingState(),
                                child: const BigFiveRetakeScreen(),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          PhosphorIconsRegular.arrowCounterClockwise,
                          size: 18,
                          color: c.primary,
                        ),
                        label: Text(
                          AppLocalizations.tr('big_five_retake_title'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.primary,
                          side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Member since
                  if (auth.isLoggedIn)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.sealCheck,
                            color: c.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${AppLocalizations.tr('member_since')}: ${_formatDate(DateTime.now())}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: c.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Tombol Simpan ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              AppLocalizations.tr('save_profile'),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Big Five Card Widget
  // ─────────────────────────────────────────────────────────────
  Widget _buildBigFiveCard(BuildContext context, AppUser user) {
    final c = ResonanceColors.of(context);
    final scores = user.bigFiveScores;
    final hasScores = scores.isNotEmpty;

    final labels = {
      'O': 'Terbuka',
      'C': 'Teliti',
      'E': 'Ekstrover',
      'A': 'Ramah',
      'N': 'Neurotisisme',
    };

    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasScores
                      ? c.primary
                      : c.outlineVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  PhosphorIconsRegular.chartBar,
                  color: hasScores ? Colors.white : c.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Big Five Personality',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasScores ? 'Skor kepribadian tersedia' : 'Belum ada data',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasScores)
                Icon(
                  PhosphorIconsRegular.pulse,
                  color: c.primary,
                  size: 18,
                ),
            ],
          ),
          if (hasScores) ...[
            const SizedBox(height: 16),
            ...scores.entries.map((e) {
              final pct = (e.value / 5.0).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${e.key} - ${labels[e.key] ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          e.value.toStringAsFixed(1),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: c.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    final c = ResonanceColors.of(context);
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: c.onSurface,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    final c = ResonanceColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13.5,
        color: c.outline,
      ),
      prefixIcon: Icon(icon, color: c.outline, size: 20),
      filled: true,
      fillColor: c.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _formatDate(DateTime dt) {
    final months = AppLocalizations.currentLocale == 'id'
        ? [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agu',
            'Sep',
            'Okt',
            'Nov',
            'Des',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}