import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/voice_detection_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inisialisasi providers sebelum runApp
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  final authProvider = AuthProvider();

  await Future.wait([
    localeProvider.init(),
    themeProvider.init(),
    authProvider.init(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const FemPhysicsMonitorApp(),
    ),
  );
}

/// Root aplikasi Fem-PhysicsMonitor
class FemPhysicsMonitorApp extends StatelessWidget {
  const FemPhysicsMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // Watch locale agar rebuild saat bahasa berubah
    context.watch<LocaleProvider>();

    // Update system UI overlay sesuai tema
    final isDark = themeProvider.isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? AppTheme.darkBackground : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Fem-PhysicsMonitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AppRouter(),
    );
  }
}

/// Router utama: cek status onboarding user dari SharedPreferences.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: StorageService.isFirstLaunch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _SplashScreen();

        final isFirstLaunch = snapshot.data!;

        if (isFirstLaunch) {
          return OnboardingScreen(
            onCompleted: () {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, a1, a2) => const MainNavigation(),
                  transitionsBuilder: (context, anim, a2, child) {
                    return FadeTransition(opacity: anim, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 600),
                ),
              );
            },
          );
        }

        return const MainNavigation();
      },
    );
  }
}

// ────────────────────────────────────────────────────────
// Splash Screen Premium
// ────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.primaryShadow,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Fem-PhysicsMonitor',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.tr('app_subtitle'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textS(context),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2.5,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
          ],
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

  void _navigateToRecording() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onStartRecording: _navigateToRecording),
          const VoiceDetectionScreen(),
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

  const _PremiumBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

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
              color: const Color(0xFF1E293B)
                  .withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryColor
                  .withValues(alpha: isDark ? 0.15 : 0.08),
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
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
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
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
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
