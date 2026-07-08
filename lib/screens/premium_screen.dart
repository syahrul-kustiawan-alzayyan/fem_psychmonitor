import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../services/subscription_service.dart';

// ── Midnight Blush Palette ──────────────────────────────────
const _primary = Color(0xFFFFC5D3);
const _secondary = Color(0xFF9D4EDD);
const _bg = Color(0xFF000000);
const _surface = Color(0xFF2D1B33);
const _onSurface = Color(0xFFE5E1E4);
const _onSurfaceVariant = Color(0xFFE2BDC6);
const _outline = Color(0xFFAA8890);
const _outlineVariant = Color(0xFF5A3F47);

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {
  final _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  int _selectedIndex = 1;

  final List<_SubscriptionPlan> _plans = [
    _SubscriptionPlan(
      id: 'weekly',
      label: 'Mingguan',
      labelEn: 'Weekly',
      price: 'Rp 7.000',
      period: '/mgg',
      periodEn: '/wk',
      savings: '',
      savingsEn: '',
      isPopular: false,
    ),
    _SubscriptionPlan(
      id: 'monthly',
      label: 'Bulanan',
      labelEn: 'Monthly',
      price: 'Rp 20.000',
      period: '/bln',
      periodEn: '/mo',
      savings: '',
      savingsEn: '',
      isPopular: false,
    ),
    _SubscriptionPlan(
      id: 'yearly',
      label: 'Tahunan',
      labelEn: 'Yearly',
      price: 'Rp 99.000',
      period: '/thn',
      periodEn: '/yr',
      savings: 'Hemat 59%',
      savingsEn: 'Save 59%',
      isPopular: true,
    ),
  ];

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    bool success = false;
    try {
      await _subscriptionService.fetchOfferings();
      if (!mounted) return;
      if (_subscriptionService.offerings.isNotEmpty) {
        final offering = _subscriptionService.offerings.first;
        final packages = offering.availablePackages;
        if (_selectedIndex < packages.length) {
          final premium = context.read<PremiumProvider>();
          success = await _subscriptionService.purchasePackage(
            packages[_selectedIndex],
            premium,
          );
        }
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showPurchaseResult(success);
  }

  Future<void> _showPurchaseResult(bool success) async {
    final isEn = AppLocalizations.locale.startsWith('en');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Icon(
          success ? Icons.check_circle_rounded : Icons.error_rounded,
          color: success ? Colors.green.shade400 : Colors.red.shade400,
          size: 48,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              success
                  ? AppLocalizations.tr('purchase_success_title')
                  : AppLocalizations.tr('purchase_failed_title'),
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? AppLocalizations.tr('purchase_success_desc')
                  : AppLocalizations.tr('purchase_failed_desc'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (success && context.mounted) Navigator.pop(context);
            },
            child: Text(
              isEn ? 'OK' : 'OK',
              style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    final premium = context.read<PremiumProvider>();
    final success = await _subscriptionService.restorePurchases(premium);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showRestoreResult(success);
  }

  Future<void> _showRestoreResult(bool success) async {
    final isEn = AppLocalizations.locale.startsWith('en');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Icon(
          success ? Icons.check_circle_rounded : Icons.info_rounded,
          color: success ? Colors.green.shade400 : Colors.orange.shade400,
          size: 48,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              success
                  ? AppLocalizations.tr('restore_success_title')
                  : AppLocalizations.tr('restore_failed_title'),
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? AppLocalizations.tr('restore_success_desc')
                  : AppLocalizations.tr('restore_failed_desc'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isEn ? 'OK' : 'OK',
              style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = AppLocalizations.locale.startsWith('en');

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bg.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: _primary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: _bg.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20, color: _primary),
              onPressed: _restore,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _bg.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.power_settings_new_rounded, size: 20, color: _primary),
              onPressed: () => _resetPremium(context),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, premium, _) {
          final isPremiumActive = premium.isPremium && !premium.isExpired;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/bgimage/bg vertical.png',
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
                        _primary.withValues(alpha: 0.04),
                        _bg,
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 64,
                      bottom: 16,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      children: [
                        Text(
                          isPremiumActive
                              ? (isEn ? 'Premium Active' : 'Premium Aktif')
                              : (isEn ? 'Unlock Premium' : 'Buka Akses Premium'),
                          style: GoogleFonts.syne(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPremiumActive
                              ? (isEn ? 'You\'re enjoying all premium features' : 'Anda menikmati semua fitur premium')
                              : (isEn
                                  ? 'Unlimited emotion detection & ad-free experience'
                                  : 'Deteksi emosi tanpa batas & bebas iklan'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isPremiumActive && premium.expiryDate != null
                        ? _buildCountdownSection(context, isEn, premium.expiryDate!)
                        : _buildPurchaseSection(context, isEn),
                  ),
                  if (!isPremiumActive) _buildBottomCta(context, isEn),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _resetPremium(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.locale.startsWith('en') ? 'Reset Premium' : 'Reset Premium',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: _onSurface),
        ),
        content: Text(
          AppLocalizations.locale.startsWith('en')
              ? 'This will clear your premium status and sign out from RevenueCat. Continue?'
              : 'Ini akan menghapus status premium Anda dan keluar dari RevenueCat. Lanjutkan?',
          style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.locale.startsWith('en') ? 'Cancel' : 'Batal',
              style: GoogleFonts.inter(color: _onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.locale.startsWith('en') ? 'Reset' : 'Reset',
              style: GoogleFonts.inter(color: _primary),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final premium = context.read<PremiumProvider>();
      await _subscriptionService.logOut(premium);
      if (context.mounted) Navigator.pop(context);
    }
  }

  // ── COUNTDOWN SECTION ──────────────────────────────────────

  Widget _buildCountdownSection(
    BuildContext context,
    bool isEn,
    DateTime expiryDate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildGlassCard(
            padding: 20,
            child: Column(
              children: [
                Text(
                  isEn ? 'Active' : 'Aktif',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade300,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEn ? 'Premium Expires In' : 'Premium Berakhir Dalam',
                  style: GoogleFonts.inter(fontSize: 13, color: _onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                _PremiumCountdown(expiryDate: expiryDate),
                const SizedBox(height: 12),
                Container(height: 1, color: _outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 10),
                Text(
                  '${isEn ? 'Expiry' : 'Berakhir'}: ${_formatDate(expiryDate)}',
                  style: GoogleFonts.inter(fontSize: 12, color: _onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildGlassCard(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Your Premium Benefits' : 'Manfaat Premium Anda',
                  style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildBenefits(isEn),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── PURCHASE SECTION ───────────────────────────────────────

  Widget _buildPurchaseSection(BuildContext context, bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isEn ? 'Choose your plan' : 'Pilih paket',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              Text(
                isEn ? 'Cancel anytime' : 'Batalkan kapan saja',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: _onSurfaceVariant,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...List.generate(_plans.length, (i) => _buildPlanCard(i, isEn)),

          const SizedBox(height: 8),

          Text(
            isEn
                ? 'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions auto-renew unless canceled.'
                : 'Dengan berlangganan, Anda menyetujui Syarat & Ketentuan dan Kebijakan Privasi kami. Langganan diperpanjang otomatis kecuali dibatalkan.',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _outline,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── PLAN CARD ──────────────────────────────────────────────

  Widget _buildPlanCard(int index, bool isEn) {
    final plan = _plans[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? _primary.withValues(alpha: 0.08) : _surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primary.withValues(alpha: 0.5) : _outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _primary : _outline,
                          width: isSelected ? 6 : 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? plan.labelEn : plan.label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: _onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                plan.price,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _primary : _onSurfaceVariant,
                                ),
                              ),
                              if (plan.period.isNotEmpty)
                                Text(
                                  isEn ? plan.periodEn : plan.period,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: _outline,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (plan.savings.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isEn ? plan.savingsEn : plan.savings,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _secondary,
                            letterSpacing: 0.05,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (plan.isPopular)
                Positioned(
                  top: -10,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isEn ? 'POPULAR' : 'POPULER',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _surface,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BOTTOM CTA ─────────────────────────────────────────────

  Widget _buildBottomCta(BuildContext context, bool isEn) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg.withValues(alpha: 0), _bg],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _purchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    isEn ? 'Subscribe Now' : 'Langganan Sekarang',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.05,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────

  Widget _buildGlassCard({
    required double padding,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = AppLocalizations.currentLocale == 'id'
        ? ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  List<Widget> _buildBenefits(bool isEn) {
    final benefits = isEn
        ? [
            ['Unlimited detection', 'Record and analyze your emotions as many times as you need'],
            ['Ad-free experience', 'Enjoy the app without any ads'],
          ]
        : [
            ['Deteksi tanpa batas', 'Rekam dan analisis emosi sebanyak yang Anda butuhkan'],
            ['Bebas iklan', 'Nikmati aplikasi tanpa gangguan iklan'],
          ];

    return benefits.map((b) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b[0],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b[1],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _PremiumCountdown extends StatefulWidget {
  final DateTime expiryDate;
  const _PremiumCountdown({required this.expiryDate});

  @override
  State<_PremiumCountdown> createState() => _PremiumCountdownState();
}

class _PremiumCountdownState extends State<_PremiumCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final remaining = widget.expiryDate.difference(DateTime.now());
    if (remaining.isNegative) {
      _timer?.cancel();
      if (mounted) setState(() => _remaining = Duration.zero);
    } else {
      if (mounted) setState(() => _remaining = remaining);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final isEn = AppLocalizations.locale.startsWith('en');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timeBlock(days, isEn ? 'Days' : 'Hari'),
        _separator(),
        _timeBlock(hours, isEn ? 'Hours' : 'Jam'),
        _separator(),
        _timeBlock(minutes, isEn ? 'Min' : 'Menit'),
        _separator(),
        _timeBlock(seconds, isEn ? 'Sec' : 'Detik'),
      ],
    );
  }

  Widget _timeBlock(int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: _onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _outline,
        ),
      ),
    );
  }
}

class _SubscriptionPlan {
  final String id;
  final String label;
  final String labelEn;
  final String price;
  final String period;
  final String periodEn;
  final String savings;
  final String savingsEn;
  final bool isPopular;

  const _SubscriptionPlan({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.price,
    required this.period,
    required this.periodEn,
    required this.savings,
    required this.savingsEn,
    required this.isPopular,
  });
}
