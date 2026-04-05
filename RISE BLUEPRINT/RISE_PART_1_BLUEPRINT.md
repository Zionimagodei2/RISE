# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 1 OF 12
# Foundation: Project Setup, Theme System, App Shell
# ============================================================
# COMMAND TO AI CODING AGENT:
# You are building a Flutter application called RISE — an AI-powered
# alarm clock that is biometrically secured, psychologically stubborn,
# and beautifully designed. This is Part 1 of 12. Your job is to
# create EVERY file listed below, EXACTLY as specified. Do not
# improvise. Do not skip files. Do not simplify. Every line of
# code here is intentional. After creating all files, run
# `flutter pub get` to verify dependencies resolve correctly.
# ============================================================

## PROJECT OVERVIEW (For Agent Context)

App Name: RISE
Bundle ID (Android): com.rise.alarmclock
Bundle ID (iOS): com.rise.alarmclock
Min Android SDK: 26 (Android 8.0) — required for exact alarms + foreground services
Min iOS Version: 14.0 — required for critical alerts + background modes
Flutter Version: 3.24.0 or later
Dart Version: 3.4.0 or later

## PART 1 CREATES THESE FILES:

1. pubspec.yaml
2. lib/main.dart
3. lib/app.dart
4. lib/core/theme/app_colors.dart
5. lib/core/theme/app_text_styles.dart
6. lib/core/theme/app_theme.dart
7. lib/core/constants/app_constants.dart
8. lib/core/constants/app_strings.dart
9. lib/core/constants/asset_paths.dart
10. lib/shared/widgets/rise_button.dart
11. lib/shared/widgets/rise_card.dart
12. lib/shared/widgets/rise_scaffold.dart
13. lib/features/home/home_screen.dart (placeholder shell — wired up in later parts)
14. android/app/src/main/AndroidManifest.xml (FULL — includes all permissions)
15. ios/Runner/Info.plist (FULL — includes all permissions and background modes)

---

## FILE 1: pubspec.yaml
## PATH: pubspec.yaml
## PURPOSE: All dependencies for the entire RISE project are declared here.
##          Every package is pinned to a specific version to prevent
##          breaking changes during development.

```yaml
name: rise_alarm
description: RISE — The AI Alarm Clock That Will Not Let You Sleep In
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ── CORE STATE MANAGEMENT ──────────────────────────────────────────
  flutter_riverpod: ^2.5.1        # State management — chosen over BLoC for
                                   # simplicity in an agentic coding workflow
  riverpod_annotation: ^2.3.5

  # ── LOCAL DATABASE ─────────────────────────────────────────────────
  hive_flutter: ^1.1.0            # Local offline-first storage for alarms,
                                   # sleep data, biometric profiles
  hive: ^2.2.3

  # ── ALARM ENGINE ───────────────────────────────────────────────────
  flutter_local_notifications: ^17.2.2  # Core notification + alarm scheduling
  android_alarm_manager_plus: ^3.0.4    # Android exact alarm scheduling
  wakelock_plus: ^1.2.8                 # Prevent screen/CPU sleep during alarm
  volume_controller: ^2.0.7            # Override volume on alarm fire

  # ── BIOMETRICS & CAMERA ────────────────────────────────────────────
  camera: ^0.11.0+2               # PPG heart rate detection via camera flash
  google_ml_kit: ^0.19.0          # Face detection for liveness check
  local_auth: ^2.3.0              # Device biometric (fingerprint/face) as
                                   # fallback identity layer

  # ── PERMISSIONS ────────────────────────────────────────────────────
  permission_handler: ^11.3.1     # Runtime permissions (camera, mic, location,
                                   # notifications, exact alarm)
  app_settings: ^5.1.1            # Deep-link to device settings for permissions

  # ── NAVIGATION ─────────────────────────────────────────────────────
  go_router: ^14.2.7              # Declarative routing — handles deep links
                                   # from notification taps and alarm screens

  # ── BACKGROUND SERVICES ────────────────────────────────────────────
  flutter_background_service: ^5.0.9   # Persistent foreground service (Android)
                                        # that cannot be killed by OS or user
  workmanager: ^0.5.2                  # Periodic background tasks (sleep check,
                                        # geofence polling)

  # ── SENSORS ────────────────────────────────────────────────────────
  sensors_plus: ^5.0.1            # Accelerometer for sleep motion detection
  noise_meter: ^6.0.2             # Microphone — detects snoring/breathing
                                   # (opt-in only, clearly disclosed)

  # ── LOCATION & GEOFENCING ──────────────────────────────────────────
  geolocator: ^13.0.1             # GPS location
  geofence_service: ^5.0.2        # Geofence trigger when user leaves/returns home

  # ── SMART HOME ─────────────────────────────────────────────────────
  # Smart home SDKs are loaded dynamically — they're optional integrations
  # that the user enables. Base packages declared here.
  url_launcher: ^6.3.0            # Launch Alexa/Google Home deep links

  # ── MONETIZATION ───────────────────────────────────────────────────
  purchases_flutter: ^8.0.0       # RevenueCat — handles ALL subscription logic,
                                   # receipt validation, trial periods, restores
  google_mobile_ads: ^5.1.0       # AdMob — for the ad-supported calorie tracker

  # ── CALORIE TRACKER ────────────────────────────────────────────────
  http: ^1.2.2                    # HTTP calls to Open Food Facts API
  barcode_scan2: ^4.3.3           # Barcode scanning for food items
  image_picker: ^1.1.2            # Photo-based food recognition (premium)

  # ── WHATSAPP / BUDDY NOTIFICATIONS ────────────────────────────────
  # WhatsApp integration uses URL scheme deep-linking (no API needed)
  # wa.me links are launched via url_launcher — no WhatsApp Business API required

  # ── FIREBASE ───────────────────────────────────────────────────────
  firebase_core: ^3.4.0
  firebase_auth: ^5.2.1
  cloud_firestore: ^5.4.1         # User profiles, sync across devices
  firebase_analytics: ^11.3.0
  firebase_crashlytics: ^4.1.0    # Crash reporting — critical for alarm app

  # ── UI & ANIMATIONS ────────────────────────────────────────────────
  animate_do: ^3.3.4              # Entrance animations
  flutter_animate: ^4.5.0         # Comprehensive animation toolkit
  lottie: ^3.1.2                  # Lottie animations for onboarding + games
  shimmer: ^3.0.0                 # Loading shimmer effects
  cached_network_image: ^3.4.1    # Cached image loading
  fl_chart: ^0.69.0               # Sleep analytics charts, calorie charts
  percent_indicator: ^4.2.3       # Circular/linear progress for games + sleep

  # ── UTILITIES ──────────────────────────────────────────────────────
  intl: ^0.19.0                   # Date/time formatting, localization
  shared_preferences: ^2.3.2      # Lightweight key-value (onboarding state,
                                   # quick settings — not for alarm data)
  path_provider: ^2.1.4           # File system paths for Hive DB
  connectivity_plus: ^6.0.5       # Network state (offline graceful degradation)
  package_info_plus: ^8.0.2       # App version display
  device_info_plus: ^10.1.2       # Device model (affects PPG calibration)
  uuid: ^4.4.2                    # Unique IDs for alarms, sessions
  equatable: ^2.0.5               # Value equality for models
  freezed_annotation: ^2.4.4      # Immutable model generation
  json_annotation: ^4.9.0         # JSON serialization
  logger: ^2.4.0                  # Structured logging (debug only)
  timezone: ^0.9.4                # Critical: timezone-aware alarm scheduling
  flutter_timezone: ^1.0.7        # Get device timezone string

  # ── ICONS & FONTS ──────────────────────────────────────────────────
  flutter_svg: ^2.0.10+1          # SVG rendering for UI icons
  google_fonts: ^6.2.1            # Typography

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  hive_generator: ^2.0.1
  flutter_launcher_icons: ^0.14.1
  flutter_native_splash: ^2.4.1

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/animations/
    - assets/sounds/
    - assets/data/

  fonts:
    - family: RiseDisplay
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
        - asset: assets/fonts/Inter-ExtraBold.ttf
          weight: 800
```

