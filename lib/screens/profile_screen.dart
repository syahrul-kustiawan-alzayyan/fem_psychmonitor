import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Edit Profil User
//
// Mengikuti tema utama aplikasi (light/dark mode aware)
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
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
                  color: AppTheme.textH(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.tr('select_profile_photo'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                ),
                title: Text(AppLocalizations.tr('camera'), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.deepPurple),
                ),
                title: Text(AppLocalizations.tr('gallery'), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                  title: Text(AppLocalizations.tr('delete_photo'), style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.red)),
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
            content: Text(AppLocalizations.tr('profile_photo_updated'), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.tr("failed_select_photo")}: $e', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFFDB2777)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            AppLocalizations.tr('profile_saved'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial = auth.username.isNotEmpty
        ? auth.username[0].toUpperCase()
        : (auth.email.isNotEmpty ? auth.email[0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.tr('profile_title')),
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
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFFEC4899),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
                              gradient: AppTheme.primaryGradient,
                              boxShadow: AppTheme.primaryShadow,
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surface(context),
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
                                        style: GoogleFonts.poppins(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryColor,
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
                                  color: AppTheme.primaryColor,
                                  border: Border.all(
                                    color: AppTheme.surface(context),
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
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
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXl),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.tr('tap_to_change_photo'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textS(context),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Form Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          _buildFieldLabel(AppLocalizations.tr('username')),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameCtrl,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textP(context),
                            ),
                            decoration: _inputDecoration(
                              hint: AppLocalizations.tr('username_hint'),
                              icon: Icons.person_outlined,
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
                          _buildFieldLabel(AppLocalizations.tr('email')),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textP(context),
                            ),
                            decoration: _inputDecoration(
                              hint: AppLocalizations.tr('email_hint'),
                              icon: Icons.email_outlined,
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

                  // ── MBTI Section ─────────────────────────────
                  if (_user != null) _buildMBTICard(context, _user!),

                  const SizedBox(height: 16),

                  // Member since
                  if (auth.isLoggedIn)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${AppLocalizations.tr('member_since')}: ${_formatDate(DateTime.now())}',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Tombol Simpan ──────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        elevation: 0,
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
                              style: GoogleFonts.poppins(
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
  // MBTI Card Widget
  // ─────────────────────────────────────────────────────────────
  Widget _buildMBTICard(BuildContext context, AppUser user) {
    final mbtiType = user.mbtiType;
    final hasMBTI = mbtiType.isNotEmpty;

    return GestureDetector(
      onTap: () => _showMBTIEditDialog(context, user),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasMBTI
                ? [const Color(0xFF3B82F6), const Color(0xFFEC4899)]
                : [const Color(0xFF64748B), const Color(0xFF94A3B8)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color:
                  (hasMBTI ? const Color(0xFF3B82F6) : const Color(0xFF64748B))
                      .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasMBTI ? Icons.psychology_rounded : Icons.help_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasMBTI ? 'Tipe MBTI Anda' : 'Belum Ada MBTI',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasMBTI
                        ? '$mbtiType - ${user.mbtiNickname}'
                        : 'Tap untuk menambahkan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Edit icon
            Icon(
              Icons.edit_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MBTI Edit Dialog
  // ─────────────────────────────────────────────────────────────
  Future<void> _showMBTIEditDialog(BuildContext context, AppUser user) async {
    final mbtiTypes = [
      'INTJ',
      'INTP',
      'ENTJ',
      'ENTP',
      'INFJ',
      'INFP',
      'ENFJ',
      'ENFP',
      'ISTJ',
      'ISFJ',
      'ESTJ',
      'ESFJ',
      'ISTP',
      'ISFP',
      'ESTP',
      'ESFP',
    ];

    String? selectedType = user.mbtiType.isNotEmpty ? user.mbtiType : null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Icon(Icons.psychology_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Pilih Tipe MBTI',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mbtiTypes.map((type) {
                final isSelected = selectedType == type;
                return ChoiceChip(
                  label: Text(
                    type,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textP(context),
                  ),
                  onSelected: (value) {
                    setState(() => selectedType = type);
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.tr('cancel'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textS(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            onPressed: selectedType == null
                ? null
                : () async {
                    await DatabaseService.updateUser(
                      user.copyWith(mbtiType: selectedType!),
                    );
                    await _loadUserData();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'MBTI berhasil diubah menjadi $selectedType!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                      ),
                    );
                  },
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textP(context),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13.5,
        color: AppTheme.textH(context),
      ),
      prefixIcon: Icon(icon, color: AppTheme.textH(context), size: 20),
      filled: true,
      fillColor: AppTheme.surfVar(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
