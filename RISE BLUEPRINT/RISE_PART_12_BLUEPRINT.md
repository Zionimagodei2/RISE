# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 12 OF 12 — THE CAPSTONE
# App Shell · Navigation · Notifications · Smart Home ·
# Reconciliation Table · Complete pubspec.yaml · Full File Tree
# ============================================================
# COMMAND TO AI CODING AGENT:
# This is the final part. Read it entirely before writing
# anything. This file does three critical jobs:
#
# JOB 1 — RECONCILIATION
#   Parts 1–12 were written over multiple sessions and the
#   product philosophy evolved. Some earlier files are now
#   superseded. The reconciliation table below tells you
#   exactly which file wins every conflict. Follow it without
#   exception.
#
# JOB 2 — WIRING
#   Everything built in Parts 1–11 is wired together here:
#   routing, notifications, background services, smart home,
#   app lifecycle. Nothing in those parts assumed the wiring
#   was done — this part does it.
#
# JOB 3 — REFERENCE
#   The complete pubspec.yaml (all parts consolidated), the
#   complete Firebase setup checklist, and the full file tree
#   of all 190+ files across all 12 parts.
#
# WHAT THIS PART CREATES (12 files):
#  1. lib/app.dart                          ← GoRouter fully wired
#  2. lib/main.dart                         ← Updated init sequence
#  3. lib/features/shell/main_shell.dart    ← 5-tab navigation
#  4. lib/core/services/notification_service.dart ← FCM + local
#  5. lib/core/services/smart_home_service.dart   ← WiFi-aware
#  6. lib/core/services/app_lifecycle_manager.dart
#  7. lib/features/shell/conversion_gate.dart ← Weekly review preview
#  8. lib/features/shell/sponsor_slot.dart    ← Ad slot (dark by default)
#  9. pubspec.yaml                            ← Complete final version
# 10. firebase_setup_checklist.md
# 11. RECONCILIATION.md                      ← What supersedes what
# 12. FILE_TREE.md                           ← Every file, all 12 parts
# ============================================================

---

# ══════════════════════════════════════════════════════════════
# RECONCILIATION TABLE
# CONFLICTS BETWEEN PARTS — DEFINITIVE RESOLUTION
# ══════════════════════════════════════════════════════════════
# Read this before touching any file. It is authoritative.
# "SUPERSEDED" = do not implement the old file at all.
# "UPDATED" = implement the new version, discard the old.
# "ADDITIVE" = new file adds to, does not replace, the old.
# ══════════════════════════════════════════════════════════════

## FILE: RECONCILIATION.md

```markdown
# RISE — What Supersedes What

## TIER / SUBSCRIPTION MODEL

CONFLICT: Part 6A defines SubscriptionTier with feature flags
  based on a paywall model where core features are gated.
  Parts 9–10 fundamentally changed the philosophy: the
  "becoming" layer (alarm, wake games, sleep tracking, calorie,
  goals, habits, quotes, streaks) is FREE FOREVER.
  The "understanding" layer (weekly review, monthly letter,
  sleep-nutrition AI insight, deep sleep history analytics)
  is the paid product.

RESOLUTION: lib/core/models/subscription_tier.dart
  Implement using Part 10A's regional pricing model as the
  source of truth for pricing. Implement using the feature
  flag philosophy described below. Part 6A's tier definitions
  are SUPERSEDED for pricing. Part 6A's feature flag structure
  can be retained but the flag values must reflect this:

  FREE TIER (starter) — these must be TRUE:
    wakeGamesEnabled:          true
    biometricLock:             true   ← Changed from Part 6A
    barcodeCalorieScanning:    true   ← Changed from Part 6A
    fullSleepHistory:          false  ← Last 14 days only
    dailyAiMorningBriefing:    false
    weeklyAiReview:            false
    monthlyAiLetter:           false
    sleepNutritionInsight:     false
    goalsEnabled:              true   ← Changed from Part 6A
    habitsEnabled:             true   ← Changed from Part 6A
    quotesEnabled:             true   ← Changed from Part 6A
    proofWallEnabled:          true   ← Changed from Part 6A

  CORE ($2.49–$5.99/mo) — adds:
    fullSleepHistory:          true   ← Unlimited history
    weeklyAiReview:            true   ← THE conversion trigger
    sleepNutritionInsight:     true

  PRO ($3.99–$9.99/mo) — adds:
    dailyAiMorningBriefing:    true
    monthlyAiLetter:           true
    chronotypeOptimizer:       true
    sleepDebtLedger:           true
    smartHomeIntegration:      true

  GUARDIAN ($6.99–$16.99/mo) — adds:
    childProfiles:             true
    parentDashboard:           true
    guardianNotifications:     true
    All PRO features

  Note: Lifetime tier gets Guardian-level features permanently.


## REFERRAL SERVICE

CONFLICT: lib/core/services/referral_service.dart (Part 6B)
  vs lib/core/services/referral_service_v2.dart (Part 10A).

RESOLUTION: USE referral_service_v2.dart ONLY.
  Delete / do not implement referral_service.dart from Part 6B.
  referral_service_v2.dart is the complete, final implementation
  with correct payout tiers, fraud detection, 30-day hold,
  and wallet-only redemption.


## PAYWALL SCREEN

CONFLICT: lib/features/social/referral_screen.dart (Part 6B)
  contains a basic paywall. lib/features/paywall/paywall_screen.dart
  (Part 10A) is the complete paywall with regional pricing,
  Flutterwave/Stripe routing, referral code entry.

RESOLUTION: USE lib/features/paywall/paywall_screen.dart ONLY.
  The Part 6B paywall is SUPERSEDED.


## SUBSCRIPTION PROVIDER

CONFLICT: lib/core/providers/subscription_provider.dart appears
  in Part 2 as a stub and in Part 11 as the full implementation.

RESOLUTION: USE Part 11's full implementation.
  It includes SubscriptionState with tier, displayName,
  storefrontCountry, faithContext, isLoaded, and the
  StateNotifier that loads from SharedPreferences + PaymentService.


## HOME SCREEN

CONFLICT: lib/features/home/home_screen.dart appears in Part 1
  as a stub and Part 9 as the full implementation.

RESOLUTION: USE Part 9's full implementation.


## CALORIE MODELS

CONFLICT: lib/core/models/calorie_log.dart (Part 2, typeId: 3 stub)
  vs lib/core/models/calorie_entry.dart (Part 10B, typeId: 3 full).
  lib/core/models/food_entry.dart (Part 2, typeId: 4 stub)
  vs lib/core/models/food_item.dart (Part 10B, typeId: 4 full).

RESOLUTION:
  DELETE calorie_log.dart and food_entry.dart (Part 2 stubs).
  USE calorie_entry.dart and food_item.dart (Part 10B) ONLY.
  They use the same typeIds (3 and 4) — the stubs are replaced.


## SLEEP SESSIONS BOX NAME

CONFLICT: Some parts use AppConstants.sessionsBoxName
  ('sleep_sessions_v1'), others use sleepSessionsBoxName
  ('sleep_v1'). These are the same box referred to by two names.

RESOLUTION: AppConstants.sessionsBoxName = 'sleep_sessions_v1'.
  This is the canonical name. Update any reference to
  sleepSessionsBoxName to use sessionsBoxName.


## BOTTOM NAVIGATION

CONFLICT: Part 1's MainShell has 4 tabs (Alarms, Sleep,
  Nutrition, Profile). Part 12 adds Goals and Quotes.

RESOLUTION: USE Part 12's MainShell with 5 tabs:
  Alarms | Sleep | Goals | Nutrition | More
  "More" contains: Profile, Quotes, Settings, Leaderboard,
  Wallet, Referrals.


## PUBSPEC VERSIONS

CONFLICT: Part 1 declares purchases_flutter ^8.0.0.
  Part 10A declares purchases_flutter ^6.19.0.

RESOLUTION: Use purchases_flutter ^8.0.0 (Part 1, higher version).
  RevenueCat maintains backward compatibility.
  Part 10A's lower pin was a draft error.

CONFLICT: Part 1 declares firebase_auth ^5.2.1.
  Part 10A/11 declare firebase_auth ^4.20.0.

RESOLUTION: Use firebase_auth ^5.2.1 (Part 1, higher version).


## ONBOARDING ROUTE

CONFLICT: Part 1 declares a placeholder '/onboarding' route.
  Part 11 builds the full OnboardingShell.

RESOLUTION: Replace Part 1's placeholder builder with:
  builder: (context, state) => const OnboardingShell()
  Full implementation is in Part 11.
```