---

## FILE 2: lib/main.dart
## PATH: lib/main.dart
## PURPOSE: Application entry point. Initializes all services in the
##          correct order. Order matters here — Firebase must init before
##          Hive, Hive before services, services before app launch.
##          Handles the case where app is launched FROM an alarm notification
##          (foreground service tap) vs. normal launch.

```dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart'; // Generated by FlutterFire CLI

// ─────────────────────────────────────────────────────────────────────────────
// MAIN ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
// AGENT NOTE: This function MUST complete all async initialization before
// runApp() is called. Any failure in initialization should be caught and
// reported to Crashlytics — the app must NEVER fail silently on startup
// because a missed alarm due to a crash is a critical product failure.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  // Ensure Flutter binding is initialized before any async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all errors in the Flutter framework and report to Crashlytics
  // This is the outermost error boundary
  await runZonedGuarded(
    () async {
      // ── Step 1: Firebase (must be first — Crashlytics depends on it) ──
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ── Step 2: Configure Crashlytics ───────────────────────────────
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlyticsService.recordFlutterError(errorDetails);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlyticsService.recordError(error, stack);
        return true;
      };

      // ── Step 3: Initialize Timezone Database ─────────────────────────
      // CRITICAL: Without this, alarm scheduling in different timezones
      // will fire at the wrong time — this is NOT optional
      tz.initializeTimeZones();
      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));

      // ── Step 4: Initialize Hive (local database) ─────────────────────
      final appDocumentDirectory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);

      // Register ALL Hive adapters here
      // Adapters are generated by hive_generator — run `dart run build_runner build`
      _registerHiveAdapters();

      // Open all required Hive boxes
      await _openHiveBoxes();

      // ── Step 5: System UI Configuration ──────────────────────────────
      // RISE uses a dark-first design — status bar is transparent
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0A0A0F),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // Lock orientation to portrait (alarm interaction is portrait-only)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // ── Step 6: Launch App ────────────────────────────────────────────
      runApp(
        // ProviderScope is the Riverpod root — wraps entire widget tree
        const ProviderScope(
          child: RiseApp(),
        ),
      );
    },
    // Catch any error that escapes the Flutter framework error handler
    (error, stackTrace) async {
      await FirebaseCrashlyticsService.recordError(error, stackTrace);
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HIVE ADAPTER REGISTRATION
// ─────────────────────────────────────────────────────────────────────────────
// AGENT NOTE: Every Hive model that uses @HiveType annotation needs its
// generated adapter registered here. Adapters are created in Part 2.
// Add to this list as models are created. Type IDs must be unique (0-255).
// ─────────────────────────────────────────────────────────────────────────────
void _registerHiveAdapters() {
  // Adapters will be registered here as models are built in Part 2.
  // Example structure (do not remove this comment):
  // if (!Hive.isAdapterRegistered(0)) {
  //   Hive.registerAdapter(AlarmModelAdapter());       // typeId: 0
  // }
  // if (!Hive.isAdapterRegistered(1)) {
  //   Hive.registerAdapter(SleepSessionAdapter());     // typeId: 1
  // }
  // if (!Hive.isAdapterRegistered(2)) {
  //   Hive.registerAdapter(BiometricProfileAdapter()); // typeId: 2
  // }
  // if (!Hive.isAdapterRegistered(3)) {
  //   Hive.registerAdapter(CalorieLogAdapter());       // typeId: 3
  // }
  // if (!Hive.isAdapterRegistered(4)) {
  //   Hive.registerAdapter(FoodEntryAdapter());        // typeId: 4
  // }
}

// ─────────────────────────────────────────────────────────────────────────────
// HIVE BOX INITIALIZATION
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _openHiveBoxes() async {
  // Boxes are opened lazily here so the app can access them anywhere
  // via Hive.box<T>(AppConstants.boxName) without async calls
  await Future.wait([
    Hive.openBox<dynamic>(AppConstants.alarmsBoxName),
    Hive.openBox<dynamic>(AppConstants.sleepSessionsBoxName),
    Hive.openBox<dynamic>(AppConstants.biometricProfilesBoxName),
    Hive.openBox<dynamic>(AppConstants.calorieLogsBoxName),
    Hive.openBox<dynamic>(AppConstants.settingsBoxName),
    Hive.openBox<dynamic>(AppConstants.questionBankBoxName),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// CRASHLYTICS SERVICE WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
// Thin wrapper so we can conditionally disable in debug mode
class FirebaseCrashlyticsService {
  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
      return;
    }
    await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  static Future<void> recordError(Object error, StackTrace? stack) async {
    if (kDebugMode) {
      debugPrint('ERROR: $error\n$stack');
      return;
    }
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  }
}
```

---

## FILE 3: lib/app.dart
## PATH: lib/app.dart
## PURPOSE: Root MaterialApp widget. Configures the router, theme,
##          and top-level providers. This is where the app's visual
##          identity is established.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/home/home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RISE APP ROOT
// ─────────────────────────────────────────────────────────────────────────────
class RiseApp extends ConsumerWidget {
  const RiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // RISE is dark-first by design

      // ── Router ────────────────────────────────────────────────────
      routerConfig: _router,

