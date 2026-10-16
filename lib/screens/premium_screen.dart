import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../services/billing_service.dart';
import '../services/config_service.dart';
import '../services/database_service.dart';

// ── Midnight Blush Palette (dark standalone) ────────────────
const _primary = Color(0xFFFFC5D3);
const _secondary = Color(0xFF9D4EDD);
const _bg = Color(0xFF0A0410);
const _surface = Color(0xFF1D1124);
const _onSurface = Color(0xFFEDE6EE);
const _onSurfaceVariant = Color(0xFFE2BDC6);
const _outline = Color(0xFFB08A96);
const _outlineVariant = Color(0xFF4A3040);

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {
  final _billing = BillingService();
  bool _isRestoring = false;
  bool _isCanceling = false;
  int _selectedIndex = 0;

  late final AnimationController _glowCtrl;

  final List<_SubscriptionPlan> _plans = [
    _SubscriptionPlan(
      productId: ConfigService.billingProductWeekly,
      labelKey: 'premium_plan_weekly',
      tagKey: 'premium_tag_weekly',
      isPopular: false,
    ),
    _SubscriptionPlan(
      productId: ConfigService.billingProductMonthly,
      labelKey: 'premium_plan_monthly',
      tagKey: 'premium_tag_monthly',
      isPopular: false,
    ),
    _SubscriptionPlan(
      productId: ConfigService.billingProductYearly,
      labelKey: 'premium_plan_yearly',
      tagKey: 'premium_tag_yearly',
      isPopular: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _billing.addListener(_onBillingStateChanged);
    _billing.addListener(_onProductsLoaded);
  }

  @override
  void dispose() {
    _billing
      ..removeListener(_onBillingStateChanged)
      ..removeListener(_onProductsLoaded);
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onProductsLoaded() {
    if (mounted) setState(() {});
  }

  /// Handle hasil pembelian / restore (sekali pakai via consumeState).
  void _onBillingStateChanged() {
    if (!mounted) return;
    final state = _billing.consumeState();
    // Refresh UI (spinner tombol) setelah state dikonsumsi → idle.
    setState(() {});
    switch (state) {
      case PurchaseState.success:
        _showPurchaseResult(true);
        break;
      case PurchaseState.error:
        _showPurchaseResult(false);
        break;
      case PurchaseState.canceled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr('premium_purchase_canceled')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _surface,
          ),
        );
        break;
      case PurchaseState.pending:
      case PurchaseState.idle:
        break;
    }
  }

  Future<void> _purchase() async {
    if (_billing.state == PurchaseState.pending) return;
    final available = _availablePlans();
    if (_selectedIndex >= available.length) return;
    final success = await _billing.purchase(available[_selectedIndex].productId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('premium_purchase_error')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
        ),
      );
    }
  }

  Future<void> _restore() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    // Selama restore, hasil dikelola di sini (bukan dialog pembelian global).
    _billing.removeListener(_onBillingStateChanged);
    final done = Completer<bool>();
    late VoidCallback listener;
    listener = () {
      final s = _billing.consumeState();
      if (s == PurchaseState.success || s == PurchaseState.error) {
        _billing.removeListener(listener);
        if (!done.isCompleted) done.complete(s == PurchaseState.success);
      }
    };
    _billing.addListener(listener);
    try {
      await _billing.restore();
      // Jika tidak ada pembelian sama sekali, stream tidak memancarkan apa pun.
      final result = await done.future
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
      _billing.removeListener(listener);
      if (!mounted) return;
      setState(() => _isRestoring = false);
      _showRestoreResult(result);
    } finally {
      _billing.addListener(_onBillingStateChanged);
    }
  }

  List<_SubscriptionPlan> _availablePlans() =>
      _plans.where((p) => _billing.productsById.containsKey(p.productId)).toList();

  Future<void> _showPurchaseResult(bool success) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          success ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.xCircle,
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
              'OK',
              style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreResult(bool success) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          success ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.info,
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
              'OK',
              style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              color: _surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: _outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Icon(PhosphorIconsRegular.x, color: _primary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: _outlineVariant.withValues(alpha: 0.4)),
            ),
            child: IconButton(
              icon: Icon(PhosphorIconsRegular.arrowsClockwise, size: 18, color: _primary),
              onPressed: _isRestoring ? null : _restore,
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
                        _primary.withValues(alpha: 0.05),
                        _bg,
                      ],
                    ),
                  ),
                ),
              ),
              _buildAmbientGlow(),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 64,
                      bottom: 16,
                      left: 24,
                      right: 24,
                    ),
                    child: _buildHero(context, isPremiumActive),
                  ),
                  Expanded(
                    child: isPremiumActive && premium.expiryDate != null
                        ? _buildCountdownSection(context, premium.expiryDate!)
                        : _buildPurchaseSection(context),
                  ),
                  if (!isPremiumActive) _buildBottomCta(context),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final t = 0.55 + 0.45 * _glowCtrl.value;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: Opacity(
                  opacity: t,
                  child: _glowCircle(
                    size: 280,
                    color: _primary.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -70,
                child: Opacity(
                  opacity: 1 - t * 0.5,
                  child: _glowCircle(
                    size: 260,
                    color: _secondary.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glowCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isPremiumActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPremiumActive ? PhosphorIconsFill.crown : PhosphorIconsFill.sparkle,
                size: 14,
                color: _primary,
              ),
              const SizedBox(width: 6),
              Text(
                isPremiumActive
                    ? AppLocalizations.tr('premium_active_badge')
                    : AppLocalizations.tr('premium_badge'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isPremiumActive
              ? AppLocalizations.tr('premium_hero_active_title')
              : AppLocalizations.tr('premium_hero_title'),
          style: GoogleFonts.syne(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          isPremiumActive
              ? AppLocalizations.tr('premium_hero_active_subtitle')
              : AppLocalizations.tr('premium_hero_subtitle'),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (!isPremiumActive) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _heroChip(PhosphorIconsRegular.infinity, 'premium_chip_unlimited'),
              _heroChip(PhosphorIconsRegular.megaphoneSimple, 'premium_chip_adfree'),
              _heroChip(PhosphorIconsRegular.shieldCheck, 'premium_chip_secure'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _heroChip(IconData icon, String labelKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _primary),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.tr(labelKey),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── COUNTDOWN SECTION ──────────────────────────────────────

  Widget _buildCountdownSection(BuildContext context, DateTime expiryDate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _buildGlassCard(
            padding: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.green.shade400.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsFill.checkCircle,
                        size: 13,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.tr('premium_active_pill'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade300,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.tr('premium_expires_in'),
                  style: GoogleFonts.inter(fontSize: 13, color: _onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                _PremiumCountdown(expiryDate: expiryDate),
                const SizedBox(height: 12),
                Container(height: 1, color: _outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 10),
                Text(
                  '${AppLocalizations.tr('premium_expiry_label')}: ${_formatDate(expiryDate)}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _onSurfaceVariant),
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
                Row(
                  children: [
                    Icon(PhosphorIconsFill.sparkle, size: 15, color: _primary),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.tr('premium_benefits_title'),
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._buildBenefits(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCancelSubscriptionCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── CANCEL SUBSCRIPTION ───────────────────────────────────

  /// Kartu kecil untuk mengelola/membatalkan langganan.
  /// Langganan aktif dibatalkan via Play Store (deep link); yang sudah
  /// kedaluwarsa dicabut langsung via server.
  Widget _buildCancelSubscriptionCard() {
    return _buildGlassCard(
      padding: 14,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.red.shade400.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.3)),
            ),
            child: Icon(
              PhosphorIconsRegular.calendarX,
              size: 15,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr('premium_cancel_subscription'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.tr('premium_cancel_manage'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isCanceling ? null : _confirmCancelSubscription,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade400.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.red.shade400.withValues(alpha: 0.4),
                ),
              ),
              child: _isCanceling
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red.shade300,
                      ),
                    )
                  : Text(
                      AppLocalizations.tr('premium_cancel_subscription'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade300,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelSubscription() async {
    if (_isCanceling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          PhosphorIconsFill.calendarX,
          color: Colors.red.shade400,
          size: 48,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.tr('premium_cancel_title'),
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.tr('premium_cancel_desc'),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.tr('premium_cancel_keep'),
              style: GoogleFonts.inter(
                color: _onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.tr('premium_cancel_open_store'),
              style: GoogleFonts.inter(
                color: Colors.red.shade300,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _cancelSubscription();
    }
  }

  /// Batalkan langganan.
  ///
  /// - Langganan yang sudah kedaluwarsa → server mencabut flag lokal
  ///   langsung (tanpa memanggil Play API).
  /// - Langganan aktif → deep link ke Play Store (pola resmi Google untuk
  ///   pembatalan inisiatif user; entitlement tetap berlaku sampai expiry).
  ///   Server hanya di-refresh best-effort setelahnya.
  Future<void> _cancelSubscription() async {
    if (_isCanceling) return;
    final premium = context.read<PremiumProvider>();
    final expiry = premium.expiryDate;
    final isExpired =
        premium.isExpired || (expiry != null && expiry.isBefore(DateTime.now()));

    if (isExpired) {
      setState(() => _isCanceling = true);
      final result = await DatabaseService.cancelPremium();
      if (!mounted) return;
      setState(() => _isCanceling = false);
      if (result.ok) {
        context.read<PremiumProvider>().clearPremium();
        await _showCancelResult(true);
      } else {
        await _showCancelResult(false, error: result.error);
      }
      return;
    }

    setState(() => _isCanceling = true);
    try {
      final launched = await launchUrl(
        Uri.parse(_playStoreSubscriptionUrl()),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(() => _isCanceling = false);
      if (!launched) {
        await _showCancelResult(false);
        return;
      }
      // Refresh status server best-effort. Play tidak memberi callback,
      // jadi user bisa saja kembali tanpa membatalkan — karena itu jangan
      // tampilkan dialog "dibatalkan". Hanya beri tahu status diperbarui,
      // kecuali server memastikan premium sudah nonaktif.
      try {
        final status = await DatabaseService.loadPremiumStatus();
        if (!mounted) return;
        if (!status.isPremium) {
          context.read<PremiumProvider>().clearPremium();
          await _showCancelResult(true);
          return;
        }
        if (status.expiry != null) {
          context.read<PremiumProvider>().setPremium(value: true, expiry: status.expiry);
        }
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('premium_status_refreshed')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCanceling = false);
      await _showCancelResult(false);
    }
  }

  /// URL halaman langganan Play Store untuk app ini (tanpa sku agar
  /// menampilkan semua langganan user pada aplikasi ini).
  String _playStoreSubscriptionUrl() {
    final pkg = ConfigService.appPackageName;
    return 'https://play.google.com/store/account/subscriptions?package=$pkg';
  }

  Future<void> _showCancelResult(bool success, {String? error}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          success ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.xCircle,
          color: success ? Colors.green.shade400 : Colors.red.shade400,
          size: 48,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              success
                  ? AppLocalizations.tr('premium_cancel_success_title')
                  : AppLocalizations.tr('premium_cancel_failed_title'),
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
                  ? AppLocalizations.tr('premium_cancel_success_desc')
                  : AppLocalizations.tr('premium_cancel_failed_desc'),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            if (!success && error != null && error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.red.shade900.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (success && context.mounted) Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── PURCHASE SECTION ───────────────────────────────────────

  Widget _buildPurchaseSection(BuildContext context) {
    final plans = _availablePlans();
    if (_selectedIndex >= plans.length && plans.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }

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
                AppLocalizations.tr('premium_choose_plan'),
                style: GoogleFonts.syne(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              Text(
                AppLocalizations.tr('premium_cancel_anytime'),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: _onSurfaceVariant,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  AppLocalizations.tr('premium_plan_unavailable'),
                  style: GoogleFonts.inter(fontSize: 12, color: _onSurfaceVariant),
                ),
              ),
            )
          else
            ...List.generate(plans.length, (i) => _buildPlanCard(i, plans)),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.lockKey, size: 13, color: _outline),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  AppLocalizations.tr('premium_secure_checkout'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr('premium_subscribe_terms'),
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _outline.withValues(alpha: 0.85),
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

  Widget _buildPlanCard(int index, List<_SubscriptionPlan> plans) {
    final plan = plans[index];
    final product = _billing.productsById[plan.productId]!;
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? _primary.withValues(alpha: 0.09)
                : _surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? _primary.withValues(alpha: 0.55)
                  : _outlineVariant.withValues(alpha: 0.35),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
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
                          width: 1.5,
                        ),
                        color: isSelected
                            ? _primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppLocalizations.tr(plan.labelKey),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: _onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.tr(plan.tagKey),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _onSurfaceVariant.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                product.price,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _primary : _onSurfaceVariant,
                                ),
                              ),
                              if (_periodLabel(product).isNotEmpty)
                                Text(
                                  _periodLabel(product),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: _outline,
                                  ),
                                ),
                            ],
                          ),
                          if (plan.isPopular) _buildEffectiveLine(plan),
                        ],
                      ),
                    ),
                    if (plan.isPopular) _buildSavingsBadge(),
                  ],
                ),
              ),

              if (plan.isPopular)
                Positioned(
                  top: -11,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsFill.star, size: 10, color: _surface),
                        const SizedBox(width: 5),
                        Text(
                          AppLocalizations.tr('premium_popular'),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _surface,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "± Rp 8.250/bln" — harga efektif dihitung dari harga store (yearly ÷ 12).
  Widget _buildEffectiveLine(_SubscriptionPlan plan) {
    final yearly = _billing.productsById[ConfigService.billingProductYearly];
    final monthly = _billing.productsById[ConfigService.billingProductMonthly];
    if (yearly == null || monthly == null) return const SizedBox.shrink();
    final effective = yearly.rawPrice / 12;
    final label = AppLocalizations.tr('premium_effective')
        .replaceAll('{price}', _formatRupiah(effective));
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          color: _onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildSavingsBadge() {
    final yearly = _billing.productsById[ConfigService.billingProductYearly];
    final monthly = _billing.productsById[ConfigService.billingProductMonthly];
    if (yearly == null || monthly == null || monthly.rawPrice <= 0) {
      return const SizedBox.shrink();
    }
    final percent =
        ((1 - (yearly.rawPrice / 12) / monthly.rawPrice) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        AppLocalizations.tr('premium_savings').replaceAll('{percent}', '$percent'),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _secondary,
          letterSpacing: 0.05,
        ),
      ),
    );
  }

  /// Label periode dari billingPeriod Play ("P1W" → "/mgg").
  String _periodLabel(ProductDetails product) {
    if (product is! GooglePlayProductDetails) return '';
    final details = product.productDetails.subscriptionOfferDetails;
    if (details == null || details.isEmpty) return '';
    final phases = details.first.pricingPhases;
    final period = phases.isEmpty ? null : phases.first.billingPeriod;
    switch (period) {
      case 'P1W':
        return AppLocalizations.tr('premium_period_week');
      case 'P1M':
        return AppLocalizations.tr('premium_period_month');
      case 'P1Y':
        return AppLocalizations.tr('premium_period_year');
      default:
        return '';
    }
  }

  String _formatRupiah(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buffer.write('.');
      buffer.write(rounded[i]);
    }
    return 'Rp $buffer';
  }

  // ── BOTTOM CTA ─────────────────────────────────────────────

  Widget _buildBottomCta(BuildContext context) {
    final isLoading = _billing.state == PurchaseState.pending;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsRegular.lockKey, size: 12, color: _outline),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppLocalizations.tr('premium_secure_checkout'),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: _outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: const Color(0xFF3A1020),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsFill.crown, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.tr('premium_subscribe_now'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
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

  List<Widget> _buildBenefits() {
    final benefits = [
      ('premium_benefit_unlimited', 'premium_benefit_unlimited_desc'),
      ('premium_benefit_adfree', 'premium_benefit_adfree_desc'),
    ];
    return benefits.map((b) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _primary.withValues(alpha: 0.25)),
              ),
              child: Icon(
                PhosphorIconsFill.check,
                size: 12,
                color: _primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.tr(b.$1),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.tr(b.$2),
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

class _SubscriptionPlan {
  final String productId;
  final String labelKey;
  final String tagKey;
  final bool isPopular;

  const _SubscriptionPlan({
    required this.productId,
    required this.labelKey,
    required this.tagKey,
    required this.isPopular,
  });
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timeBlock(days, AppLocalizations.tr('premium_countdown_days')),
        _separator(),
        _timeBlock(hours, AppLocalizations.tr('premium_countdown_hours')),
        _separator(),
        _timeBlock(minutes, AppLocalizations.tr('premium_countdown_minutes')),
        _separator(),
        _timeBlock(seconds, AppLocalizations.tr('premium_countdown_seconds')),
      ],
    );
  }

  Widget _timeBlock(int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _primary.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.jetBrainsMono(
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
        style: GoogleFonts.jetBrainsMono(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _outline,
        ),
      ),
    );
  }
}