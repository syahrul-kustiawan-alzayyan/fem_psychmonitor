import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/admin_provider.dart';
import 'theme/app_theme.dart';
import 'theme/resonance_colors.dart';
import 'services/ad_service.dart';
import 'services/billing_service.dart';
import 'services/database_service.dart';
import 'services/config_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_detection_screen.dart';
import 'screens/history_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ConfigService.load();
  await Firebase.initializeApp();

  // Notifikasi pengingat harian (aman di-skip bila platform tidak mendukung)
  try {
    await NotificationService.instance.init();
    // Auto-request permission & schedule on first launch
    await NotificationService.instance.requestAndSchedule();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

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
    appOpen: ConfigService.admobAppOpen,
  );
  await adService.init(premiumProvider);

  final billingService = BillingService();
  await billingService.init(premiumProvider);
  // Restore & re-verifikasi status premium (server = sumber kebenaran)
  await billingService.refreshFromServer(premiumProvider);

  // Auto-create admin account if not exists
  final adminEmail = ConfigService.adminEmail;
  final adminPassword = ConfigService.adminPassword;
  if (adminEmail.isNotEmpty && adminPassword.isNotEmpty) {
    final exists = await DatabaseService.adminExists();
    if (!exists) {
      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        await DatabaseService.upsertUser(
          uid: userCredential.user!.uid,
          name: 'Admin',
          email: adminEmail,
          isAdmin: true,
        );
        await userCredential.user!.updateDisplayName('Admin');
        debugPrint('Admin account created: $adminEmail');
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') {
          debugPrint('Failed to create admin: $e');
        }
      }
    } else {
      debugPrint('Admin account already exists');
    }
  }

  final adminProvider = AdminProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: premiumProvider),
        ChangeNotifierProvider.value(value: adminProvider),
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
  bool _hasResumed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdService().loadAppOpenAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_hasResumed) {
        AdService().showAppOpenAd();
      }
      _hasResumed = true;
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

enum _RouteAction { splash, onboarding, auth, main, admin }

/// Router utama: cek status onboarding, login, dan validasi data user.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RouteAction>(
      future: (() async {
        // NOTE: tidak ada unduh model saat startup. Transkripsi utama
        // dari server (/transcribe); Whisper on-device hanya fallback
        // dan diunduh sesuai kebutuhan di layar deteksi.
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final isAdmin = await DatabaseService.isCurrentUserAdmin();
            if (isAdmin) {
              return _RouteAction.admin;
            }

            final appUser = await DatabaseService.getUser();
            final hasData = appUser != null && appUser.bigFiveScores.isNotEmpty;
            if (hasData) {
              await StorageService.setOnboardingComplete('');
              return _RouteAction.main;
            }
            return _RouteAction.onboarding;
          }
        } catch (_) {}

        final isFirstLaunch = await StorageService.isFirstLaunch();
        if (isFirstLaunch) {
          return _RouteAction.onboarding;
        }
        return _RouteAction.auth;
      })(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _SplashScreen();

        switch (snapshot.data!) {
          case _RouteAction.onboarding:
            return OnboardingScreen(
              onCompleted: () {
                final loggedIn = FirebaseAuth.instance.currentUser != null;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => loggedIn
                        ? const MainNavigation()
                        : const AuthScreen(),
                  ),
                );
              },
            );

          case _RouteAction.auth:
            return const AuthScreen();

          case _RouteAction.main:
            return MainNavigation(
              key: ValueKey('main_nav_${DateTime.now().millisecondsSinceEpoch}'),
            );

          case _RouteAction.admin:
            return const AdminDashboardScreen();

          case _RouteAction.splash:
            return const _SplashScreen();
        }
      },
    );
  }
}

// ────────────────────────────────────────────────────────
// Splash Screen — statis, tanpa unduh model.
// (Transkripsi utama dari server; model on-device hanya fallback.)
// ────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Stack(
        children: [
          // Dekorasi lembut
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryContainer.withValues(alpha: 0.55),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2B6BF).withValues(alpha: 0.3),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo tile
                  Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: c.surfaceLowest,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4024161C),
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // App name
                  Text(
                    'Fem-Psych Monitor',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: c.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Short description
                  Text(
                    AppLocalizations.tr('splash_subtitle'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: c.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
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

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final appUser = await DatabaseService.getUser();
        final hasData = appUser != null && appUser.bigFiveScores.isNotEmpty;
        if (!hasData) {
          if (!mounted) return;
          final go = await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surface(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text(AppLocalizations.tr('incomplete_data_title'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18))),
                ],
              ),
              content: Text(
                AppLocalizations.tr('incomplete_data_desc'),
                style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(AppLocalizations.tr('later'), style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.tr('fill_now'), style: GoogleFonts.poppins()),
                ),
              ],
            ),
          );
          if (go == true && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (ctx) => OnboardingScreen(
                  onCompleted: () {
                    Navigator.of(ctx).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                    );
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      final premium = context.read<PremiumProvider>();
      if (!premium.isPremium) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      }
      // NOTE: tidak ada unduh/prompt model suara di awal. Transkripsi
      // utama dari server; Whisper on-device hanya fallback sesuai kebutuhan.
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
      backgroundColor: AppTheme.bg(context),
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
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4A3B41)
                  : const Color(0xFFE2D7D1),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1424161C),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(2, 2),
              ),
              BoxShadow(
                color: const Color(0x4024161C),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(4, 4),
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
                        style: GoogleFonts.spaceGrotesk(
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