      // ── Localization ─────────────────────────────────────────────
      // Full localization added in Part 11 (onboarding)
      // Placeholder structure declared here
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────
// AGENT NOTE: All routes are declared here. Routes added in later parts
// will be inserted into this router. The shell route wraps screens that
// need the bottom navigation bar. The alarm screen is a FULL SCREEN route
// that overrides everything — it cannot be navigated away from without
// completing the wake game.
// ─────────────────────────────────────────────────────────────────────────────
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Shell Route (app with bottom nav) ───────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        // Routes added in later parts:
        // '/alarm-setup'    → Part 3
        // '/sleep-tracker'  → Part 5
        // '/calorie-tracker' → Part 8
        // '/settings'       → Part 11
        // '/upgrade'        → Part 9
      ],
    ),

    // ── Alarm Screen (full screen — no nav bar) ──────────────────────
    // Added in Part 7. Declared as placeholder here.
    GoRoute(
      path: '/alarm-firing',
      name: 'alarmFiring',
      builder: (context, state) {
        // Placeholder — full implementation in Part 7
        return const Scaffold(
          backgroundColor: Color(0xFF0A0A0F),
          body: Center(
            child: Text(
              'ALARM SCREEN\n(Part 7)',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    ),

    // ── Biometric Enrollment ──────────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) {
        // Placeholder — full implementation in Part 11
        return const Scaffold(
          backgroundColor: Color(0xFF0A0A0F),
          body: Center(
            child: Text(
              'ONBOARDING\n(Part 11)',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SHELL — App frame with bottom navigation
// ─────────────────────────────────────────────────────────────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _RiseBottomNav(),
    );
  }
}

class _RiseBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accentColor,
        unselectedItemColor: Colors.white.withOpacity(0.35),
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onNavTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_rounded),
            label: 'Alarms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime_rounded),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_rounded),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/sleep')) return 1;
    if (location.startsWith('/calorie')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/sleep-tracker');
        break;
      case 2:
        context.go('/calorie-tracker');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
```

---

## FILE 4: lib/core/theme/app_colors.dart
## PATH: lib/core/theme/app_colors.dart
## PURPOSE: The complete color system for RISE. Every color used anywhere
##          in the app comes from here. Never use hardcoded Color() values
##          outside this file. RISE uses a dark space-inspired palette.

```dart
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RISE COLOR SYSTEM
// Design philosophy: RISE is used at 2am and 6am. Colors must be:
//   1. Easy on eyes at 2am (not blinding white)
//   2. Energizing at 6am (accent colors that signal "wake up")
//   3. Trustworthy (users are trusting RISE with their mornings)
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._(); // prevent instantiation

  // ── Background Scale (dark) ────────────────────────────────────────
  // Layered dark backgrounds — never pure #000000 (too harsh at night)
  static const Color backgroundDeep   = Color(0xFF0A0A0F); // Deepest layer
  static const Color backgroundBase   = Color(0xFF0F0F18); // Main screen bg
  static const Color backgroundSurface = Color(0xFF16161F); // Cards, sheets
  static const Color backgroundElevated = Color(0xFF1E1E2A); // Dialogs, modals
  static const Color backgroundHighlight = Color(0xFF252535); // Selected states

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF5F5F7); // Main body text
  static const Color textSecondary = Color(0xFFABABBF); // Supporting text
  static const Color textTertiary  = Color(0xFF6B6B80); // Hint, disabled
  static const Color textInverse   = Color(0xFF0A0A0F); // Text on bright bg

  // ── Accent (The "Rise" Orange-Gold — dawn inspired) ───────────────
  // This color says "sunrise" — it's warm, energetic, optimistic
  static const Color accent         = Color(0xFFFF8C42); // Primary CTA
  static const Color accentLight    = Color(0xFFFFAD75); // Hover/lighter state
  static const Color accentDark     = Color(0xFFE5721D); // Pressed state
  static const Color accentSubtle   = Color(0x26FF8C42); // 15% opacity bg tint

  // ── Secondary Accent (Electric Blue — alertness) ─────────────────
  // Used for the alarm firing screen and critical alerts
  static const Color electric       = Color(0xFF4DA8FF); // Electric blue
  static const Color electricSubtle = Color(0x264DA8FF); // 15% opacity

  // ── Status / Semantic Colors ──────────────────────────────────────
  static const Color success        = Color(0xFF34C777); // Green — game passed
  static const Color successSubtle  = Color(0x2634C777);
  static const Color warning        = Color(0xFFFFB547); // Amber — 1 snooze left
  static const Color warningSubtle  = Color(0x26FFB547);
  static const Color danger         = Color(0xFFFF4757); // Red — final warning
  static const Color dangerSubtle   = Color(0x26FF4757);

  // ── Sleep Quality Colors (used in sleep charts) ───────────────────
  static const Color sleepDeep   = Color(0xFF6366F1); // Deep sleep
  static const Color sleepLight  = Color(0xFF818CF8); // Light sleep
  static const Color sleepREM    = Color(0xFFA78BFA); // REM
  static const Color sleepAwake  = Color(0xFF6B6B80); // Awake periods

  // ── Game Colors (each wake game has a signature color) ────────────
  static const Color gameMath      = Color(0xFF34C777); // Math — green (go)
  static const Color gameTrace     = Color(0xFF4DA8FF); // Trace — blue (focus)
  static const Color gameMemory    = Color(0xFFAB47BC); // Memory — purple
  static const Color gameKnowledge = Color(0xFFFF8C42); // Knowledge — orange
  static const Color gameWord      = Color(0xFFFFB547); // Word — amber

  // ── Subscription Tier Colors ──────────────────────────────────────
  static const Color tierFree      = Color(0xFF6B6B80); // Lite — grey
  static const Color tierPro       = Color(0xFFFF8C42); // Pro — gold/orange
  static const Color tierGuardian  = Color(0xFF4DA8FF); // Guardian — blue
  static const Color tierForever   = Color(0xFFAB47BC); // Forever — purple

  // ── Dividers & Borders ────────────────────────────────────────────
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white
  static const Color borderMedium = Color(0x29FFFFFF); // 16% white
  static const Color borderStrong = Color(0x3DFFFFFF); // 24% white

  // ── Overlay ───────────────────────────────────────────────────────
  static const Color overlay20 = Color(0x33000000);
  static const Color overlay50 = Color(0x80000000);
  static const Color overlay80 = Color(0xCC000000);

  // ── Light Theme Colors (used when user manually sets light mode) ──
  // RISE recommends dark but respects system preference
  static const Color lightBackground = Color(0xFFF8F8FC);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0A0A0F);
  static const Color lightTextSecondary = Color(0xFF4A4A5A);
  static const Color lightBorder     = Color(0xFFE5E5ED);
}
```

---

## FILE 5: lib/core/theme/app_text_styles.dart
## PATH: lib/core/theme/app_text_styles.dart
## PURPOSE: Typography scale for RISE. Uses Inter (loaded from Google Fonts).
##          Consistent text styles prevent visual debt accumulating over time.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RISE TYPOGRAPHY SYSTEM
// All text in the app uses one of these defined styles.
// NEVER use TextStyle() inline in widgets — always reference this class.
// ─────────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter(
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Display (Hero text — alarm time, large numbers) ───────────────
  static TextStyle get displayXL => _base.copyWith(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2.0,
  );

  static TextStyle get displayLG => _base.copyWith(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.5,
  );

  static TextStyle get displayMD => _base.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.0,
  );

  // ── Headings ──────────────────────────────────────────────────────
  static TextStyle get h1 => _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static TextStyle get h3 => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle get h4 => _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // ── Body ──────────────────────────────────────────────────────────
  static TextStyle get bodyLG => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMD => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySM => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Labels ────────────────────────────────────────────────────────
  static TextStyle get labelLG => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMD => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle get labelSM => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ── Caption ───────────────────────────────────────────────────────
  static TextStyle get caption => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  // ── Monospace (alarm time display, game timers) ───────────────────
  static TextStyle get mono => GoogleFonts.robotoMono(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get monoLG => GoogleFonts.robotoMono(
    color: AppColors.textPrimary,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
  );

  // ── Game-specific (high contrast for alarm state) ─────────────────
  static TextStyle get gameQuestion => _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get gameAnswer => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static TextStyle get gameTimer => GoogleFonts.robotoMono(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    height: 1.0,
  );
}
```

