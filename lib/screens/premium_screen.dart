import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with SingleTickerProviderStateMixin {
  final _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  int _selectedIndex = 1; // Default to yearly
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.fetchOfferings();
      if (_subscriptionService.offerings.isNotEmpty) {
        final offering = _subscriptionService.offerings.first;
        final packages = offering.availablePackages;
        if (_selectedIndex < packages.length) {
          final premium = context.read<PremiumProvider>();
          await _subscriptionService.purchasePackage(packages[_selectedIndex], premium);
        }
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    final premium = context.read<PremiumProvider>();
    await _subscriptionService.restorePurchases(premium);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEn = AppLocalizations.locale.startsWith('en');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.bg(context).withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: AppTheme.textP(context), size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _restore,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.bg(context).withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              isEn ? 'Restore' : 'Pulihkan',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          AppTheme.bg(context),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 50,
                      bottom: 32,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 24,
                                  spreadRadius: 8,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.diamond_rounded,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isEn ? 'Unlock Premium' : 'Buka Akses Premium',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textP(context),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isEn
                              ? 'Get full access to all features and enjoy a completely ad-free experience.'
                              : 'Dapatkan akses penuh ke semua fitur dan nikmati pengalaman tanpa iklan.',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppTheme.textS(context),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Benefits
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.surfVar(context)),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: _buildBenefits(isEn),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        Text(
                          isEn ? 'Choose your plan' : 'Pilih paket Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textP(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Plans
                        ...List.generate(_plans.length, (i) => _buildPlanCard(i, isEn)),
                        const SizedBox(height: 16),
                        
                        // Trust / Legal text
                        Text(
                          isEn
                              ? 'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions auto-renew unless canceled.'
                              : 'Dengan berlangganan, Anda menyetujui Syarat & Ketentuan dan Kebijakan Privasi kami. Langganan diperpanjang otomatis kecuali dibatalkan.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textH(context),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Fixed Bottom CTA
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textP(context).withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isEn ? 'Continue' : 'Lanjutkan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBenefits(bool isEn) {
    final benefits = isEn
        ? [
            'Unlimited voice emotion detection',
            'Remove all banner & interstitial ads',
          ]
        : [
            'Deteksi emosi suara tanpa batas',
            'Hilangkan semua iklan banner & pop-up',
          ];
    final icons = [
      Icons.mic_rounded,
      Icons.block_rounded,
    ];

    return List.generate(benefits.length, (i) {
      return Padding(
        padding: EdgeInsets.only(bottom: i == benefits.length - 1 ? 0 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[i],
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  benefits[i],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textP(context),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlanCard(int index, bool isEn) {
    final plan = _plans[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withValues(alpha: 0.05) 
                : AppTheme.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.surfVar(context),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Radio indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textH(context),
                          width: isSelected ? 7 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? plan.labelEn : plan.label,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: AppTheme.textP(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                plan.price,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textS(context),
                                ),
                              ),
                              if (plan.period.isNotEmpty)
                                Text(
                                  isEn ? plan.periodEn : plan.period,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.textH(context),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (plan.savings.isNotEmpty && !plan.isPopular)
                      Text(
                        isEn ? plan.savingsEn : plan.savings,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Popular Badge
              if (plan.isPopular)
                Positioned(
                  top: -12,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      isEn ? 'MOST POPULAR' : 'PALING POPULER',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
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