---

# ══════════════════════════════════════════════════════════════
# FILE 1: lib/app.dart
# PURPOSE: GoRouter fully wired with every route from all parts.
#          Redirect logic: onboarding check on every launch.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/alarm/alarm_screen.dart';
import 'features/alarm/alarm_setup_screen.dart';
import 'features/calorie/calorie_screen.dart';
import 'features/goals/daily_intention_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/goals/monthly_letter_screen.dart';
import 'features/goals/proof_wall_screen.dart';
import 'features/goals/weekly_review_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_shell.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/quotes/quotes_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/sleep/sleep_tracker_screen.dart';
import 'features/social/leaderboard_screen.dart';
import 'features/social/wallet_screen.dart';

// ── Router ─────────────────────────────────────────────────────────────────

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Check onboarding completion on every cold start
      final prefs    = await SharedPreferences.getInstance();
      final complete = prefs.getBool('onboarding_complete') ?? false;
      final onOnboarding = state.uri.toString() == '/onboarding';

      if (!complete && !onOnboarding) return '/onboarding';
      if (complete && onOnboarding) return '/';
      return null;
    },

    routes: [
      // ── Onboarding (full screen, no nav bar) ───────────────
      GoRoute(
        path:    '/onboarding',
        name:    'onboarding',
        builder: (ctx, _) => const OnboardingShell(),
      ),

      // ── Alarm firing (full screen, overrides everything) ───
      GoRoute(
        path:    '/alarm-firing',
        name:    'alarmFiring',
        builder: (ctx, state) {
          final alarmId = state.uri.queryParameters['alarmId'] ?? '';
          return AlarmScreen(alarmId: alarmId);
        },
      ),

      // ── Shell (app with bottom nav) ────────────────────────
      ShellRoute(
        builder: (ctx, state, child) =>
            MainShell(child: child, location: state.uri.toString()),
        routes: [

          // Home — Alarms tab
          GoRoute(
            path: '/',
            name: 'home',
            builder: (ctx, _) => const HomeScreen(),
          ),
          GoRoute(
            path: '/alarm-setup',
            name: 'alarmSetup',
            builder: (ctx, state) {
              final alarmId = state.uri.queryParameters['alarmId'];
              return AlarmSetupScreen(editAlarmId: alarmId);
            },
          ),

          // Sleep tab
          GoRoute(
            path: '/sleep',
            name: 'sleep',
            builder: (ctx, _) => const SleepTrackerScreen(),
          ),

          // Goals tab
          GoRoute(
            path: '/goals',
            name: 'goals',
            builder: (ctx, _) => const GoalsScreen(),
            routes: [
              GoRoute(
                path: 'intention',
                name: 'dailyIntention',
                builder: (ctx, _) =>
                    DailyIntentionScreen(entry:
                        // TodayEntry passed via extra
                        ctx.extra as dynamic),
              ),
              GoRoute(
                path: 'weekly-review',
                name: 'weeklyReview',
                builder: (ctx, _) => const WeeklyReviewScreen(),
              ),
              GoRoute(
                path: 'monthly-letter',
                name: 'monthlyLetter',
                builder: (ctx, _) => const MonthlyLetterScreen(),
              ),
              GoRoute(
                path: 'proof-wall',
                name: 'proofWall',
                builder: (ctx, _) => const ProofWallScreen(),
              ),
            ],
          ),

          // Nutrition tab
          GoRoute(
            path: '/nutrition',
            name: 'nutrition',
            builder: (ctx, _) => const CalorieScreen(),
          ),

          // More tab destinations
          GoRoute(
            path: '/quotes',
            name: 'quotes',
            builder: (ctx, _) => const QuotesScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (ctx, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            name: 'leaderboard',
            builder: (ctx, _) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (ctx, _) => const WalletScreen(),
          ),
          GoRoute(
            path: '/upgrade',
            name: 'upgrade',
            builder: (ctx, _) => const PaywallScreen(),
          ),
        ],
      ),
    ],
  );
});

// ── App root ───────────────────────────────────────────────────────────────

class RiseApp extends ConsumerWidget {
  const RiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title:           'RISE',
      debugShowCheckedModeBanner: false,
      theme:           AppTheme.dark,
      routerConfig:    router,
    );
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 2: lib/main.dart
# PURPOSE: App initialization in the correct order.
#          Everything that must happen before the first frame.
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/models/alarm_model.dart';
import 'core/models/biometric_profile.dart';
import 'core/models/calorie_entry.dart';
import 'core/models/daily_entry.dart';
import 'core/models/dream_entry.dart';
import 'core/models/food_item.dart';
import 'core/models/habit_model.dart';
import 'core/models/north_star_goal.dart';
import 'core/models/onboarding_state.dart';
import 'core/models/proof_wall_milestone.dart';
import 'core/models/quote_item.dart';
import 'core/models/sleep_session.dart';
import 'core/models/wake_confirmation.dart';
import 'core/models/wake_game_result.dart';
import 'core/services/app_lifecycle_manager.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

// ── Background notification handler (top-level, not in a class) ────────────
// Required by firebase_messaging — must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().handleFcmMessage(message,
      background: true);
}