---

## FILE 6: lib/core/theme/app_theme.dart
## PATH: lib/core/theme/app_theme.dart
## PURPOSE: MaterialTheme data objects. Applies color system and typography
##          to every Flutter built-in widget automatically.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RISE THEME CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // Expose accent color for use in app.dart and other files
  static const Color accentColor = AppColors.accent;

  // ── Dark Theme (Primary) ──────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.electric,
        onSecondary: AppColors.textInverse,
        surface: AppColors.backgroundSurface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: AppColors.textPrimary,
        outline: AppColors.borderSubtle,
      ),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.backgroundBase,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTextStyles.h3,
        centerTitle: false,
      ),

      // Bottom Nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDeep,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button (Primary CTA)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverse,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.labelLG,
          elevation: 0,
        ),
      ),

      // Outlined Button (Secondary CTA)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: AppColors.borderMedium),
          textStyle: AppTextStyles.labelLG,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.labelMD,
        ),
      ),

      // Input fields (used in alarm setup, calorie search)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: AppTextStyles.bodyMD.copyWith(color: AppColors.textTertiary),
        hintStyle: AppTextStyles.bodyMD.copyWith(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accentSubtle;
          return AppColors.backgroundHighlight;
        }),
      ),

      // Slider (volume, time adjustments)
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.backgroundHighlight,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accentSubtle,
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.backgroundHighlight,
      ),

      // Chip (game categories, days of week selector)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSurface,
        selectedColor: AppColors.accentSubtle,
        labelStyle: AppTextStyles.labelMD,
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 0.5,
        space: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMD.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.backgroundElevated,
        contentTextStyle: AppTextStyles.bodyMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayXL,
        displayMedium: AppTextStyles.displayLG,
        displaySmall: AppTextStyles.displayMD,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h4,
        bodyLarge: AppTextStyles.bodyLG,
        bodyMedium: AppTextStyles.bodyMD,
        bodySmall: AppTextStyles.bodySM,
        labelLarge: AppTextStyles.labelLG,
        labelMedium: AppTextStyles.labelMD,
        labelSmall: AppTextStyles.labelSM,
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.electric,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      // Light theme inherits most settings from dark — specific overrides
      // are applied per-widget as needed. Full light theme polish in Part 11.
    );
  }
}
```

---

## FILE 7: lib/core/constants/app_constants.dart
## PATH: lib/core/constants/app_constants.dart
## PURPOSE: All magic numbers, timing values, and configuration constants.
##          If you find yourself writing a raw number in a widget, it belongs here.

```dart
// ─────────────────────────────────────────────────────────────────────────────
// RISE APP CONSTANTS
// Single source of truth for all configuration values.
// ─────────────────────────────────────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  // ── App Identity ──────────────────────────────────────────────────
  static const String appName = 'RISE';
  static const String appTagline = 'The Alarm Clock That Never Gives Up';
  static const String bundleId = 'com.rise.alarmclock';

  // ── Hive Box Names ────────────────────────────────────────────────
  static const String alarmsBoxName           = 'alarms_v1';
  static const String sleepSessionsBoxName    = 'sleep_sessions_v1';
  static const String biometricProfilesBoxName = 'biometric_profiles_v1';
  static const String calorieLogsBoxName      = 'calorie_logs_v1';
  static const String settingsBoxName         = 'settings_v1';
  static const String questionBankBoxName     = 'question_bank_v1';

  // ── Alarm Behavior ────────────────────────────────────────────────
  static const int maxSnoozeCountFree         = 3;    // Lite tier: 3 snoozes max
  static const int maxSnoozeCountPro          = 5;    // Pro tier: 5 snoozes max
  static const int snoozeInterval1Minutes     = 7;    // 1st snooze: 7 min
  static const int snoozeInterval2Minutes     = 5;    // 2nd snooze: 5 min
  static const int snoozeInterval3Minutes     = 3;    // 3rd snooze: 3 min
  static const int snoozeInterval4Minutes     = 3;    // 4th: no snooze (ignored)
  static const int alarmVolumeEscalationStep  = 10;   // +10% volume per 90sec
  static const int alarmVolumeEscalationInterval = 90; // seconds between escalations
  static const int alarmInitialVolumePercent  = 40;   // Start at 40% volume
  static const int alarmMaxVolumePercent      = 100;  // Max alarm volume

  // ── Biometric Enrollment ──────────────────────────────────────────
  static const int ppgEnrollmentDays          = 5;    // 5 readings over 5 days
  static const int ppgReadingDurationSeconds  = 8;    // Duration of PPG capture
  static const double ppgMatchToleranceBPM    = 12.0; // ±12 BPM tolerance
  static const double ppgConfidenceThreshold  = 0.72; // 72% confidence minimum
  static const int faceEnrollmentFrames       = 30;   // Frames for face profile

  // ── Sleep Detection ───────────────────────────────────────────────
  static const int minSleepMinutesForVerification = 60; // Must sleep 60+ min
  static const int sleepOnsetStillnessSeconds    = 180; // 3 min still = sleep onset
  static const double sleepMotionThreshold        = 0.15; // Accelerometer threshold
  static const int sleepCheckIntervalMinutes      = 15; // Check sleep state every 15min

  // ── Wake Games ────────────────────────────────────────────────────
  static const int mathGameQuestionsEasy    = 3;  // Snooze 1: 3 questions
  static const int mathGameQuestionsMedium  = 4;  // Snooze 2: 4 questions
  static const int mathGameQuestionsHard    = 5;  // Snooze 3: 5 questions
  static const int gameWrongAnswerPenaltySeconds = 30; // Wrong answer adds 30sec
  static const int gameTimerSecondsEasy     = 60;  // 60 second timer easy mode
  static const int gameTimerSecondsMedium   = 45;  // 45 seconds medium
  static const int gameTimerSecondsHard     = 30;  // 30 seconds hard mode
  static const int traceGameAccuracyPercent = 75;  // Must trace 75% accurately

  // ── PPG & Heart Rate ──────────────────────────────────────────────
  static const int ppgFramesPerSecond       = 30;  // Camera FPS for PPG
  static const int ppgBufferSize            = 256; // Sample buffer
  static const double ppgRedChannelWeight   = 0.85; // Red channel dominant for PPG
  static const double ppgGreenChannelWeight = 0.15;

  // ── Geofencing ────────────────────────────────────────────────────
  static const double homeGeofenceRadiusMeters = 500.0; // 500m home radius
  static const double awayThresholdMeters       = 500.0; // Away if >500m from home

  // ── Calorie Tracker ───────────────────────────────────────────────
  static const String openFoodFactsBaseUrl = 'https://world.openfoodfacts.org';
  static const int defaultDailyCalorieGoal = 2000;
  static const int adUnlockHours           = 24;   // Watch ad → 24hr premium tracker
  static const int adsToWatchForUnlock     = 2;    // Must watch 2 ads

  // ── Monetization ─────────────────────────────────────────────────
  static const String revenueCatApiKey     = 'REPLACE_WITH_REVENUECAT_API_KEY';
  static const String productIdPro         = 'rise_pro_monthly';
  static const String productIdProAnnual   = 'rise_pro_annual';
  static const String productIdGuardian    = 'rise_guardian_monthly';
  static const String productIdForever     = 'rise_forever_lifetime';
  static const String productIdSnoozePack  = 'rise_snooze_pack_3';
  static const int freeAlarmLimit          = 2;    // Free tier: 2 alarms

  // ── WhatsApp Buddy ────────────────────────────────────────────────
  static const String whatsappScheme = 'whatsapp://send';
  static const String buddyDefaultMessage =
      '🚨 Hey! {name} set an alarm for {time} and still hasn\'t woken up. '
      'Can you give them a nudge? (Sent by RISE)';

  // ── Notification Channels ─────────────────────────────────────────
  static const String alarmChannelId     = 'rise_alarm_channel';
  static const String alarmChannelName   = 'RISE Alarms';
  static const String buddyChannelId     = 'rise_buddy_channel';
  static const String buddyChannelName   = 'Buddy Alerts';
  static const String reminderChannelId  = 'rise_reminder_channel';
  static const String reminderChannelName = 'Reminders';

  // ── Animation Durations ───────────────────────────────────────────
  static const Duration animFast    = Duration(milliseconds: 200);
  static const Duration animMedium  = Duration(milliseconds: 350);
  static const Duration animSlow    = Duration(milliseconds: 500);
  static const Duration animPageTransition = Duration(milliseconds: 300);

  // ── UI Dimensions ─────────────────────────────────────────────────
  static const double borderRadiusSM  = 8.0;
  static const double borderRadiusMD  = 12.0;
  static const double borderRadiusLG  = 16.0;
  static const double borderRadiusXL  = 24.0;
  static const double borderRadiusFull = 100.0;

  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  static const double buttonHeight    = 56.0;
  static const double inputHeight     = 52.0;
  static const double appBarHeight    = 56.0;
  static const double bottomNavHeight = 72.0;
  static const double cardPadding     = 16.0;
}
```

---

## FILE 8: lib/core/constants/app_strings.dart
## PATH: lib/core/constants/app_strings.dart
## PURPOSE: All user-facing text strings. Centralizing strings enables
##          future localization without changing widget code.

```dart
class AppStrings {
  AppStrings._();

