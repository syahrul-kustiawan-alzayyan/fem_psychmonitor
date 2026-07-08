import 'dart:async';

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
import 'services/config_service.dart';
import 'services/storage_service.dart';
import 'services/whisper_init_service.dart';
import 'widgets/gradient_background.dart';
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

  await ConfigService.load();
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
    bannerTop: ConfigService.admobBannerTop,
    bannerBottom: ConfigService.admobBannerBottom,
    interstitial: ConfigService.admobInterstitial,
    rewarded: ConfigService.admobRewarded,
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

class _FemPhysicsMonitorAppState extends State<FemPhysicsMonitorApp> {
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
      future: (() async {
        final isFirstLaunch = await StorageService.isFirstLaunch();
        await WhisperInitService.instance.warmUp();
        if (!WhisperInitService.instance.isReady) {
          await Future.delayed(const Duration(seconds: 3));
        }
        return isFirstLaunch;
      })(),
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

        // Jika sudah login, langsung ke main navigation
        return MainNavigation(
          key: ValueKey('main_nav_${authProvider.username}'),
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
  double _modelProgress = 0.0;
  String _modelStatus = '';

  @override
  void initState() {
    super.initState();
    final ws = WhisperInitService.instance;
    _modelProgress = ws.progress;
    _modelStatus = ws.statusMessage;
    ws.addProgressListener(_onModelProgress);
  }

  void _onModelProgress(double progress, String message) {
    if (mounted) setState(() { _modelProgress = progress; _modelStatus = message; });
  }

  @override
  void dispose() {
    WhisperInitService.instance.removeProgressListener(_onModelProgress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _modelProgress >= 1.0;
    final status = _modelStatus.isNotEmpty ? _modelStatus : 'Memuat aplikasi...';

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),

              // App name
              Text(
                'Fem-Psych Monitor',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 8),

              // Short description
              Text(
                AppLocalizations.tr('splash_subtitle'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textS(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Progress bar
              if (isReady)
                Icon(Icons.check_circle, color: Colors.green, size: 28)
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 200,
                    height: 4,
                    child: LinearProgressIndicator(
                      value: _modelProgress > 0 ? _modelProgress : null,
                      minHeight: 4,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _modelProgress > 0
                      ? '${(_modelProgress * 100).toStringAsFixed(0)}%'
                      : status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textS(context),
                  ),
                ),
              ],
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final premium = context.read<PremiumProvider>();
      if (!premium.isPremium) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      }
      if (!mounted) return;
      if (!WhisperInitService.instance.isReady) {
        _showModelDownloadDialog(context);
      }
    });
  }

  void _showModelDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Model Suara',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Fitur analisis suara memerlukan model bahasa untuk transkripsi. '
          'Harap sambungkan ke internet untuk mengunduh model (~150 MB).',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Nanti', style: GoogleFonts.poppins()),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text('Unduh Sekarang', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              _performModelDownload();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performModelDownload() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Text('Mengunduh model...', style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    await WhisperInitService.instance.warmUp();
    if (!mounted) return;
    if (WhisperInitService.instance.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model berhasil diunduh', style: GoogleFonts.poppins(fontSize: 12))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh. Periksa koneksi internet.', style: GoogleFonts.poppins(fontSize: 12))),
      );
    }
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
                          color: AppTheme.primaryDark,
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
                              ? AppTheme.primaryDark
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
                              ? AppTheme.primaryDark
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