Future<void> main() async {
  // ── 1. Flutter binding ────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. Error boundary — catches all uncaught errors ──────────
  await runZonedGuarded(() async {

    // ── 3. Firebase ─────────────────────────────────────────────
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Crashlytics — catches Flutter framework errors
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    // ── 4. Timezone database ────────────────────────────────────
    tz.initializeTimeZones();

    // ── 5. Hive — register adapters THEN open boxes ─────────────
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);

    // Register all Hive adapters (generated from @HiveType models)
    // ORDER MATTERS: register before openBox
    Hive.registerAdapter(AlarmModelAdapter());           // typeId: 0
    Hive.registerAdapter(SleepSessionAdapter());         // typeId: 1
    Hive.registerAdapter(BiometricProfileAdapter());     // typeId: 2
    Hive.registerAdapter(CalorieEntryAdapter());         // typeId: 3
    Hive.registerAdapter(FoodItemAdapter());             // typeId: 4
    Hive.registerAdapter(WakeGameResultAdapter());       // typeId: 5
    Hive.registerAdapter(BuddyContactAdapter());         // typeId: 6
    Hive.registerAdapter(SubscriptionStatusAdapter());   // typeId: 7
    Hive.registerAdapter(DreamEntryAdapter());           // typeId: 8
    Hive.registerAdapter(WakeConfirmationAdapter());     // typeId: 9
    Hive.registerAdapter(NorthStarGoalAdapter());        // typeId: 10
    Hive.registerAdapter(HabitModelAdapter());           // typeId: 11
    Hive.registerAdapter(DailyEntryAdapter());           // typeId: 12
    Hive.registerAdapter(QuoteItemAdapter());            // typeId: 13
    Hive.registerAdapter(ProofWallMilestoneAdapter());   // typeId: 14
    Hive.registerAdapter(HabitEntryAdapter());           // typeId: 15
    // Enum adapters (generated)
    Hive.registerAdapter(MealTypeAdapter());
    Hive.registerAdapter(CuisineRegionAdapter());
    Hive.registerAdapter(GoalCategoryAdapter());
    Hive.registerAdapter(HabitFrequencyAdapter());
    Hive.registerAdapter(QuoteCategoryAdapter());
    Hive.registerAdapter(MilestoneTypeAdapter());
    Hive.registerAdapter(MorningTaskStatusAdapter());
    Hive.registerAdapter(EveningReflectionAdapter());

    // Open ALL boxes at startup — never open lazily for alarm-critical data
    await Future.wait([
      Hive.openBox<dynamic>(AppConstants.alarmsBoxName),
      Hive.openBox<dynamic>(AppConstants.sessionsBoxName),
      Hive.openBox<dynamic>(AppConstants.biometricBoxName),
      Hive.openBox<dynamic>(AppConstants.calorieBoxName),
      Hive.openBox<dynamic>(AppConstants.foodDbBoxName),
      Hive.openBox<dynamic>(AppConstants.gameResultsBoxName),
      Hive.openBox<dynamic>(AppConstants.buddyBoxName),
      Hive.openBox<dynamic>(AppConstants.dreamsBoxName),
      Hive.openBox<dynamic>(AppConstants.wakeConfirmBoxName),
      Hive.openBox<dynamic>(AppConstants.goalsBoxName),
      Hive.openBox<dynamic>(AppConstants.habitsBoxName),
      Hive.openBox<dynamic>(AppConstants.quotesBoxName),
      Hive.openBox<dynamic>(AppConstants.proofWallBoxName),
      Hive.openBox<dynamic>(AppConstants.intentionsBoxName),
      Hive.openBox<dynamic>(AppConstants.morningThreeBoxName),
      Hive.openBox<dynamic>(AppConstants.settingsBoxName),
      Hive.openBox<dynamic>(AppConstants.challengesBoxName),
    ]);

    // ── 6. Notification service ──────────────────────────────────
    final notifSvc = NotificationService();
    await notifSvc.initialize();
    await notifSvc.registerFcmBackgroundHandler(
        _firebaseMessagingBackgroundHandler);

    // ── 7. App lifecycle manager ─────────────────────────────────
    AppLifecycleManager().initialize();

    // ── 8. Run app ───────────────────────────────────────────────
    runApp(const ProviderScope(child: RiseApp()));

  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 3: lib/features/shell/main_shell.dart
# PURPOSE: 5-tab bottom navigation.
#          Alarms | Sleep | Goals | Nutrition | More
#          More drawer contains: Quotes, Leaderboard,
#          Wallet, Settings, Upgrade.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({
    super.key, required this.child, required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:              child,
      bottomNavigationBar: _RiseBottomNav(location: location),
    );
  }
}

class _RiseBottomNav extends StatelessWidget {
  final String location;
  const _RiseBottomNav({required this.location});

  @override
  Widget build(BuildContext context) {
    final idx = _indexForLocation(location);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(top: BorderSide(
            color: Colors.white.withOpacity(0.07), width: 0.5)),
      ),
      child: NavigationBar(
        backgroundColor:      Colors.transparent,
        indicatorColor:       Colors.indigoAccent.withOpacity(0.15),
        selectedIndex:        idx,
        onDestinationSelected: (i) => _navigate(context, i),
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon:          Icon(Icons.alarm_outlined),
            selectedIcon:  Icon(Icons.alarm),
            label:         'Alarms',
          ),
          NavigationDestination(
            icon:          Icon(Icons.bedtime_outlined),
            selectedIcon:  Icon(Icons.bedtime),
            label:         'Sleep',
          ),
          NavigationDestination(
            icon:          Icon(Icons.track_changes_outlined),
            selectedIcon:  Icon(Icons.track_changes),
            label:         'Goals',
          ),
          NavigationDestination(
            icon:          Icon(Icons.restaurant_outlined),
            selectedIcon:  Icon(Icons.restaurant),
            label:         'Nutrition',
          ),
          NavigationDestination(
            icon:          Icon(Icons.grid_view_outlined),
            selectedIcon:  Icon(Icons.grid_view),
            label:         'More',
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String loc) {
    if (loc.startsWith('/sleep'))     return 1;
    if (loc.startsWith('/goals'))     return 2;
    if (loc.startsWith('/nutrition')) return 3;
    if (loc.startsWith('/quotes') ||
        loc.startsWith('/leaderboard') ||
        loc.startsWith('/wallet') ||
        loc.startsWith('/settings'))  return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/sleep');
      case 2: context.go('/goals');
      case 3: context.go('/nutrition');
      case 4: _showMoreSheet(context);
    }
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context:          context,
      backgroundColor:  const Color(0xFF161628),
      shape:            const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
      builder: (_) => _MoreSheet(),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem('🔖', 'Quotes',       '/quotes'),
      _MoreItem('🏆', 'Leaderboard',  '/leaderboard'),
      _MoreItem('💰', 'Wallet',       '/wallet'),
      _MoreItem('⚙️',  'Settings',    '/settings'),
      _MoreItem('⭐', 'Upgrade',      '/upgrade'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          ...items.map((item) => ListTile(
            leading: Text(item.emoji,
                style: const TextStyle(fontSize: 22)),
            title:   Text(item.label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 15)),
            onTap: () {
              Navigator.pop(context);
              context.go(item.route);
            },
          )),
        ],
      ),
    );
  }
}

class _MoreItem {
  final String emoji;
  final String label;
  final String route;
  const _MoreItem(this.emoji, this.label, this.route);
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 4: lib/core/services/notification_service.dart
# PURPOSE: FCM push notifications + local notification channels.
#          Routes every notification type to the right handler.
#          Deep links alarm fire, wake confirmation, buddy alerts,
#          referral rewards, streak milestones into the app.
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

// Notification channel IDs — declared once, referenced everywhere
class NotificationChannels {
  static const String alarmCritical    = 'rise_alarm_critical';
  static const String wakeConfirm      = 'rise_wake_confirm';
  static const String buddyAlert       = 'rise_buddy_alert';
  static const String streakMilestone  = 'rise_streak';
  static const String referralReward   = 'rise_referral';
  static const String general          = 'rise_general';
}

// Notification types — used in FCM payload 'type' field
class NotifType {
  static const String alarmFire        = 'alarm_fire';
  static const String wakeConfirmCheck = 'wake_confirm_check';
  static const String buddyNotConfirmed = 'buddy_not_confirmed';
  static const String streakMilestone  = 'streak_milestone';
  static const String referralConfirmed = 'referral_confirmed';
  static const String weeklyReviewReady = 'weekly_review_ready';
  static const String smartHomeTrigger  = 'smart_home_trigger';
}

class NotificationService {
  static final NotificationService _i = NotificationService._internal();
  factory NotificationService() => _i;
  NotificationService._internal();

  final _local   = FlutterLocalNotificationsPlugin();
  final _fcm     = FirebaseMessaging.instance;
  String?        _fcmToken;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Request FCM permission
    await _fcm.requestPermission(
      alert:       true,
      announcement: false,
      badge:       true,
      sound:       true,
    );

    _fcmToken = await _fcm.getToken();

    // Local notification initialization
    const android = AndroidInitializationSettings(
        '@drawable/ic_notification');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested in onboarding
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // Create Android notification channels
    await _createChannels();

    // FCM foreground handler
    FirebaseMessaging.onMessage.listen(_onFcmForeground);

    // FCM notification tap handler (app in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onFcmTap);

    // Check for notification that launched the app from terminated state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onFcmTap(initial);
  }