  // App identity
  static const String appName    = 'RISE';
  static const String appTagline = 'The alarm clock that never gives up';

  // Alarm states
  static const String alarmFiringTitle  = 'Time to Rise';
  static const String alarmFiringBody   = 'Prove you\'re awake to dismiss';
  static const String snoozeLabel       = 'Snooze';
  static const String dismissLabel      = 'I\'m Up';
  static const String snoozeWarning2    = '1 snooze remaining';
  static const String snoozeWarningFinal = 'No more snoozes — wake up!';
  static const String snoozeBuyLabel    = 'Buy 3 Extra Snoozes — \$0.99';

  // Biometric
  static const String ppgTitle      = 'Identity Check';
  static const String ppgInstruction = 'Cover the camera with your finger';
  static const String ppgVerifying  = 'Verifying it\'s really you...';
  static const String ppgSuccess    = 'Identity confirmed ✓';
  static const String ppgFailed     = 'This isn\'t you. Alarm escalating.';
  static const String ppgEnrollTitle = 'Set Your Biometric Profile';
  static const String ppgEnrollBody  =
      'RISE uses your heart rate signature to make sure no one else can '
      'dismiss your alarm. Cover the camera with your finger to begin.';

  // Wake games
  static const String gameSelectTitle    = 'Wake Up Challenge';
  static const String mathGameTitle      = 'Math Sprint';
  static const String traceGameTitle     = 'Shape Trace';
  static const String memoryGameTitle    = 'Memory Mirror';
  static const String knowledgeGameTitle = 'Knowledge Spark';
  static const String wordGameTitle      = 'Word Unscramble';
  static const String gamePassedMessage  = 'Brain activated! Rising...';
  static const String gameFailedMessage  = 'Try again! +30 seconds';

  // Sleep tracking
  static const String sleepTrackerTitle  = 'Sleep';
  static const String bedtimeLabel       = 'Bedtime';
  static const String wakeTimeLabel      = 'Wake Time';
  static const String sleepDurationLabel = 'Duration';
  static const String sleepQualityLabel  = 'Quality';
  static const String noSleepDataYet     = 'Set an alarm tonight to start tracking';

