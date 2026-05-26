import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/premium_provider.dart';
import 'theme/app_theme.dart';
import 'services/ad_service.dart';
import 'services/subscription_service.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'models/user_model.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_detection_screen.dart';
import 'screens/history_screen.dart';
import 'screens/premium_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();

  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  final authProvider = AuthProvider();
  final premiumProvider = PremiumProvider();

  await Future.wait([
    localeProvider.init(),
    themeProvider.init(),
    authProvider.init(),
  ]);
  premiumProvider.init();

  final adService = AdService();
  adService.setProductionIds(
    bannerTop: 'ca-app-pub-1119296580292407/3050744323',
    bannerBottom: 'ca-app-pub-1119296580292407/9420711553',
    interstitial: 'ca-app-pub-1119296580292407/1598061850',
    appOpen: 'ca-app-pub-1119296580292407/6736057059',
  );
  await adService.init(premiumProvider);

  final subscriptionService = SubscriptionService();
  await subscriptionService.init(premiumProvider);

  // Fallback: load premium dari Firestore jika RevenueCat gagal
  if (!premiumProvider.isPremium && authProvider.isLoggedIn) {
    final status = await DatabaseService.loadPremiumStatus();
    if (status.isPremium) {
      premiumProvider.setPremium(value: true, expiry: status.expiry);
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: premiumProvider),
      ],
      child: const FemPhysicsMonitorApp(),
    ),
  );
}

/// Root aplikasi Fem-PhysicsMonitor
class FemPhysicsMonitorApp extends StatefulWidget {
  const FemPhysicsMonitorApp({super.key});

  @override
  State<FemPhysicsMonitorApp> createState() => _FemPhysicsMonitorAppState();
}

class _FemPhysicsMonitorAppState extends State<FemPhysicsMonitorApp>
    with WidgetsBindingObserver {
  bool _isFirstResume = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isFirstResume) {
        _isFirstResume = false;
        return;
      }

      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        AdService().showAppOpenAd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final isDark = themeProvider.isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? AppTheme.darkBackground
            : Colors.white,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Fem-Psych Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AppRouter(),
    );
  }
}

/// Router utama: cek status onboarding dan login user dari SharedPreferences.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Future.wait([
        StorageService.isFirstLaunch(),
        Future.delayed(const Duration(seconds: 3)),
      ]).then((results) => results[0] as bool),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _SplashScreen();

        final isFirstLaunch = snapshot.data!;

        // Jika first launch, tampilkan onboarding dulu
        if (isFirstLaunch) {
          return OnboardingScreen(
            onCompleted: () {
              // Setelah onboarding selesai, arahkan ke AuthScreen
              // Gunakan MaterialPageRoute untuk menghindari animation curve issues
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          );
        }

        // Jika bukan first launch, cek apakah sudah login
        final authProvider = context.watch<AuthProvider>();

        // Jika belum login, tampilkan AuthScreen
        if (!authProvider.isLoggedIn) {
          return const AuthScreen();
        }

        // Jika sudah login, cek apakah user sudah ada di database (selesai onboarding)
        return FutureBuilder<AppUser?>(
          future: DatabaseService.getUser(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }

            // Jika user belum ada di database, arahkan ke OnboardingScreen
            if (userSnapshot.data == null) {
              return OnboardingScreen(
                onCompleted: () {
                  // Setelah onboarding selesai, langsung masuk ke aplikasi.
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MainNavigation(
                        key: ValueKey('main_nav_${authProvider.username}'),
                      ),
                    ),
                  );
                },
              );
            }

            // Jika sudah ada data user, langsung ke main navigation
            // Gunakan key unik berdasarkan username untuk memastikan state direset
            return MainNavigation(
              key: ValueKey('main_nav_${authProvider.username}'),
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────
// Splash Screen Premium dengan Animasi Partikel
// ────────────────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Fem-Psych Monitor',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textP(context),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.tr('splash_subtitle'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memuat aplikasi...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textS(context),
                  ),
                ),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildFeatureCard(
                        icon: Icons.psychology_rounded,
                        label: 'MBTI Test',
                        delay: 0.2,
                      ),
                      const SizedBox(width: 12),
                      _buildFeatureCard(
                        icon: Icons.favorite_rounded,
                        label: 'Mental Health',
                        delay: 0.4,
                      ),
                      const SizedBox(width: 12),
                      _buildFeatureCard(
                        icon: Icons.mic_rounded,
                        label: 'Voice Analysis',
                        delay: 0.6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required double delay,
  }) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final slideProgress = (_controller.value - delay).clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, 50 * (1 - slideProgress)),
            child: Opacity(opacity: slideProgress),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textS(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ────────────────────────────────────────────────────────
// Main Navigation — Bottom Nav Bar Premium
// ────────────────────────────────────────────────────────
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final premium = context.read<PremiumProvider>();
      if (!premium.isPremium) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      }
    });
  }

  void _navigateToRecording() {
    setState(() => _currentIndex = 1);
  }

  void _navigateToHistory() {
    setState(() => _currentIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    // Watch locale & theme so IndexedStack rebuilds when settings change
    final localeName = context.watch<LocaleProvider>().locale;
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return Scaffold(
      body: IndexedStack(
        key: ValueKey('nav_${localeName}_${themeMode.index}'),
        index: _currentIndex,
        children: [
          HomeScreen(
            onStartRecording: _navigateToRecording,
            onNavigateToHistory: _navigateToHistory,
          ),
          const LiveDetectionScreen(),
          const HistoryScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _PremiumBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Widget: Premium Floating Bottom Navigation Bar
// ────────────────────────────────────────────────────────
class _PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: AppLocalizations.tr('nav_home'),
      ),
      (
        icon: Icons.mic_none_rounded,
        activeIcon: Icons.mic_rounded,
        label: AppLocalizations.tr('nav_record'),
      ),
      (
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: AppLocalizations.tr('nav_history'),
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF1E293B,
              ).withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withValues(
                alpha: isDark ? 0.15 : 0.08,
              ),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = currentIndex == i;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: isActive ? 40 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          key: ValueKey(isActive),
                          color: isActive
                              ? AppTheme.primaryColor
                              : (isDark
                                    ? const Color(0xFF616161)
                                    : const Color(0xFFCBD5E1)),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppTheme.primaryColor
                              : (isDark
                                    ? const Color(0xFF616161)
                                    : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