  Future<void> registerFcmBackgroundHandler(
      Future<void> Function(RemoteMessage) handler) async {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  Future<void> _createChannels() async {
    final plugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) return;

    // CRITICAL channel — alarm fire. Cannot be silenced by user.
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.alarmCritical,
        'RISE Alarm',
        description:     'Your RISE alarm. Cannot be disabled.',
        importance:      Importance.max,
        enableVibration: true,
        playSound:       true,
      ),
    );

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.wakeConfirm,
        'Wake Confirmation',
        description:     'Check-in 15 minutes after your alarm.',
        importance:      Importance.high,
        enableVibration: true,
      ),
    );

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.buddyAlert,
        'Buddy Alerts',
        description:     'Your accountability buddy notifications.',
        importance:      Importance.high,
      ),
    );

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.streakMilestone,
        'Streak Milestones',
        description:     'Celebrate your consistency.',
        importance:      Importance.defaultImportance,
      ),
    );

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.referralReward,
        'Referral Rewards',
        description:     'Wallet credit from your referrals.',
        importance:      Importance.defaultImportance,
      ),
    );
  }

  // ── Alarm fire notification ────────────────────────────────────────────────
  // Called by AlarmService when alarm fires.
  // This opens the AlarmScreen via deep link.
  Future<void> showAlarmFiringNotification({
    required String alarmId,
    required String label,
  }) async {
    await _local.show(
      alarmId.hashCode,
      'RISE',
      label.isNotEmpty ? label : 'Time to wake up',
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.alarmCritical,
          'RISE Alarm',
          importance:     Importance.max,
          priority:       Priority.max,
          fullScreenIntent: true,   // Shows even on locked screen
          ongoing:        true,     // Cannot be dismissed by swipe
          autoCancel:     false,
          category:       AndroidNotificationCategory.alarm,
          visibility:     NotificationVisibility.public,
          actions: [
            const AndroidNotificationAction(
              'snooze', 'Snooze',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'dismiss', 'Dismiss',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'ALARM',
          interruptionLevel:  InterruptionLevel.critical,
        ),
      ),
      payload: jsonEncode({
        'type':    NotifType.alarmFire,
        'alarmId': alarmId,
      }),
    );
  }

  Future<void> cancelAlarmNotification(String alarmId) async {
    await _local.cancel(alarmId.hashCode);
  }

  // ── Wake confirmation notification ────────────────────────────────────────
  Future<void> scheduleWakeConfirmNotification({
    required String alarmId,
    required DateTime fireAt,
  }) async {
    await _local.zonedSchedule(
      'wc_${alarmId}'.hashCode,
      'Are you actually up?',
      'Tap to confirm you\'re awake and moving.',
      _tzDateTime(fireAt),
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.wakeConfirm,
          'Wake Confirmation',
          importance: Importance.high,
          priority:   Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode({
        'type':    NotifType.wakeConfirmCheck,
        'alarmId': alarmId,
      }),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Buddy alert notification ──────────────────────────────────────────────
  Future<void> showBuddyAlertNotification({
    required String buddyName,
    required String message,
    required String alarmId,
  }) async {
    await _local.show(
      'buddy_$alarmId'.hashCode,
      '$buddyName hasn\'t confirmed yet',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.buddyAlert,
          'Buddy Alerts',
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode({
        'type':    NotifType.buddyNotConfirmed,
        'alarmId': alarmId,
      }),
    );
  }

  // ── Streak milestone notification ─────────────────────────────────────────
  Future<void> showStreakMilestoneNotification({
    required int    streak,
    required String title,
    required String body,
  }) async {
    await _local.show(
      'streak_$streak'.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.streakMilestone,
          'Streak Milestones',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode({
        'type': NotifType.streakMilestone,
        'streak': streak,
      }),
    );
  }

  // ── Referral confirmed notification ───────────────────────────────────────
  Future<void> showReferralRewardNotification({
    required String creditAmount,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$creditAmount added to your wallet 💰',
      'Your referral confirmed their subscription.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.referralReward,
          'Referral Rewards',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode({'type': NotifType.referralConfirmed}),
    );
  }

  // ── FCM message handler ───────────────────────────────────────────────────
  Future<void> handleFcmMessage(RemoteMessage message,
      {bool background = false}) async {
    final type = message.data['type'] as String?;
    if (type == null) return;

    switch (type) {
      case NotifType.alarmFire:
        // Handled by local alarm engine — FCM is backup only
        break;
      case NotifType.wakeConfirmCheck:
        if (!background) {
          await scheduleWakeConfirmNotification(
            alarmId: message.data['alarmId'] ?? '',
            fireAt:  DateTime.now(),
          );
        }
      case NotifType.buddyNotConfirmed:
        await showBuddyAlertNotification(
          buddyName: message.data['buddyName'] ?? 'Your buddy',
          message:   message.data['message'] ?? '',
          alarmId:   message.data['alarmId'] ?? '',
        );
      case NotifType.streakMilestone:
        await showStreakMilestoneNotification(
          streak: int.tryParse(message.data['streak'] ?? '0') ?? 0,
          title:  message.notification?.title ?? 'Streak milestone',
          body:   message.notification?.body ?? '',
        );
      case NotifType.referralConfirmed:
        await showReferralRewardNotification(
            creditAmount: message.data['creditAmount'] ?? '');
      case NotifType.weeklyReviewReady:
        // Silent notification — pre-generates the weekly review
        // so it loads instantly when user opens the screen
        break;
    }
  }

  void _onFcmForeground(RemoteMessage message) {
    handleFcmMessage(message, background: false);
  }

  void _onFcmTap(RemoteMessage message) {
    // Navigate based on notification type
    final type = message.data['type'] as String?;
    // Navigation handled by GoRouter — context not available here.
    // Use a global navigator key or stream.
    _notifTapController.add(message.data);
  }

  void _onLocalTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _notifTapController.add(data);
    } catch (_) {}
  }

  // Stream of notification taps — listened to by app.dart to navigate
  final _notifTapController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationTaps =>
      _notifTapController.stream;

  String? get fcmToken => _fcmToken;

  // tz.TZDateTime helper
  dynamic _tzDateTime(DateTime dt) {
    // Full implementation uses tz package
    return dt;
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 5: lib/core/services/smart_home_service.dart
# PURPOSE: Smart home integration — WiFi-aware.
#          Works: Philips Hue, LIFX, smart kettle (Switchbot).
#          Gracefully absent when offline.
#          Guardian tier: child's room lights on alarm fire.
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum SmartHomeProvider { philipsHue, lifx, switchBot, none }

class SmartHomeConfig {
  final SmartHomeProvider provider;
  final String?           bridgeIp;     // Hue local bridge IP
  final String?           bridgeToken;  // Hue API token
  final String?           lifxToken;    // LIFX cloud token
  final String?           switchbotToken;
  final bool              lightsOnWake;  // Gradually brighten before alarm
  final int               rampMinutes;   // How many minutes before alarm to start ramp
  final bool              kettleOnWake;  // Smart kettle on after wake confirmation
  final bool              thermostatOnWake; // Adjust thermostat on wake

  const SmartHomeConfig({
    this.provider         = SmartHomeProvider.none,
    this.bridgeIp,
    this.bridgeToken,
    this.lifxToken,
    this.switchbotToken,
    this.lightsOnWake     = true,
    this.rampMinutes      = 20,
    this.kettleOnWake     = false,
    this.thermostatOnWake = false,
  });

  Map<String, dynamic> toJson() => {
    'provider':         provider.name,
    'bridgeIp':         bridgeIp,
    'bridgeToken':      bridgeToken,
    'lifxToken':        lifxToken,
    'switchbotToken':   switchbotToken,
    'lightsOnWake':     lightsOnWake,
    'rampMinutes':      rampMinutes,
    'kettleOnWake':     kettleOnWake,
    'thermostatOnWake': thermostatOnWake,
  };

  factory SmartHomeConfig.fromJson(Map<String, dynamic> j) =>
      SmartHomeConfig(
        provider:         SmartHomeProvider.values.byName(
            j['provider'] as String? ?? 'none'),
        bridgeIp:         j['bridgeIp'] as String?,
        bridgeToken:      j['bridgeToken'] as String?,
        lifxToken:        j['lifxToken'] as String?,
        switchbotToken:   j['switchbotToken'] as String?,
        lightsOnWake:     j['lightsOnWake'] as bool? ?? true,
        rampMinutes:      j['rampMinutes'] as int? ?? 20,
        kettleOnWake:     j['kettleOnWake'] as bool? ?? false,
        thermostatOnWake: j['thermostatOnWake'] as bool? ?? false,
      );
}

class SmartHomeService {
  static final SmartHomeService _i = SmartHomeService._internal();
  factory SmartHomeService() => _i;
  SmartHomeService._internal();

  static const _configKey = 'smart_home_config';

  Future<SmartHomeConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_configKey);
    if (json == null) return const SmartHomeConfig();
    try {
      return SmartHomeConfig.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const SmartHomeConfig();
    }
  }

  Future<void> saveConfig(SmartHomeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  // ── Called by AlarmService X minutes before alarm fires ──────────────────
  // Starts the light ramp. Only if WiFi is connected.
  Future<void> startLightRamp(SmartHomeConfig config) async {
    if (!await _isOnWifi()) return; // Never attempt on mobile data
    if (!config.lightsOnWake) return;

    switch (config.provider) {
      case SmartHomeProvider.philipsHue:
        await _hueRamp(config);
      case SmartHomeProvider.lifx:
        await _lifxRamp(config);
      case SmartHomeProvider.switchBot:
      case SmartHomeProvider.none:
        break;
    }
  }

  // ── Called after wake confirmation confirmed ──────────────────────────────
  Future<void> onWakeConfirmed(SmartHomeConfig config) async {
    if (!await _isOnWifi()) return;

    // Full brightness after wake confirmation
    if (config.lightsOnWake) {
      await _setFullBrightness(config);
    }

    // Smart kettle — start boiling
    if (config.kettleOnWake && config.provider == SmartHomeProvider.switchBot) {
      await _switchbotKettleOn(config);
    }
  }

  // ── Philips Hue ───────────────────────────────────────────────────────────
  Future<void> _hueRamp(SmartHomeConfig config) async {
    if (config.bridgeIp == null || config.bridgeToken == null) return;

    // Find lights in bedroom group (group 1 by default)
    // Ramp from 10% brightness at 2000K (warm) to 80% at 5000K (daylight)
    // over rampMinutes
    final rampMs = config.rampMinutes * 60 * 10; // Hue uses 100ms units

    final body = jsonEncode({
      'on':           true,
      'bri':          204,         // 80% brightness
      'ct':           200,         // ~5000K
      'transitiontime': rampMs,
    });

    try {
      await http.put(
        Uri.parse('http://${config.bridgeIp}/api/'
            '${config.bridgeToken}/groups/1/action'),
        headers: {'Content-Type': 'application/json'},
        body:    body,
      );
    } catch (_) {
      // WiFi may have dropped between check and call — silently fail
    }
  }

  Future<void> _setFullBrightness(SmartHomeConfig config) async {
    if (config.provider != SmartHomeProvider.philipsHue) return;
    if (config.bridgeIp == null || config.bridgeToken == null) return;

    try {
      await http.put(
        Uri.parse('http://${config.bridgeIp}/api/'
            '${config.bridgeToken}/groups/1/action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'on': true, 'bri': 254, 'ct': 153}),
      );
    } catch (_) {}
  }

  // ── LIFX ──────────────────────────────────────────────────────────────────
  Future<void> _lifxRamp(SmartHomeConfig config) async {
    if (config.lifxToken == null) return;
    final rampSec = config.rampMinutes * 60;

    try {
      await http.put(
        Uri.parse('https://api.lifx.com/v1/lights/all/state'),
        headers: {
          'Authorization': 'Bearer ${config.lifxToken}',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({
          'power':     'on',
          'color':     'kelvin:5000',
          'brightness': 0.8,
          'duration':   rampSec,
        }),
      );
    } catch (_) {}
  }

  // ── SwitchBot kettle ──────────────────────────────────────────────────────
  Future<void> _switchbotKettleOn(SmartHomeConfig config) async {
    if (config.switchbotToken == null) return;
    // SwitchBot API v1.1 — trigger device command
    // Device ID must be configured during smart home setup
    try {
      await http.post(
        Uri.parse('https://api.switch-bot.com/v1.1/devices/'
            'kettle/commands'),
        headers: {
          'Authorization': config.switchbotToken!,
          'Content-Type':  'application/json',
        },
        body: jsonEncode({
          'commandType': 'command',
          'command':     'boil',
        }),
      );
    } catch (_) {}
  }

  // ── WiFi check ────────────────────────────────────────────────────────────
  // Smart home features ONLY work on WiFi.
  // Never attempt on mobile data — smart home devices are local.
  Future<bool> _isOnWifi() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  // ── Capability discovery ──────────────────────────────────────────────────
  // Called from settings to discover Hue bridge on local network.
  Future<String?> discoverHueBridge() async {
    if (!await _isOnWifi()) return null;
    try {
      final resp = await http
          .get(Uri.parse('https://discovery.meethue.com/'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;
      final list = jsonDecode(resp.body) as List;
      if (list.isEmpty) return null;
      return (list.first as Map<String, dynamic>)['internalipaddress']
          as String?;
    } catch (_) {
      return null;
    }
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 6: lib/core/services/app_lifecycle_manager.dart
# PURPOSE: App foreground/background transitions.
#          Reschedules alarms on foreground resume.
#          Fires sync queue when connectivity restored.
#          Refreshes Remote Config hourly.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'alarm_service.dart';
import 'offline_sync_service.dart';
import 'remote_config_service.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _i = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _i;
  AppLifecycleManager._internal();

  final _alarmSvc  = AlarmService();
  final _syncSvc   = OfflineSyncService();
  final _rcSvc     = RemoteConfigService();
  DateTime?        _lastConfigRefresh;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    // Listen to connectivity changes — fire sync queue when online
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }

  Future<void> _onResume() async {
    // 1. Verify all alarms are still scheduled
    //    Android may have wiped alarms after reboot or battery save
    await _alarmSvc.rescheduleAllActiveAlarms();

    // 2. Refresh Remote Config if last fetch was >12 hours ago
    final now = DateTime.now();
    if (_lastConfigRefresh == null ||
        now.difference(_lastConfigRefresh!).inHours >= 12) {
      await _rcSvc.refresh();
      _lastConfigRefresh = now;
    }

    // 3. Attempt to drain sync queue
    await _syncSvc.drainQueue();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile);
    if (online) {
      _syncSvc.drainQueue();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 7: lib/features/shell/conversion_gate.dart
# PURPOSE: The weekly review preview — the single most effective
#          conversion mechanic in RISE.
#          Shows first paragraph of weekly review.
#          Blurs the rest. "Upgrade to read your full review."
#          Called from WeeklyReviewScreen for free users.
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/constants/app_constants.dart';

class ConversionGate extends ConsumerWidget {
  final String   fullNarrative;
  final Widget   lockedContent;

  const ConversionGate({
    super.key,
    required this.fullNarrative,
    required this.lockedContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionProvider).tier;
    final isFree = tier == AppConstants.tierStarter;

    if (!isFree) return lockedContent;

    // Extract the first paragraph (up to first double newline or 200 chars)
    final paragraphs = fullNarrative.split('\n\n');
    final preview    = paragraphs.isNotEmpty
        ? paragraphs.first
        : fullNarrative.substring(
            0, fullNarrative.length.clamp(0, 200));
    final rest = fullNarrative
        .substring(preview.length)
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visible paragraph — full opacity
        Text(preview, style: const TextStyle(
            color: Colors.white, fontSize: 16, height: 1.8,
            fontWeight: FontWeight.w300)),

        const SizedBox(height: 12),

        // Blurred remainder
        Stack(children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Text(
              rest.isNotEmpty ? rest
                  : 'Your sleep patterns, your habit consistency, '
                    'what the data reveals about your discipline '
                    'this week, and one thing to carry forward...',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 15,
                  height: 1.8),
              maxLines: 8,
              overflow: TextOverflow.fade,
            ),
          ),

          // Upgrade CTA overlay
          Positioned.fill(
            child: Center(
              child: _UpgradeCard(onTap: () =>
                  Navigator.pushNamed(context, '/upgrade')),
            ),
          ),
        ]),
      ],
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeCard({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(
          vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.indigoAccent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.indigoAccent.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Your full review is ready.',
              style: TextStyle(color: Colors.white,
                  fontSize: 17, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Core to read it every week.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('See plans',
                style: TextStyle(
                    color: Colors.black, fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 8: lib/features/shell/sponsor_slot.dart
# PURPOSE: Ad/sponsor slot — dark by default.
#          Remote config flag 'sponsor_slot_enabled' controls it.
#          When enabled: editorial-style sponsor message shown
#          once per week at bottom of WeeklyReviewScreen.
#          Never shown in morning ritual screens.
#          Free tier only.
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/remote_config_service.dart';

class SponsorSlot extends ConsumerWidget {
  /// Which screen this appears on. Used for impression analytics.
  final String placement;

  const SponsorSlot({super.key, required this.placement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionProvider).tier;

    // Only free users see sponsor content
    if (tier != AppConstants.tierStarter) return const SizedBox.shrink();

    final rc      = RemoteConfigService();
    final enabled = rc.getBool('sponsor_slot_enabled',
        defaultValue: false);         // Dark by default

    if (!enabled) return const SizedBox.shrink();

    final title   = rc.getString('sponsor_title',
        defaultValue: '');
    final body    = rc.getString('sponsor_body',
        defaultValue: '');
    final cta     = rc.getString('sponsor_cta',
        defaultValue: 'Learn more');
    final url     = rc.getString('sponsor_url',
        defaultValue: '');
    final brand   = rc.getString('sponsor_brand',
        defaultValue: '');

    if (title.isEmpty || body.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editorial label — transparent, never disguised as content
          Text('Brought to you by $brand',
              style: const TextStyle(
                  color: Colors.white24, fontSize: 10,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        const Color(0xFF161628),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    color: Colors.white70, fontSize: 14,
                    fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13, height: 1.5)),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      // Launch URL via url_launcher
                      // Track impression via analytics
                    },
                    child: Text(cta, style: const TextStyle(
                        color: Colors.indigoAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 9: pubspec.yaml — COMPLETE FINAL VERSION
# All parts consolidated. Conflict-resolved.
# ══════════════════════════════════════════════════════════════

```yaml
name: rise_alarm
description: RISE — The AI Alarm Clock That Understands You
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ── STATE MANAGEMENT ───────────────────────────────────────
  flutter_riverpod:     ^2.5.1
  riverpod_annotation:  ^2.3.5

  # ── LOCAL DATABASE ─────────────────────────────────────────
  hive_flutter:         ^1.1.0
  hive:                 ^2.2.3

  # ── ALARM ENGINE ───────────────────────────────────────────
  flutter_local_notifications: ^17.2.2
  android_alarm_manager_plus:  ^3.0.4
  wakelock_plus:               ^1.2.8
  volume_controller:           ^2.0.7

  # ── BIOMETRICS & CAMERA ────────────────────────────────────
  camera:               ^0.11.0+2
  google_ml_kit:        ^0.19.0
  local_auth:           ^2.3.0

  # ── PERMISSIONS ────────────────────────────────────────────
  permission_handler:   ^11.3.1
  app_settings:         ^5.1.1

  # ── NAVIGATION ─────────────────────────────────────────────
  go_router:            ^14.2.7

  # ── BACKGROUND SERVICES ────────────────────────────────────
  flutter_background_service: ^5.0.9
  workmanager:                ^0.5.2

  # ── SENSORS ────────────────────────────────────────────────
  sensors_plus:         ^5.0.1
  noise_meter:          ^6.0.2

  # ── LOCATION & GEOFENCING ──────────────────────────────────
  geolocator:           ^13.0.1
  geofence_service:     ^5.0.2

  # ── CONNECTIVITY ───────────────────────────────────────────
  connectivity_plus:    ^6.0.5    # Network state — offline graceful degradation

  # ── NETWORK ────────────────────────────────────────────────
  http:                 ^1.2.2

  # ── MONETIZATION ───────────────────────────────────────────
  purchases_flutter:    ^8.0.0    # RevenueCat — subscription lifecycle
  flutter_stripe:       ^10.1.1   # Stripe — West/Europe/Asia payments
  # Flutterwave: server-side only via Cloud Functions (no client SDK needed)

  # ── FOOD / BARCODE ─────────────────────────────────────────
  barcode_scan2:        ^4.3.3
  image_picker:         ^1.1.2

  # ── SHARING ────────────────────────────────────────────────
  share_plus:           ^7.2.2    # Quote sharing

  # ── URL LAUNCHER ───────────────────────────────────────────
  url_launcher:         ^6.3.0    # WhatsApp buddy links, smart home deep links

  # ── FIREBASE ───────────────────────────────────────────────
  firebase_core:           ^3.4.0
  firebase_auth:           ^5.2.1
  cloud_firestore:         ^5.4.1
  firebase_messaging:      ^15.1.3   # FCM push notifications
  firebase_analytics:      ^11.3.0
  firebase_crashlytics:    ^4.1.0
  firebase_remote_config:  ^4.3.3    # Server-driven UI + feature flags

  # ── UI & ANIMATIONS ────────────────────────────────────────
  animate_do:           ^3.3.4
  flutter_animate:      ^4.5.0
  lottie:               ^3.1.2
  shimmer:              ^3.0.0
  cached_network_image: ^3.4.1
  fl_chart:             ^0.69.0
  percent_indicator:    ^4.2.3

  # ── UTILITIES ──────────────────────────────────────────────
  intl:                 ^0.19.0
  shared_preferences:   ^2.3.2
  path_provider:        ^2.1.4
  package_info_plus:    ^8.0.2
  device_info_plus:     ^10.1.2
  uuid:                 ^4.4.2
  equatable:            ^2.0.5
  freezed_annotation:   ^2.4.4
  json_annotation:      ^4.9.0
  logger:               ^2.4.0
  timezone:             ^0.9.4
  flutter_timezone:     ^1.0.7

  # ── ICONS & FONTS ──────────────────────────────────────────
  flutter_svg:          ^2.0.10+1
  google_fonts:         ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints:        ^4.0.0
  build_runner:         ^2.4.13
  freezed:              ^2.5.7
  json_serializable:    ^6.8.0
  riverpod_generator:   ^2.4.3
  hive_generator:       ^2.0.1
  flutter_launcher_icons: ^0.14.1
  flutter_native_splash:  ^2.4.1

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/animations/
    - assets/sounds/
    - assets/data/
    - assets/quotes.json   # Bundled quote bank (offline-first)

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

# ══════════════════════════════════════════════════════════════
# FILE 10: firebase_setup_checklist.md
# ══════════════════════════════════════════════════════════════

```markdown
# RISE — Firebase Setup Checklist

Complete these steps in Firebase Console BEFORE first build.

## Project Setup
- [ ] Create project: rise-alarm (or rise-alarm-prod)
- [ ] Enable Google Analytics
- [ ] Download google-services.json → android/app/
- [ ] Download GoogleService-Info.plist → ios/Runner/
- [ ] Run: flutterfire configure

## Authentication
- [ ] Enable Anonymous sign-in provider
- [ ] (Optional) Enable Google sign-in for account linking later

## Firestore
- [ ] Create database in production mode
- [ ] Set region: closest to majority user base
      (Recommendation: europe-west1 for Africa/Europe users)
- [ ] Apply security rules (see firestore.rules below)

## Cloud Messaging (FCM)
- [ ] Enable Cloud Messaging
- [ ] Upload APNs auth key (iOS): Project Settings → Cloud Messaging
- [ ] Add FCM server key to backend environment

## Remote Config
- [ ] Create these parameters with defaults:
      sponsor_slot_enabled         = false (boolean)
      sponsor_title                = "" (string)
      sponsor_body                 = "" (string)
      sponsor_cta                  = "Learn more" (string)
      sponsor_url                  = "" (string)
      sponsor_brand                = "" (string)
      today_quote_category         = "mixed" (string)
      ramadan_active               = false (boolean)
      ramadan_start_date           = "" (string)
      wake_confirm_delay_minutes   = 15 (number)
      weekly_review_preview_enabled = true (boolean)
      goals_enabled                = true (boolean)
      quotes_enabled               = true (boolean)

## Cloud Functions (deploy separately)
Required functions from Part 10A:
  - createFlutterwavePaymentLink
  - flutterwaveWebhook
  - getOrCreateStripeCustomer
  - createStripeSubscription
  - confirmStripeSubscription
  - createStripeOneTimePayment
  - applyReferralCode
  - validateReferralCode
  - onSubscriptionConfirmed
  - onSubscriptionCancelled

## Crashlytics
- [ ] Enable in Firebase Console
- [ ] Verify crash reports appear after test crash

## Analytics Events to Track
- alarm_created
- alarm_dismissed (with game_type, duration_seconds)
- wake_game_completed (game_type, difficulty, passed)
- wake_confirmed
- streak_milestone (streak_days)
- onboarding_completed (mode, duration_seconds)
- subscription_started (tier, region, provider)
- weekly_review_opened
- weekly_review_upgrade_tapped   ← Conversion funnel
- monthly_letter_opened
- quote_shared
- goal_created
- habit_completed
- smart_home_triggered

## Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
                        && request.auth.uid == userId;
      match /{document=**} {
        allow read, write: if request.auth != null
                          && request.auth.uid == userId;
      }
    }
    match /referrals/{referralId} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud Functions only
    }
    match /leaderboard/{entry} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud Functions only
    }
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 11: FILE_TREE.md — Complete file tree, all 12 parts
# ══════════════════════════════════════════════════════════════

```markdown
# RISE — Complete File Tree (All 12 Parts)
# Total: 192 Dart files + config

rise_alarm/
├── pubspec.yaml                          (Part 12 — final version)
├── firebase.json
├── firestore.rules
├── google-services.json                  (Android — not in git)
├── GoogleService-Info.plist              (iOS — not in git)
│
├── lib/
│   ├── main.dart                         (Part 1 stub → Part 12 final)
│   ├── app.dart                          (Part 1 stub → Part 12 final)
│   ├── firebase_options.dart             (generated by flutterfire)
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart        (Part 1, updated each part)
│   │   │   ├── app_strings.dart          (Part 1)
│   │   │   └── asset_paths.dart          (Part 1)
│   │   │
│   │   ├── theme/
│   │   │   ├── app_colors.dart           (Part 1)
│   │   │   ├── app_text_styles.dart      (Part 1)
│   │   │   └── app_theme.dart            (Part 1)
│   │   │
│   │   ├── models/
│   │   │   ├── alarm_model.dart          (Part 2, typeId: 0)
│   │   │   ├── sleep_session.dart        (Part 2, typeId: 1)
│   │   │   ├── biometric_profile.dart    (Part 2, typeId: 2)
│   │   │   ├── calorie_entry.dart        (Part 10B, typeId: 3) ← replaces stub
│   │   │   ├── food_item.dart            (Part 10B, typeId: 4) ← replaces stub
│   │   │   ├── wake_game_result.dart     (Part 2, typeId: 5)
│   │   │   ├── buddy_contact.dart        (Part 2, typeId: 6)
│   │   │   ├── subscription_status.dart  (Part 2, typeId: 7)
│   │   │   ├── dream_entry.dart          (Part 6A, typeId: 8)
│   │   │   ├── wake_confirmation.dart    (Part 9, typeId: 9)
│   │   │   ├── north_star_goal.dart      (Part 10B, typeId: 10)
│   │   │   ├── habit_model.dart          (Part 10B, typeId: 11+15)
│   │   │   ├── daily_entry.dart          (Part 10B, typeId: 12)
│   │   │   ├── quote_item.dart           (Part 10B, typeId: 13)
│   │   │   ├── proof_wall_milestone.dart (Part 10B, typeId: 14)
│   │   │   ├── subscription_tier.dart    (Part 6A, UPDATED by Part 12)
│   │   │   ├── reward_ledger.dart        (Part 6A)
│   │   │   ├── sleep_challenge.dart      (Part 6A)
│   │   │   ├── referral_record.dart      (Part 6A)
│   │   │   ├── device_capability_model.dart (Part 2)
│   │   │   ├── feature_flag.dart         (Part 2)
│   │   │   ├── user_profile.dart         (Part 2)
│   │   │   ├── regional_pricing.dart     (Part 10A)
│   │   │   └── onboarding_state.dart     (Part 11)
│   │   │
│   │   ├── providers/
│   │   │   ├── capability_provider.dart  (Part 2)
│   │   │   ├── alarm_provider.dart       (Part 2)
│   │   │   ├── sleep_provider.dart       (Part 2)
│   │   │   ├── user_provider.dart        (Part 2)
│   │   │   ├── subscription_provider.dart (Part 11 — FINAL)
│   │   │   ├── biometric_provider.dart   (Part 4)
│   │   │   └── sleep_detection_provider.dart (Part 5)
│   │   │
│   │   └── services/
│   │       ├── alarm_service.dart             (Part 3)
│   │       ├── alarm_scheduler.dart           (Part 3)
│   │       ├── audio_route_manager.dart       (Part 3)
│   │       ├── battery_monitor.dart           (Part 3)
│   │       ├── dnd_checker.dart               (Part 3)
│   │       ├── driving_detector.dart          (Part 3)
│   │       ├── timezone_manager.dart          (Part 3)
│   │       ├── buddy_notification_service.dart (Part 3)
│   │       ├── background_service_manager.dart (Part 3)
│   │       ├── ppg_service.dart               (Part 4)
│   │       ├── biometric_service.dart         (Part 4)
│   │       ├── face_liveness_service.dart     (Part 4)
│   │       ├── pin_service.dart               (Part 4)
│   │       ├── biometric_enrollment_service.dart (Part 4)
│   │       ├── motion_analyzer.dart           (Part 5)
│   │       ├── sleep_detection_service.dart   (Part 5)
│   │       ├── thermal_monitor.dart           (Part 5)
│   │       ├── sleep_quality_scorer.dart      (Part 5)
│   │       ├── economy_service.dart           (Part 6A)
│   │       ├── referral_service.dart          (Part 6A — SUPERSEDED)
│   │       ├── dream_journal_service.dart     (Part 6A)
│   │       ├── wake_game_engine.dart          (Part 6A)
│   │       ├── wake_confirmation_service.dart (Part 9)
│   │       ├── regional_pricing_service.dart  (Part 10A)
│   │       ├── payment_service.dart           (Part 10A)
│   │       ├── flutterwave_service.dart       (Part 10A)
│   │       ├── stripe_service.dart            (Part 10A)
│   │       ├── referral_service_v2.dart       (Part 10A — USE THIS)
│   │       ├── remote_config_service.dart     (Part 10A)
│   │       ├── offline_sync_service.dart      (Part 10A)
│   │       ├── goals_service.dart             (Part 10B)
│   │       ├── ai_reflection_service.dart     (Part 10B)
│   │       ├── quote_service.dart             (Part 10B)
│   │       ├── calorie_service.dart           (Part 10B)
│   │       ├── onboarding_service.dart        (Part 11)
│   │       ├── notification_service.dart      (Part 12)
│   │       ├── smart_home_service.dart        (Part 12)
│   │       └── app_lifecycle_manager.dart     (Part 12)
│   │
│   ├── shared/
│   │   └── widgets/
│   │       ├── rise_button.dart               (Part 1)
│   │       ├── rise_card.dart                 (Part 1)
│   │       ├── rise_scaffold.dart             (Part 1)
│   │       ├── capability_banner.dart         (Part 2)
│   │       ├── feature_gate.dart              (Part 2)
│   │       ├── ppg_capture_widget.dart        (Part 4)
│   │       ├── biometric_verification_sheet.dart (Part 4)
│   │       └── pin_entry_widget.dart          (Part 4)
│   │
│   └── features/
│       ├── shell/
│       │   ├── main_shell.dart                (Part 12)
│       │   ├── conversion_gate.dart           (Part 12)
│       │   └── sponsor_slot.dart              (Part 12)
│       │
│       ├── onboarding/
│       │   ├── onboarding_shell.dart          (Part 11)
│       │   └── steps/
│       │       ├── welcome_step.dart          (Part 11)
│       │       ├── mode_select_step.dart      (Part 11)
│       │       ├── permissions_step.dart      (Part 11)
│       │       ├── profile_step.dart          (Part 11)
│       │       ├── faith_step.dart            (Part 11)
│       │       ├── biometric_intro_step.dart  (Part 11)
│       │       └── first_alarm_step.dart      (Part 11)
│       │
│       ├── home/
│       │   ├── home_screen.dart               (Part 9 — final)
│       │   └── widgets/
│       │       ├── upcoming_alarm_card.dart   (Part 9)
│       │       ├── sleep_score_card.dart      (Part 9)
│       │       ├── streak_card.dart           (Part 9)
│       │       └── wake_confirmation_banner.dart (Part 9)
│       │
│       ├── alarm/
│       │   ├── alarm_screen_controller.dart   (Part 7)
│       │   ├── alarm_screen.dart              (Part 7)
│       │   ├── alarm_setup_screen.dart        (Part 8)
│       │   └── widgets/
│       │       ├── alarm_header.dart          (Part 7)
│       │       ├── biometric_gate.dart        (Part 7)
│       │       ├── snooze_panel.dart          (Part 7)
│       │       ├── post_dismiss_screen.dart   (Part 7)
│       │       └── sound_picker.dart          (Part 8)
│       │
│       ├── sleep/
│       │   └── sleep_tracker_screen.dart      (Part 5)
│       │
│       ├── wake_games/
│       │   └── games/
│       │       ├── math_game.dart             (Part 6B)
│       │       ├── memory_grid_game.dart      (Part 6B)
│       │       ├── word_unscramble_game.dart  (Part 6B)
│       │       ├── sequence_tap_game.dart     (Part 6B)
│       │       └── barcode_scan_game.dart     (Part 6B)
│       │
│       ├── goals/
│       │   ├── goals_screen.dart              (Part 10B)
│       │   ├── daily_intention_screen.dart    (Part 10B)
│       │   ├── weekly_review_screen.dart      (Part 10B)
│       │   ├── monthly_letter_screen.dart     (Part 10B)
│       │   └── proof_wall_screen.dart         (Part 10B)
│       │
│       ├── quotes/
│       │   └── quotes_screen.dart             (Part 10B)
│       │
│       ├── calorie/
│       │   ├── calorie_screen.dart            (Part 10B)
│       │   └── food_search_sheet.dart         (Part 10B)
│       │
│       ├── social/
│       │   ├── leaderboard_service.dart       (Part 6B)
│       │   ├── sleep_challenge_service.dart   (Part 6B)
│       │   ├── leaderboard_screen.dart        (Part 6B)
│       │   ├── wallet_screen.dart             (Part 6B)
│       │   └── referral_screen.dart           (Part 6B)
│       │
│       ├── paywall/
│       │   ├── paywall_screen.dart            (Part 10A)
│       │   └── widgets/
│       │       └── tier_card.dart             (Part 10A)
│       │
│       └── settings/
│           ├── settings_screen.dart           (Part 8)
│           ├── alarm_setup_screen.dart        (Part 8)
│           └── sections/
│               ├── accessibility_settings.dart (Part 8)
│               ├── safety_settings.dart        (Part 8)
│               ├── notification_settings.dart  (Part 8)
│               └── biometric_settings.dart     (Part 8)
│
└── assets/
    ├── quotes.json          ← Bundle at least 100 quotes before launch
    ├── fonts/
    │   └── Inter-*.ttf
    ├── images/
    ├── animations/          ← Lottie JSON files
    ├── sounds/              ← Alarm tones (OGG + AAC)
    └── data/                ← Static reference data

# Cloud Functions (separate deploy)
functions/
├── createFlutterwavePaymentLink.js
├── flutterwaveWebhook.js
├── getOrCreateStripeCustomer.js
├── createStripeSubscription.js
├── confirmStripeSubscription.js
├── createStripeOneTimePayment.js
├── applyReferralCode.js
├── validateReferralCode.js
├── onSubscriptionConfirmed.js
└── onSubscriptionCancelled.js
```

---

## SERVICE INITIALIZATION ORDER (critical — do not reorder)

```
main() sequence:
  1. WidgetsFlutterBinding.ensureInitialized()
  2. Firebase.initializeApp()
  3. FlutterError.onError → Crashlytics
  4. tz.initializeTimeZones()
  5. Hive.initFlutter(appDir)
  6. Register ALL Hive adapters
  7. Hive.openBox() × 17 (in parallel via Future.wait)
  8. NotificationService.initialize()
  9. NotificationService.registerFcmBackgroundHandler()
  10. AppLifecycleManager.initialize()
  11. runApp(ProviderScope(child: RiseApp()))

Post-onboarding sequence (OnboardingService.completeOnboarding):
  1. FirebaseAuth.signInAnonymously()
  2. SharedPreferences profile writes
  3. PaymentService.initialize(userId)
  4. OfflineSyncService.initialize()
  5. RemoteConfigService.refresh()
  6. CalorieService.seedFoodDatabase()
  7. OfflineSyncService.queue(updateUserProfile)

App resume sequence (AppLifecycleManager._onResume):
  1. AlarmService.rescheduleAllActiveAlarms()
  2. RemoteConfigService.refresh() (if >12h since last)
  3. OfflineSyncService.drainQueue()
```

---

## SMART HOME INTEGRATION POINTS

```
AlarmService.scheduleAlarm() should also:
  → Call SmartHomeService.startLightRamp(config) at
    (alarmTime - config.rampMinutes) using workmanager

WakeConfirmationService.confirmWake() should also:
  → Call SmartHomeService.onWakeConfirmed(config)

WiFi required: SmartHomeService checks connectivity
  before EVERY API call. Never attempts on mobile data.
  Always fails silently — never shows error to user.
```

---

## CONVERSION FUNNEL — IMPLEMENTATION NOTES

```
WeeklyReviewScreen should:
  1. Always generate the review (even for free users)
  2. Free users: wrap narrative in ConversionGate widget
  3. ConversionGate shows first paragraph + blur + upgrade CTA
  4. Track analytics event: 'weekly_review_upgrade_tapped'
     when CTA is tapped

This is the #1 conversion driver. Build it carefully.
The weekly review text must be compelling — the blur
creates desire only if what's visible is already worth reading.

Analytics to watch:
  weekly_review_opened → weekly_review_upgrade_tapped
  Target conversion: 8–12% of free users who see the gate
  should tap through to the paywall.
```

---

## END OF PART 12 BLUEPRINT
## 12 files | Complete pubspec | Firebase checklist | Full file tree
##
## RISE Blueprint: COMPLETE (All 12 Parts)
##
## Total lines across all 12 parts: ~36,500
## Total Dart files: 192
## Total Cloud Functions: 10
##
## Parts summary:
##   Part 1:  Foundation (main, app, theme, constants)
##   Part 2:  Device capability system (19 files)
##   Part 3:  Alarm engine (5-layer failsafe, 17 files)
##   Part 4:  Biometric verification (PPG + face + PIN)
##   Part 5:  Sleep detection service
##   Part 6:  Business model (wake games, economy, dreams)
##   Part 7:  Alarm screen (6-phase state machine)
##   Part 8:  Settings architecture (5 subsections)
##   Part 9:  Wake confirmation + Home dashboard
##   Part 10A: Monetization engine (payments, referral V2)
##   Part 10B: Goals journal + Quotes + Calorie tracker
##   Part 11: Onboarding flow (3 modes, 7 steps)
##   Part 12: Wiring, navigation, notifications, smart home