  // Calorie tracker
  static const String calorieTrackerTitle = 'Nutrition';
  static const String calorieGoalLabel    = 'Daily Goal';
  static const String logMealLabel        = 'Log a Meal';
  static const String scanBarcodeLabel    = 'Scan Barcode';
  static const String searchFoodLabel     = 'Search Food';
  static const String watchAdToUnlock     =
      'Watch 2 short ads to unlock full nutrition tracking for 24 hours — free.';
  static const String adFreeWithPro       =
      'RISE Pro includes full nutrition tracking — no ads, ever.';

  // Monetization — copy is carefully written to NOT feel pushy
  static const String upgradeTitle        = 'Unlock the Full RISE Experience';
  static const String proMonthlyLabel     = 'Pro Monthly';
  static const String proAnnualLabel      = 'Pro Annual · Save 42%';
  static const String guardianLabel       = 'Guardian · Family Plan';
  static const String foreverLabel        = 'RISE Forever · One-Time';
  static const String restorePurchases    = 'Restore Purchases';
  static const String alreadyPro         = 'You\'re on RISE Pro ✓';
  static const String snoozePackTitle     = 'Need 3 more snoozes?';
  static const String snoozePackBody      =
      'One emergency snooze pack. We won\'t judge.';

  // Geofence travel advisory
  static const String awayFromHomeTitle   = 'You\'re Away Tonight';
  static const String awayFromHomeBody    =
      'Your smart home automations won\'t trigger from here. '
      'Make sure your phone volume is at max and you\'re not relying '
      'on smart lights to wake you up. RISE has your phone covered. 🌍';

  // Buddy
  static const String buddyTitle          = 'Accountability Buddy';
  static const String buddySetupBody      =
      'Choose someone who will be notified if you can\'t wake up. '
      'This is your emergency backup — choose wisely.';
  static const String buddyAlertSent      = 'Your buddy has been notified.';

  // Errors
  static const String permissionRequired  = 'Permission required';
  static const String cameraPermissionMsg =
      'Camera access is needed for identity verification. RISE uses your '
      'heartbeat to confirm it\'s really you dismissing the alarm.';
  static const String notificationPermMsg =
      'Notification permission is required for alarms to fire.';
  static const String locationPermMsg     =
      'Location is used only to detect when you\'re away from home '
      'so RISE can advise you about smart device automations.';
  static const String micPermMsg          =
      'Microphone access (optional) lets RISE detect when you\'ve '
      'fallen asleep based on breathing patterns.';
}
```

---

## FILE 9: lib/core/constants/asset_paths.dart
## PATH: lib/core/constants/asset_paths.dart
## PURPOSE: All asset paths in one place. Prevents typos in asset references.

```dart
class AssetPaths {
  AssetPaths._();

  // ── Images ────────────────────────────────────────────────────────
  static const String logoFull       = 'assets/images/rise_logo_full.png';
  static const String logoMark       = 'assets/images/rise_logomark.png';
  static const String onboarding1    = 'assets/images/onboarding_alarm.png';
  static const String onboarding2    = 'assets/images/onboarding_biometric.png';
  static const String onboarding3    = 'assets/images/onboarding_games.png';
  static const String sleepBg        = 'assets/images/sleep_bg.png';
  static const String starsBg        = 'assets/images/stars_bg.png';
  static const String upgradeBanner  = 'assets/images/upgrade_banner.png';

  // ── Animations (Lottie) ───────────────────────────────────────────
  static const String heartbeatAnim  = 'assets/animations/heartbeat.json';
  static const String successAnim    = 'assets/animations/success_check.json';
  static const String sunriseAnim    = 'assets/animations/sunrise.json';
  static const String sleepingAnim   = 'assets/animations/sleeping.json';
  static const String alarmRingAnim  = 'assets/animations/alarm_ring.json';
  static const String mathAnim       = 'assets/animations/math_game.json';
  static const String traceAnim      = 'assets/animations/trace_game.json';
  static const String memoryAnim     = 'assets/animations/memory_game.json';
  static const String sparkAnim      = 'assets/animations/knowledge_spark.json';
  static const String wordAnim       = 'assets/animations/word_game.json';

  // ── Alarm Sounds ──────────────────────────────────────────────────
  static const String soundDefault   = 'assets/sounds/rise_default.mp3';
  static const String soundGentle    = 'assets/sounds/rise_gentle.mp3';
  static const String soundPulse     = 'assets/sounds/rise_pulse.mp3';
  static const String soundSiren     = 'assets/sounds/rise_siren.mp3';
  static const String soundDawn      = 'assets/sounds/rise_dawn.mp3'; // Premium

  // ── Data ─────────────────────────────────────────────────────────
  static const String questionBank   = 'assets/data/question_bank.json';
  static const String mathProblems   = 'assets/data/math_problems.json';
  static const String wordList       = 'assets/data/word_list.json';
  static const String shapeList      = 'assets/data/shapes.json';
}
```

---

## FILE 10: lib/shared/widgets/rise_button.dart
## PATH: lib/shared/widgets/rise_button.dart
## PURPOSE: RISE's custom button component. Used everywhere.
##          Has primary, secondary, ghost, and danger variants.
##          Includes loading state and haptic feedback built-in.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

enum RiseButtonVariant { primary, secondary, ghost, danger, success }
enum RiseButtonSize { small, medium, large }

class RiseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final RiseButtonVariant variant;
  final RiseButtonSize size;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;

  const RiseButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = RiseButtonVariant.primary,
    this.size = RiseButtonSize.large,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: _getHeight(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final (bgColor, fgColor, borderColor) = _getColors();

    return AnimatedContainer(
      duration: AppConstants.animFast,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (onPressed == null || isLoading)
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
          child: Ink(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.0)
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fgColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (leadingIcon != null) ...[
                          Icon(leadingIcon, color: fgColor, size: _getIconSize()),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: _getTextStyle().copyWith(color: fgColor),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(trailingIcon, color: fgColor, size: _getIconSize()),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _getColors() {
    switch (variant) {
      case RiseButtonVariant.primary:
        return (AppColors.accent, AppColors.textInverse, null);
      case RiseButtonVariant.secondary:
        return (AppColors.backgroundSurface, AppColors.textPrimary, AppColors.borderMedium);
      case RiseButtonVariant.ghost:
        return (Colors.transparent, AppColors.accent, null);
      case RiseButtonVariant.danger:
        return (AppColors.dangerSubtle, AppColors.danger, AppColors.danger);
      case RiseButtonVariant.success:
        return (AppColors.successSubtle, AppColors.success, AppColors.success);
    }
  }

  double _getHeight() {
    switch (size) {
      case RiseButtonSize.small:  return 36;
      case RiseButtonSize.medium: return 46;
      case RiseButtonSize.large:  return AppConstants.buttonHeight;
    }
  }

  double _getIconSize() {
    switch (size) {
      case RiseButtonSize.small:  return 14;
      case RiseButtonSize.medium: return 16;
      case RiseButtonSize.large:  return 18;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case RiseButtonSize.small:  return AppTextStyles.labelSM;
      case RiseButtonSize.medium: return AppTextStyles.labelMD;
      case RiseButtonSize.large:  return AppTextStyles.labelLG;
    }
  }
}
```

---

## FILE 11: lib/shared/widgets/rise_card.dart
## PATH: lib/shared/widgets/rise_card.dart
## PURPOSE: RISE's standard card component. Consistent corners, padding,
##          and background across all screens.

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class RiseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasBorder;
  final double? borderRadius;

  const RiseCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.hasBorder = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? AppConstants.borderRadiusLG;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(br),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(br),
            border: hasBorder
                ? Border.all(color: AppColors.borderSubtle, width: 0.5)
                : null,
          ),
          child: Padding(
            padding: padding ??
                const EdgeInsets.all(AppConstants.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCENT CARD — Used for highlighted/featured cards (e.g., Pro upsell)
// ─────────────────────────────────────────────────────────────────────────────
class RiseAccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color accentColor;

  const RiseAccentCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLG),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
```

---

## FILE 12: lib/shared/widgets/rise_scaffold.dart
## PATH: lib/shared/widgets/rise_scaffold.dart
## PURPOSE: RISE's standard screen wrapper. Handles safe area, consistent
##          padding, and header pattern used across all screens.

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class RiseScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget body;
  final Widget? action;                 // Right side of header
  final Widget? floatingActionButton;
  final bool showBackButton;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final List<Widget>? headerChildren;  // Extra content below title

  const RiseScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.body,
    this.action,
    this.floatingActionButton,
    this.showBackButton = false,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.headerChildren,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.backgroundBase,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) _buildHeader(context),
            if (headerChildren != null) ...headerChildren!,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLG,
        AppConstants.spacingMD,
        AppConstants.spacingMD,
        AppConstants.spacingSM,
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title!, style: AppTextStyles.h1),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMD.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
```

---

## FILE 13: lib/features/home/home_screen.dart
## PATH: lib/features/home/home_screen.dart
## PURPOSE: Main screen placeholder. Shows alarm list, next alarm countdown,
##          and quick stats. Full implementation in Part 3 (Alarm Engine).
##          This placeholder makes the app compile and run in Part 1.

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/rise_scaffold.dart';
import '../../shared/widgets/rise_button.dart';
import '../../shared/widgets/rise_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RiseScaffold(
      title: AppStrings.appName,
      subtitle: 'Good morning',
      action: IconButton(
        icon: const Icon(Icons.add_rounded, color: AppColors.accent, size: 28),
        onPressed: () {
          // Navigate to alarm setup — wired in Part 3
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Next Alarm Display ──────────────────────────────────
            _NextAlarmCard(),
            const SizedBox(height: 16),
            // ── Quick Stats Row ─────────────────────────────────────
            _QuickStatsRow(),
            const SizedBox(height: 16),
            // ── Alarm List placeholder ─────────────────────────────
            _AlarmListPlaceholder(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _NextAlarmCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RiseCard(
      backgroundColor: AppColors.backgroundSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEXT ALARM', style: AppTextStyles.labelSM.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          )),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('06:30', style: AppTextStyles.displayMD.copyWith(
                color: AppColors.accent,
              )),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('AM', style: AppTextStyles.h3.copyWith(
                  color: AppColors.textSecondary,
                )),
              ),
              const Spacer(),
              Switch(
                value: true,
                onChanged: (val) {},
                activeColor: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Tomorrow · Mon, Tue, Wed, Thu, Fri',
            style: AppTextStyles.bodyMD.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successSubtle,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Biometric lock: ON',
              style: AppTextStyles.labelSM.copyWith(color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Sleep', value: '7h 12m',
          icon: Icons.bedtime_rounded, color: AppColors.sleepDeep)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Calories', value: '1,840',
          icon: Icons.local_fire_department_rounded, color: AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Streak', value: '5 days',
          icon: Icons.bolt_rounded, color: AppColors.warning)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RiseCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AlarmListPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ALL ALARMS', style: AppTextStyles.labelSM.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        )),
        const SizedBox(height: 12),
        RiseButton(
          label: '+ Add Your First Alarm',
          variant: RiseButtonVariant.secondary,
          onPressed: () {
            // Wired in Part 3
          },
        ),
      ],
    );
  }
}
```

---

## FILE 14: android/app/src/main/AndroidManifest.xml
## PATH: android/app/src/main/AndroidManifest.xml
## PURPOSE: Android permissions and configuration. EVERY permission RISE
##          needs is declared here. Missing a permission = alarm fails silently.
##          This is complete — do not add or remove without understanding why.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.rise.alarmclock">

    <!-- ── ALARM PERMISSIONS (CRITICAL) ───────────────────────────── -->
    <!-- Required for exact alarm scheduling on Android 12+ -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />

    <!-- Foreground service — prevents OS from killing alarm service -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <!-- Wake lock — keeps CPU alive when alarm fires at 3am -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- Boot receiver — reschedule alarms after device restart -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <!-- Volume control override -->
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

    <!-- ── NOTIFICATION PERMISSIONS ───────────────────────────────── -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- ── BIOMETRIC & CAMERA ──────────────────────────────────────── -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />
    <uses-feature android:name="android.hardware.camera.flash" android:required="false" />

    <!-- ── MICROPHONE (OPTIONAL — SLEEP DETECTION) ────────────────── -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- ── LOCATION (GEOFENCING) ─────────────────────────────────── -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- ── NETWORK ────────────────────────────────────────────────── -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- ── BATTERY OPTIMIZATION ──────────────────────────────────── -->
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

    <application
        android:label="RISE"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:requestLegacyExternalStorage="false"
        android:usesCleartextTraffic="false">

        <!-- Main Activity — fullscreen alarm support -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:showOnLockScreen="true"
            android:turnScreenOn="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Turn screen on when alarm fires — critical -->
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Handle alarm deep links from notification tap -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:scheme="rise" android:host="alarm" />
            </intent-filter>
        </activity>

        <!-- Flutter Background Service for persistent alarm monitoring -->
        <service
            android:name="id.flutter.flutter_background_service.BackgroundService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="false" />

        <!-- Boot receiver — restore alarms after phone restart -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>

        <!-- Alarm notification broadcast receiver -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />

        <!-- AdMob App ID — replace with real ID from AdMob console -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-REPLACE_WITH_YOUR_ADMOB_APP_ID~XXXXXXXXXX"/>

        <!-- Google Maps (for geofencing visualization) -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="REPLACE_WITH_GOOGLE_MAPS_API_KEY"/>
    </application>
</manifest>
```

---

## FILE 15: ios/Runner/Info.plist
## PATH: ios/Runner/Info.plist
## PURPOSE: iOS permissions, background modes, and capabilities.
##          iOS is strict — every background capability must be declared
##          or Apple will reject the app during review.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Identity -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>RISE</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>rise_alarm</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>

    <!-- Flutter -->
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>

    <!-- ── CRITICAL ALERTS (Alarms bypass silent mode) ───────────── -->
    <!-- Users must grant Critical Alerts permission explicitly.       -->
    <!-- Without this, alarm is silenced in Do Not Disturb mode.       -->
    <!-- NOTE: Apple requires special entitlement for Critical Alerts  -->
    <!-- You must request this in App Store Connect before submitting  -->
    <key>NSUserNotificationUsageDescription</key>
    <string>RISE uses notifications to fire your alarms reliably, even when your phone is on silent. Your alarm will not work without notification permission.</string>

    <!-- ── CAMERA ─────────────────────────────────────────────────── -->
    <key>NSCameraUsageDescription</key>
    <string>RISE uses your camera to read your heartbeat through the flash — this creates your unique biometric profile so no one else can dismiss your alarm. No video is recorded or stored.</string>

    <!-- ── MICROPHONE ─────────────────────────────────────────────── -->
    <key>NSMicrophoneUsageDescription</key>
    <string>RISE can optionally use your microphone to detect when you fall asleep based on breathing patterns. This is completely optional and no audio is ever recorded or transmitted.</string>

    <!-- ── LOCATION ───────────────────────────────────────────────── -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>RISE uses your location to detect when you are away from home so it can remind you to adjust your smart home devices before you sleep.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>RISE uses background location to monitor when you return home and automatically restore your smart home alarm automations.</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>RISE uses background location to detect when you travel away from home and advise you about your smart home alarm setup.</string>

    <!-- ── FACE ID / BIOMETRICS ───────────────────────────────────── -->
    <key>NSFaceIDUsageDescription</key>
    <string>RISE uses Face ID as a fallback identity verification layer to confirm it is really you dismissing the alarm.</string>

    <!-- ── BACKGROUND MODES ──────────────────────────────────────── -->
    <!-- These are required for the alarm to fire when app is in background -->
    <key>UIBackgroundModes</key>
    <array>
        <!-- Audio: plays alarm sound when app is backgrounded -->
        <string>audio</string>
        <!-- Location: geofencing continues in background -->
        <string>location</string>
        <!-- Background fetch: checks sleep state, syncs data -->
        <string>fetch</string>
        <!-- Remote notifications: push-based buddy alerts -->
        <string>remote-notification</string>
        <!-- Processing: background task for sleep analysis -->
        <string>processing</string>
    </array>

    <!-- ── MINIMUM iOS VERSION ───────────────────────────────────── -->
    <key>MinimumOSVersion</key>
    <string>14.0</string>

    <!-- ── APP TRANSPORT SECURITY ─────────────────────────────────── -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <!-- All API calls use HTTPS — no exceptions -->
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>

    <!-- ── HEALTH KIT (Future: Apple Watch integration) ────────────── -->
    <!-- Declared now so it doesn't require app update to enable later -->
    <key>NSHealthShareUsageDescription</key>
    <string>RISE can optionally read your sleep data from Apple Health to improve alarm timing recommendations.</string>

    <!-- AdMob -->
    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-REPLACE_WITH_YOUR_ADMOB_APP_ID~XXXXXXXXXX</string>

    <key>GADIsAdManagerApp</key>
    <true/>
</dict>
</plist>
```

---

## AGENT: AFTER CREATING ALL FILES, DO THE FOLLOWING:

### Step 1 — Create required asset directories:
```bash
mkdir -p assets/images
mkdir -p assets/animations
mkdir -p assets/sounds
mkdir -p assets/data
mkdir -p assets/fonts
```

### Step 2 — Create placeholder asset files so Flutter doesn't fail:
```bash
# Create minimal placeholder files so pubspec.yaml asset declarations don't fail
touch assets/images/.gitkeep
touch assets/animations/.gitkeep
touch assets/sounds/.gitkeep
touch assets/fonts/.gitkeep

# Create an empty question bank JSON (filled in Part 6)
echo '{"questions": []}' > assets/data/question_bank.json
echo '{"problems": []}' > assets/data/math_problems.json
echo '{"words": []}' > assets/data/word_list.json
echo '{"shapes": []}' > assets/data/shapes.json
```

### Step 3 — Create firebase_options.dart placeholder:
```bash
# Create a placeholder so app compiles — real file generated by FlutterFire CLI
# The developer will run: flutterfire configure
# to generate the real firebase_options.dart
```

Create this file at `lib/firebase_options.dart`:
```dart
// PLACEHOLDER — Replace by running: flutterfire configure
// See: https://firebase.google.com/docs/flutter/setup
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('RISE supports Android and iOS only');
    }
  }

  // REPLACE THESE VALUES by running: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FIREBASE_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_FIREBASE_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'rise-alarm-REPLACE',
    storageBucket: 'rise-alarm-REPLACE.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FIREBASE_IOS_API_KEY',
    appId: 'REPLACE_WITH_FIREBASE_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'rise-alarm-REPLACE',
    storageBucket: 'rise-alarm-REPLACE.appspot.com',
    iosClientId: 'REPLACE_WITH_IOS_CLIENT_ID',
    iosBundleId: 'com.rise.alarmclock',
  );
}
```

### Step 4 — Run:
```bash
flutter pub get
flutter analyze
```

### Expected result:
- `flutter pub get` resolves all dependencies without errors
- `flutter analyze` shows 0 errors (may show info-level hints — ignore)
- App compiles and shows the RISE home screen with the alarm card and bottom navigation

---

## WHAT PART 2 WILL COVER:
Part 2 builds ALL DATA MODELS: AlarmModel, SleepSession, BiometricProfile,
CalorieLog, FoodEntry, UserProfile, SubscriptionStatus — with full Hive
serialization, Firestore converters, and Riverpod providers. Part 2 is the
data backbone every other part depends on.

---
## END OF PART 1 BLUEPRINT
## Total files created: 15 + 4 asset directories + placeholder assets
## Foundation: COMPLETE ✓
```
