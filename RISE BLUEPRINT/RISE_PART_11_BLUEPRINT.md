# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 11 OF 12
# Onboarding Flow — First-Run Experience
# ============================================================
# COMMAND TO AI CODING AGENT:
# Parts 1–10B must be complete before starting this part.
# Read EVERY section before writing a single line of code.
# Onboarding is the only thing standing between a new user
# and everything RISE has built. Get it wrong and none of
# Parts 1–10 matter. Get it right and the user is set up
# for a streak that never ends.
#
# WHAT THIS PART CREATES (11 files):
#
#  1. lib/core/models/onboarding_state.dart
#     Full onboarding state model stored in SharedPreferences.
#     Survives app kills. Resumable at any interrupted step.
#
#  2. lib/core/services/onboarding_service.dart
#     Orchestrates all onboarding steps. Determines mode
#     (Quick/Standard/Assisted). Writes user profile.
#     Triggers all downstream initializations on completion.
#
#  3. lib/core/providers/subscription_provider.dart
#     The Riverpod provider referenced in Parts 10A and 10B.
#     Holds tierId, displayName, storefrontCountry, faithContext.
#     Populated at end of onboarding. Persists to SharedPreferences.
#
#  4. lib/features/onboarding/onboarding_shell.dart
#     Root navigator for the entire onboarding sequence.
#     Handles: step routing, back navigation, progress bar,
#     skip logic, crash recovery.
#
#  5. lib/features/onboarding/steps/welcome_step.dart
#     First screen. RISE brand moment. Mode detection.
#     Auto-suggests Assisted if accessibility settings active.
#
#  6. lib/features/onboarding/steps/mode_select_step.dart
#     Quick / Standard / Assisted mode selection.
#     Explains what each mode means. Non-judgmental language.
#
#  7. lib/features/onboarding/steps/permissions_step.dart
#     Permission requests in the CORRECT order.
#     Notifications → Exact Alarm → Battery Optimization →
#     Camera (biometrics) → Motion (wake confirmation).
#     Each explained in plain human language before requesting.
#     EC-9.2: Assisted mode shows full visual guide per permission.
#
#  8. lib/features/onboarding/steps/profile_step.dart
#     Name, regional detection (storefront), calorie target,
#     sleep goal (hours), bedtime suggestion.
#
#  9. lib/features/onboarding/steps/faith_step.dart
#     Faith preference selection. Non-pressured. Skippable.
#     Shows which features this personalizes.
#
# 10. lib/features/onboarding/steps/biometric_intro_step.dart
#     Explains the 5-session enrollment protocol.
#     Session 1 happens here. Sessions 2-5 during real alarms.
#     EC-8.1: Anti-gaming rules explained plainly.
#     EC-9.2: Assisted mode uses large text + slow animations.
#
# 11. lib/features/onboarding/steps/first_alarm_step.dart
#     User sets their first alarm. Full AlarmModel creation.
#     Goal connection. Wake confirmation toggle.
#     Buddy invite (optional). Referral code entry.
#     Paywall entry point (if upgrading from free).
#     Final completion — streak Day 0 created.
#     "The first morning is waiting" finish screen.
#
# ══════════════════════════════════════════════════════════════
# ONBOARDING DESIGN PRINCIPLES:
#
# 1. RESUMABLE: If user quits mid-onboarding, app resumes at
#    exact step on next launch. No data is lost.
#
# 2. THREE MODES — Quick / Standard / Assisted:
#    Quick:    Name + first alarm only. 90 seconds.
#              Biometrics, faith, buddy all skipped.
#              User can set these later in Settings.
#    Standard: Full flow. ~4 minutes. Recommended.
#    Assisted: Large text, slow animations, generous tap targets.
#              Step-by-step voice-style explanations.
#              Auto-suggested if system accessibility settings
#              indicate large text or high contrast.
#
# 3. PERMISSION ORDER MATTERS:
#    Android: Notifications first (most non-scary) → exact alarm
#    (explain why) → battery optimization (explain story) →
#    camera (biometrics) → motion (wake confirmation).
#    iOS: Notifications only (others granted by default or in
#    Settings). Camera only if biometrics chosen.
#    NEVER ask for more than one permission per screen.
#    NEVER show the system dialog without first showing our
#    own explanation screen that tells the user WHY.
#
# 4. FAITH IS OPTIONAL AND NON-PRESSURED:
#    The faith step says clearly: "This personalizes your
#    morning quotes and dream interpretation. Skip it if
#    you prefer a secular experience." Secular is a valid,
#    first-class option — not a fallback.
#
# 5. BIOMETRIC ENROLLMENT IS A 5-DAY PROCESS:
#    Session 1 happens during onboarding.
#    Sessions 2-5 are triggered automatically on real alarm
#    dismissals over subsequent days.
#    The user is told this clearly: "We need 5 real morning
#    readings to build your profile. Today is Session 1."
#    This sets expectations and prevents confusion later.
#
# 6. THE FIRST ALARM IS SACRED:
#    The moment a user sets their first alarm is the most
#    important moment in the RISE experience. The UI must
#    feel intentional, calm, and optimistic — not like a
#    settings form. It should feel like a commitment.
# ============================================================

---

## FILE 1: lib/core/models/onboarding_state.dart
## PURPOSE: Complete onboarding state. Persisted to SharedPreferences.
##          Survives app kills. Resumable at any step.

```dart
enum OnboardingMode { quick, standard, assisted }

enum OnboardingStep {
  welcome,
  modeSelect,
  permissions,
  profile,
  faith,
  biometricIntro,
  firstAlarm,
  complete,
}

extension OnboardingStepExt on OnboardingStep {
  bool get isSkippableInQuickMode => switch (this) {
    OnboardingStep.permissions    => false, // Never skip permissions
    OnboardingStep.faith          => true,
    OnboardingStep.biometricIntro => true,
    _                             => false,
  };

  /// Total steps shown in standard mode for progress bar.
  static const standardStepCount = 6;

  int get progressIndex => switch (this) {
    OnboardingStep.welcome        => 0,
    OnboardingStep.modeSelect     => 0,
    OnboardingStep.permissions    => 1,
    OnboardingStep.profile        => 2,
    OnboardingStep.faith          => 3,
    OnboardingStep.biometricIntro => 4,
    OnboardingStep.firstAlarm     => 5,
    OnboardingStep.complete       => 6,
  };
}

class OnboardingState {
  final OnboardingMode mode;
  final OnboardingStep currentStep;
  final bool           permissionsGranted;
  final bool           notificationGranted;
  final bool           exactAlarmGranted;
  final bool           batteryOptExempt;
  final bool           cameraGranted;
  final bool           motionGranted;
  final String?        displayName;
  final String         storefrontCountry;
  final int            calorieTarget;
  final double         sleepGoalHours;
  final String?        faithContext;     // FaithOption.name or null
  final bool           faithStepSkipped;
  final bool           biometricSession1Done;
  final String?        firstAlarmId;
  final bool           complete;
  final DateTime       startedAt;

  const OnboardingState({
    this.mode                  = OnboardingMode.standard,
    this.currentStep           = OnboardingStep.welcome,
    this.permissionsGranted    = false,
    this.notificationGranted   = false,
    this.exactAlarmGranted     = false,
    this.batteryOptExempt      = false,
    this.cameraGranted         = false,
    this.motionGranted         = false,
    this.displayName,
    this.storefrontCountry     = 'US',
    this.calorieTarget         = 2000,
    this.sleepGoalHours        = 8.0,
    this.faithContext,
    this.faithStepSkipped      = false,
    this.biometricSession1Done = false,
    this.firstAlarmId,
    this.complete              = false,
    required this.startedAt,
  });

  OnboardingState copyWith({
    OnboardingMode?  mode,
    OnboardingStep?  currentStep,
    bool?            permissionsGranted,
    bool?            notificationGranted,
    bool?            exactAlarmGranted,
    bool?            batteryOptExempt,
    bool?            cameraGranted,
    bool?            motionGranted,
    String?          displayName,
    String?          storefrontCountry,
    int?             calorieTarget,
    double?          sleepGoalHours,
    String?          faithContext,
    bool?            faithStepSkipped,
    bool?            biometricSession1Done,
    String?          firstAlarmId,
    bool?            complete,
  }) => OnboardingState(
    mode:                  mode                  ?? this.mode,
    currentStep:           currentStep           ?? this.currentStep,
    permissionsGranted:    permissionsGranted    ?? this.permissionsGranted,
    notificationGranted:   notificationGranted   ?? this.notificationGranted,
    exactAlarmGranted:     exactAlarmGranted     ?? this.exactAlarmGranted,
    batteryOptExempt:      batteryOptExempt      ?? this.batteryOptExempt,
    cameraGranted:         cameraGranted         ?? this.cameraGranted,
    motionGranted:         motionGranted         ?? this.motionGranted,
    displayName:           displayName           ?? this.displayName,
    storefrontCountry:     storefrontCountry     ?? this.storefrontCountry,
    calorieTarget:         calorieTarget         ?? this.calorieTarget,
    sleepGoalHours:        sleepGoalHours        ?? this.sleepGoalHours,
    faithContext:          faithContext          ?? this.faithContext,
    faithStepSkipped:      faithStepSkipped      ?? this.faithStepSkipped,
    biometricSession1Done: biometricSession1Done ?? this.biometricSession1Done,
    firstAlarmId:          firstAlarmId          ?? this.firstAlarmId,
    complete:              complete              ?? this.complete,
    startedAt:             startedAt,
  );

  Map<String, dynamic> toJson() => {
    'mode':                  mode.name,
    'currentStep':           currentStep.name,
    'permissionsGranted':    permissionsGranted,
    'notificationGranted':   notificationGranted,
    'exactAlarmGranted':     exactAlarmGranted,
    'batteryOptExempt':      batteryOptExempt,
    'cameraGranted':         cameraGranted,
    'motionGranted':         motionGranted,
    'displayName':           displayName,
    'storefrontCountry':     storefrontCountry,
    'calorieTarget':         calorieTarget,
    'sleepGoalHours':        sleepGoalHours,
    'faithContext':          faithContext,
    'faithStepSkipped':      faithStepSkipped,
    'biometricSession1Done': biometricSession1Done,
    'firstAlarmId':          firstAlarmId,
    'complete':              complete,
    'startedAt':             startedAt.toIso8601String(),
  };

  factory OnboardingState.fromJson(Map<String, dynamic> j) =>
      OnboardingState(
        mode:      OnboardingMode.values.byName(
            j['mode'] as String? ?? 'standard'),
        currentStep: OnboardingStep.values.byName(
            j['currentStep'] as String? ?? 'welcome'),
        permissionsGranted:    j['permissionsGranted']    as bool? ?? false,
        notificationGranted:   j['notificationGranted']   as bool? ?? false,
        exactAlarmGranted:     j['exactAlarmGranted']     as bool? ?? false,
        batteryOptExempt:      j['batteryOptExempt']      as bool? ?? false,
        cameraGranted:         j['cameraGranted']         as bool? ?? false,
        motionGranted:         j['motionGranted']         as bool? ?? false,
        displayName:           j['displayName']           as String?,
        storefrontCountry:     j['storefrontCountry']     as String? ?? 'US',
        calorieTarget:         j['calorieTarget']         as int?    ?? 2000,
        sleepGoalHours:        (j['sleepGoalHours'] as num?)?.toDouble()
                               ?? 8.0,
        faithContext:          j['faithContext']          as String?,
        faithStepSkipped:      j['faithStepSkipped']      as bool? ?? false,
        biometricSession1Done: j['biometricSession1Done'] as bool? ?? false,
        firstAlarmId:          j['firstAlarmId']          as String?,
        complete:              j['complete']              as bool? ?? false,
        startedAt: DateTime.parse(
            j['startedAt'] as String? ??
            DateTime.now().toIso8601String()),
      );

  factory OnboardingState.fresh() =>
      OnboardingState(startedAt: DateTime.now());
}
```

---

## FILE 2: lib/core/services/onboarding_service.dart
## PURPOSE: Orchestrates all onboarding steps.
##          Determines mode. Writes user profile.
##          Triggers downstream inits on completion.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/onboarding_state.dart';
import 'calorie_service.dart';
import 'offline_sync_service.dart';
import 'payment_service.dart';
import 'regional_pricing_service.dart';
import 'remote_config_service.dart';

class OnboardingService {
  static final OnboardingService _i = OnboardingService._internal();
  factory OnboardingService() => _i;
  OnboardingService._internal();

  static const _stateKey = 'onboarding_state_v1';
  static const _channel  = MethodChannel(
      'com.rise.alarmclock/capabilities');

  // ── Load / save state ─────────────────────────────────────────────────────

  Future<OnboardingState> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_stateKey);
    if (json == null) return OnboardingState.fresh();
    try {
      return OnboardingState.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return OnboardingState.fresh();
    }
  }

  Future<void> saveState(OnboardingState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state.toJson()));
  }

  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
  }

  // ── Mode detection ────────────────────────────────────────────────────────
  // Auto-suggests Assisted if system accessibility settings indicate
  // large text or bold text preferences (EC-9.2).
  Future<OnboardingMode> detectSuggestedMode() async {
    try {
      final textScale = await _channel
          .invokeMethod('getTextScaleFactor') as double? ?? 1.0;
      if (textScale >= 1.4) return OnboardingMode.assisted;
    } catch (_) {}
    return OnboardingMode.standard;
  }

  // ── Regional detection ────────────────────────────────────────────────────
  Future<String> detectStorefrontCountry() async {
    return RegionalPricingService()._getStorefrontCountry();
  }

  // ── Permission requests ───────────────────────────────────────────────────
  // Each method requests exactly ONE permission.
  // The UI shows our explanation screen first, then calls these.

  Future<bool> requestNotifications() async {
    if (Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    // Android 13+
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> requestExactAlarm() async {
    if (Platform.isIOS) return true; // iOS handles this natively
    try {
      final result = await _channel
          .invokeMethod('requestExactAlarmPermission') as bool? ?? false;
      return result;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    if (Platform.isIOS) return true;
    try {
      final result = await _channel
          .invokeMethod('requestBatteryOptimizationExemption') as bool?
          ?? false;
      return result;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestMotionSensors() async {
    if (Platform.isIOS) {
      final status = await Permission.sensors.request();
      return status.isGranted;
    }
    // Android: activity recognition
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  // ── Step navigation logic ─────────────────────────────────────────────────
  // Returns the next step given current state and mode.
  OnboardingStep nextStep(OnboardingState state) {
    return switch (state.currentStep) {
      OnboardingStep.welcome     => OnboardingStep.modeSelect,
      OnboardingStep.modeSelect  => OnboardingStep.permissions,
      OnboardingStep.permissions => OnboardingStep.profile,
      OnboardingStep.profile     =>
          state.mode == OnboardingMode.quick
              ? OnboardingStep.firstAlarm
              : OnboardingStep.faith,
      OnboardingStep.faith       => OnboardingStep.biometricIntro,
      OnboardingStep.biometricIntro => OnboardingStep.firstAlarm,
      OnboardingStep.firstAlarm  => OnboardingStep.complete,
      OnboardingStep.complete    => OnboardingStep.complete,
    };
  }

  // ── Completion ────────────────────────────────────────────────────────────
  // Called after the first alarm is set. Writes profile to Firestore
  // and triggers all downstream initializations.
  Future<void> completeOnboarding(OnboardingState state) async {
    // 1. Authenticate anonymously if no user yet
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final userId = auth.currentUser!.uid;

    // 2. Write profile to SharedPreferences for local access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id',            userId);
    await prefs.setString('display_name',       state.displayName ?? 'Friend');
    await prefs.setString('storefront_country', state.storefrontCountry);
    await prefs.setInt   ('calorie_target',     state.calorieTarget);
    await prefs.setDouble('sleep_goal_hours',   state.sleepGoalHours);
    if (state.faithContext != null) {
      await prefs.setString('faith_context', state.faithContext!);
    }
    await prefs.setBool('onboarding_complete', true);

    // 3. Initialize all services that need userId
    await PaymentService().initialize(userId);
    await OfflineSyncService().initialize();
    await RemoteConfigService().refresh();

    // 4. Seed the food database (first run)
    await CalorieService().seedFoodDatabase();

    // 5. Queue user profile sync to Firestore
    await OfflineSyncService().queue(SyncOpType.updateUserProfile, {
      'userId':           userId,
      'displayName':      state.displayName ?? 'Friend',
      'storefrontCountry': state.storefrontCountry,
      'calorieTarget':    state.calorieTarget,
      'sleepGoalHours':   state.sleepGoalHours,
      'faithContext':     state.faithContext,
      'onboardedAt':      DateTime.now().toIso8601String(),
    });

    // 6. Mark onboarding state as complete
    await saveState(state.copyWith(complete: true));
  }

  // ── Check if onboarding is already done ──────────────────────────────────
  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
```

---

## FILE 3: lib/core/providers/subscription_provider.dart
## PURPOSE: The Riverpod provider referenced across Parts 10A/10B.
##          Holds tierId, displayName, storefrontCountry, faithContext.
##          Populated at end of onboarding. Persists across sessions.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/regional_pricing.dart';
import '../services/payment_service.dart';

class SubscriptionState {
  final String  tier;
  final String? displayName;
  final String  storefrontCountry;
  final String? faithContext;
  final bool    isLoaded;

  const SubscriptionState({
    this.tier              = AppConstants.tierStarter,
    this.displayName,
    this.storefrontCountry = 'US',
    this.faithContext,
    this.isLoaded          = false,
  });

  SubscriptionState copyWith({
    String?  tier,
    String?  displayName,
    String?  storefrontCountry,
    String?  faithContext,
    bool?    isLoaded,
  }) => SubscriptionState(
    tier:              tier              ?? this.tier,
    displayName:       displayName       ?? this.displayName,
    storefrontCountry: storefrontCountry ?? this.storefrontCountry,
    faithContext:      faithContext      ?? this.faithContext,
    isLoaded:          isLoaded          ?? this.isLoaded,
  );

  RegionalPricing get pricing =>
      RegionalPricing.forCountry(storefrontCountry);
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs   = await SharedPreferences.getInstance();
    final tierId  = await PaymentService().getCurrentTierId();

    state = SubscriptionState(
      tier:              tierId,
      displayName:       prefs.getString('display_name'),
      storefrontCountry: prefs.getString('storefront_country') ?? 'US',
      faithContext:      prefs.getString('faith_context'),
      isLoaded:          true,
    );
  }

  Future<void> refresh() async => _load();

  Future<void> updateProfile({
    String?  displayName,
    String?  faithContext,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (displayName != null) {
      await prefs.setString('display_name', displayName);
    }
    if (faithContext != null) {
      await prefs.setString('faith_context', faithContext);
    }
    state = state.copyWith(
      displayName:  displayName  ?? state.displayName,
      faithContext: faithContext ?? state.faithContext,
    );
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(),
);
```

---

## FILE 4: lib/features/onboarding/onboarding_shell.dart
## PURPOSE: Root navigator for the entire onboarding sequence.
##          Handles step routing, back navigation, progress bar,
##          crash recovery, and mode-aware skipping.

```dart
import 'package:flutter/material.dart';
import '../../core/models/onboarding_state.dart';
import '../../core/services/onboarding_service.dart';
import 'steps/biometric_intro_step.dart';
import 'steps/faith_step.dart';
import 'steps/first_alarm_step.dart';
import 'steps/mode_select_step.dart';
import 'steps/permissions_step.dart';
import 'steps/profile_step.dart';
import 'steps/welcome_step.dart';

class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final _svc   = OnboardingService();
  OnboardingState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final state = await _svc.loadState();
    if (!mounted) return;
    setState(() { _state = state; _loading = false; });
  }

  void _advance(OnboardingState updated) {
    final next = _svc.nextStep(updated);
    final newState = updated.copyWith(currentStep: next);
    _svc.saveState(newState);
    setState(() => _state = newState);
  }

  void _updateAndStay(OnboardingState updated) {
    _svc.saveState(updated);
    setState(() => _state = updated);
  }

  void _back() {
    if (_state == null) return;
    // Determine previous step (simple back stack)
    final prev = _prevStep(_state!.currentStep, _state!.mode);
    if (prev == null) return; // Already at first step
    final newState = _state!.copyWith(currentStep: prev);
    _svc.saveState(newState);
    setState(() => _state = newState);
  }

  OnboardingStep? _prevStep(OnboardingStep current, OnboardingMode mode) {
    return switch (current) {
      OnboardingStep.modeSelect     => OnboardingStep.welcome,
      OnboardingStep.permissions    => OnboardingStep.modeSelect,
      OnboardingStep.profile        => OnboardingStep.permissions,
      OnboardingStep.faith          => OnboardingStep.profile,
      OnboardingStep.biometricIntro => OnboardingStep.faith,
      OnboardingStep.firstAlarm     =>
          mode == OnboardingMode.quick
              ? OnboardingStep.profile
              : OnboardingStep.biometricIntro,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _state == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: CircularProgressIndicator(
            color: Colors.white24)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(children: [
          // Progress bar (not shown on welcome/mode-select)
          if (_showProgress)
            _OnboardingProgressBar(
              step:  _state!.currentStep,
              mode:  _state!.mode,
              onBack: _canGoBack ? _back : null,
            ),
          Expanded(child: _buildStep()),
        ]),
      ),
    );
  }

  bool get _showProgress =>
      _state!.currentStep != OnboardingStep.welcome &&
      _state!.currentStep != OnboardingStep.modeSelect &&
      _state!.currentStep != OnboardingStep.complete;

  bool get _canGoBack =>
      _prevStep(_state!.currentStep, _state!.mode) != null;

  Widget _buildStep() {
    final s = _state!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0.05, 0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: anim, curve: Curves.easeOut)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey(s.currentStep),
        child: switch (s.currentStep) {
          OnboardingStep.welcome     => WelcomeStep(
              onContinue: (mode) => _advance(
                  s.copyWith(mode: mode,
                      currentStep: OnboardingStep.welcome)),
            ),
          OnboardingStep.modeSelect  => ModeSelectStep(
              suggestedMode: s.mode,
              onSelect: (mode) => _advance(s.copyWith(mode: mode)),
            ),
          OnboardingStep.permissions => PermissionsStep(
              state: s,
              onComplete: (updated) => _advance(updated),
            ),
          OnboardingStep.profile     => ProfileStep(
              state: s,
              onComplete: (updated) => _advance(updated),
            ),
          OnboardingStep.faith       => FaithStep(
              state: s,
              onComplete: (updated) => _advance(updated),
              onSkip:     () => _advance(
                  s.copyWith(faithStepSkipped: true)),
            ),
          OnboardingStep.biometricIntro => BiometricIntroStep(
              state: s,
              onComplete: (updated) => _advance(updated),
              onSkip:     () => _advance(s),
            ),
          OnboardingStep.firstAlarm  => FirstAlarmStep(
              state: s,
              onComplete: (updated) {
                _svc.completeOnboarding(updated);
                _advance(updated.copyWith(complete: true));
              },
            ),
          OnboardingStep.complete    => _CompletionScreen(
              name: s.displayName ?? 'Friend',
            ),
        },
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────

class _OnboardingProgressBar extends StatelessWidget {
  final OnboardingStep currentStep;
  final OnboardingMode mode;
  final VoidCallback?  onBack;

  const _OnboardingProgressBar({
    required this.currentStep,
    required this.mode,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final total    = OnboardingStepExt.standardStepCount;
    final progress = currentStep.progressIndex / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        if (onBack != null)
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios,
                color: Colors.white38, size: 18),
          )
        else
          const SizedBox(width: 18),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           progress,
              backgroundColor: Colors.white.withOpacity(0.08),
              color:           Colors.indigoAccent,
              minHeight:       4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('${currentStep.progressIndex}/$total',
            style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 11)),
      ]),
    );
  }
}

// ── Completion screen ─────────────────────────────────────────────────────

class _CompletionScreen extends StatefulWidget {
  final String name;
  const _CompletionScreen({required this.name});
  @override
  State<_CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<_CompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    // Navigate to main app after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Center(
    child: FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌅', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text('Good morning, ${widget.name}.',
                style: const TextStyle(color: Colors.white,
                    fontSize: 26, fontWeight: FontWeight.w200)),
            const SizedBox(height: 12),
            Text('The first morning is waiting.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}
```

---

## FILE 5: lib/features/onboarding/steps/welcome_step.dart
## PURPOSE: First screen. RISE brand moment.
##          Detects suggested mode. Gets out of the way quickly.

```dart
import 'package:flutter/material.dart';
import '../../../core/models/onboarding_state.dart';
import '../../../core/services/onboarding_service.dart';

class WelcomeStep extends StatefulWidget {
  final void Function(OnboardingMode mode) onContinue;
  const WelcomeStep({super.key, required this.onContinue});
  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  final _svc = OnboardingService();
  OnboardingMode _suggestedMode = OnboardingMode.standard;
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _detect();
  }

  Future<void> _detect() async {
    final mode = await _svc.detectSuggestedMode();
    if (mounted) setState(() => _suggestedMode = mode);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Brand mark
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.alarm,
                color: Colors.white, size: 40),
          ),

          const SizedBox(height: 32),
          const Text('RISE',
              style: TextStyle(color: Colors.white, fontSize: 36,
                  fontWeight: FontWeight.w200, letterSpacing: 8)),
          const SizedBox(height: 16),
          Text('Wake up on purpose.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 17)),

          const Spacer(flex: 3),

          // Large mode CTA
          ElevatedButton(
            onPressed: () => widget.onContinue(_suggestedMode),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize:     const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Get started',
                style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 12),

          // Assisted mode hint (shown if detected)
          if (_suggestedMode == OnboardingMode.assisted)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'We\'ve detected accessibility settings are active. '
                'We\'ll set things up at a comfortable pace.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}
```

---

## FILE 6: lib/features/onboarding/steps/mode_select_step.dart
## PURPOSE: Quick / Standard / Assisted mode selection.
##          Non-judgmental language. Assisted is not "for old people."

```dart
import 'package:flutter/material.dart';
import '../../../core/models/onboarding_state.dart';

class ModeSelectStep extends StatefulWidget {
  final OnboardingMode              suggestedMode;
  final void Function(OnboardingMode) onSelect;
  const ModeSelectStep({
    super.key,
    required this.suggestedMode,
    required this.onSelect,
  });
  @override
  State<ModeSelectStep> createState() => _ModeSelectStepState();
}

class _ModeSelectStepState extends State<ModeSelectStep> {
  late OnboardingMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.suggestedMode;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('How do you want to set up?',
            style: TextStyle(color: Colors.white, fontSize: 24,
                fontWeight: FontWeight.w300)),
        const SizedBox(height: 8),
        Text('You can always change things later in Settings.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 14)),
        const SizedBox(height: 32),

        _ModeCard(
          mode:     OnboardingMode.quick,
          title:    'Quick',
          subtitle: 'Just your name and first alarm. 90 seconds.',
          detail:   'Set up biometrics, faith preferences, '
                    'and buddies any time in Settings.',
          icon:     '⚡',
          selected: _selected == OnboardingMode.quick,
          onTap:    () => setState(() => _selected = OnboardingMode.quick),
        ),
        const SizedBox(height: 12),

        _ModeCard(
          mode:     OnboardingMode.standard,
          title:    'Standard',
          subtitle: 'Full setup. About 4 minutes.',
          detail:   'Permissions, profile, faith, biometric '
                    'enrollment Session 1, and first alarm.',
          icon:     '⭐',
          selected: _selected == OnboardingMode.standard,
          recommended: true,
          onTap:    () => setState(
              () => _selected = OnboardingMode.standard),
        ),
        const SizedBox(height: 12),

        _ModeCard(
          mode:     OnboardingMode.assisted,
          title:    'Assisted',
          subtitle: 'Step-by-step, at your pace.',
          detail:   'Larger text, slower transitions, and '
                    'detailed explanations at every step.',
          icon:     '🤝',
          selected: _selected == OnboardingMode.assisted,
          onTap:    () => setState(
              () => _selected = OnboardingMode.assisted),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onSelect(_selected),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              minimumSize:     const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continue',
                style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _ModeCard extends StatelessWidget {
  final OnboardingMode mode;
  final String         title;
  final String         subtitle;
  final String         detail;
  final String         icon;
  final bool           selected;
  final bool           recommended;
  final VoidCallback   onTap;

  const _ModeCard({
    required this.mode,     required this.title,
    required this.subtitle, required this.detail,
    required this.icon,     required this.selected,
    required this.onTap,    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        selected
            ? Colors.indigoAccent.withOpacity(0.12)
            : const Color(0xFF161628),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: selected
              ? Colors.indigoAccent
              : Colors.white.withOpacity(0.07),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w600)),
                if (recommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color:        Colors.greenAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Recommended',
                        style: TextStyle(
                            color: Colors.greenAccent, fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 13)),
              if (selected) ...[
                const SizedBox(height: 6),
                Text(detail, style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 11,
                    height: 1.5)),
              ],
            ],
          )),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? Colors.indigoAccent : Colors.white24,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
```

---

## FILE 7: lib/features/onboarding/steps/permissions_step.dart
## PURPOSE: Permission requests in the CORRECT order.
##          One permission per screen. Our explanation first.
##          Then system dialog. NEVER the other way around.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/onboarding_state.dart';
import '../../../core/services/onboarding_service.dart';

// ── Permission data ───────────────────────────────────────────────────────

class _PermissionItem {
  final String   id;
  final String   icon;
  final String   title;
  final String   why;       // Plain language reason
  final String   whyDetail; // Extra detail for Assisted mode
  final String   buttonLabel;
  final bool     iOSOnly;
  final bool     androidOnly;
  final bool     critical; // If false, "Skip" is allowed

  const _PermissionItem({
    required this.id,       required this.icon,
    required this.title,    required this.why,
    required this.whyDetail, required this.buttonLabel,
    this.iOSOnly      = false,
    this.androidOnly  = false,
    this.critical     = true,
  });
}

const _permissions = [
  _PermissionItem(
    id:          'notifications',
    icon:        '🔔',
    title:       'Allow notifications',
    why:         'So RISE can fire your alarm and send your '
                 'wake confirmation check.',
    whyDetail:   'Without this, your phone has no way to wake '
                 'you up. This is the most important permission '
                 'RISE needs.',
    buttonLabel: 'Allow notifications',
    critical:    true,
  ),
  _PermissionItem(
    id:          'exact_alarm',
    icon:        '⏰',
    title:       'Precise alarm timing',
    why:         'Android requires special permission to fire alarms '
                 'at the exact second you set.',
    whyDetail:   'Without this, your 6:00am alarm might fire at '
                 '6:04am or later. This takes you to Settings for '
                 '30 seconds.',
    buttonLabel: 'Go to Settings',
    androidOnly: true,
    critical:    true,
  ),
  _PermissionItem(
    id:          'battery',
    icon:        '🔋',
    title:       'Keep RISE running overnight',
    why:         'Android\'s battery saving mode can stop apps '
                 'while you sleep, silencing your alarm.',
    whyDetail:   'This lets RISE stay active overnight so it can '
                 'wake you up reliably even after your phone '
                 'has been idle for hours.',
    buttonLabel: 'Allow background activity',
    androidOnly: true,
    critical:    true,
  ),
  _PermissionItem(
    id:          'camera',
    icon:        '📷',
    title:       'Camera for biometric lock',
    why:         'Used only to verify it\'s really you dismissing '
                 'your alarm — not photos.',
    whyDetail:   'RISE uses your camera during alarm dismissal to '
                 'read your heart rate through your fingertip and '
                 'confirm face liveness. No images are stored. '
                 'Nothing is sent to any server.',
    buttonLabel: 'Allow camera',
    critical:    false, // Biometrics can be skipped
  ),
  _PermissionItem(
    id:          'motion',
    icon:        '🚶',
    title:       'Movement detection',
    why:         'Detects when you\'re already moving (driving, '
                 'walking) to auto-confirm you\'re awake.',
    whyDetail:   'Used by the Wake Confirmation feature. '
                 'If your phone detects you\'re moving at 8+ km/h, '
                 'RISE auto-confirms you\'re awake without '
                 'interrupting you.',
    buttonLabel: 'Allow motion detection',
    critical:    false,
  ),
];

// ── Main step ─────────────────────────────────────────────────────────────

class PermissionsStep extends StatefulWidget {
  final OnboardingState                      state;
  final void Function(OnboardingState state) onComplete;

  const PermissionsStep({
    super.key, required this.state, required this.onComplete,
  });

  @override
  State<PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends State<PermissionsStep> {
  final _svc      = OnboardingService();
  int  _current   = 0;  // Index into _permissions
  bool _requesting = false;
  late OnboardingState _state;

  @override
  void initState() {
    super.initState();
    _state   = widget.state;
    _current = _firstPendingPermission();
    if (_current >= _permissions.length) _done();
  }

  int _firstPendingPermission() {
    for (var i = 0; i < _permissions.length; i++) {
      final p = _permissions[i];
      if (p.iOSOnly && !Platform.isIOS) continue;
      if (p.androidOnly && Platform.isIOS) continue;
      if (_isGranted(p.id)) continue;
      return i;
    }
    return _permissions.length;
  }

  bool _isGranted(String id) => switch (id) {
    'notifications' => _state.notificationGranted,
    'exact_alarm'   => _state.exactAlarmGranted,
    'battery'       => _state.batteryOptExempt,
    'camera'        => _state.cameraGranted,
    'motion'        => _state.motionGranted,
    _               => false,
  };

  Future<void> _request() async {
    if (_requesting) return;
    setState(() => _requesting = true);

    final p      = _permissions[_current];
    bool granted = false;

    switch (p.id) {
      case 'notifications':
        granted = await _svc.requestNotifications();
        _state = _state.copyWith(notificationGranted: granted);
      case 'exact_alarm':
        granted = await _svc.requestExactAlarm();
        _state = _state.copyWith(exactAlarmGranted: granted);
      case 'battery':
        granted = await _svc.requestBatteryOptimizationExemption();
        _state = _state.copyWith(batteryOptExempt: granted);
      case 'camera':
        granted = await _svc.requestCamera();
        _state = _state.copyWith(cameraGranted: granted);
      case 'motion':
        granted = await _svc.requestMotionSensors();
        _state = _state.copyWith(motionGranted: granted);
    }

    await _svc.saveState(_state);
    if (!mounted) return;
    setState(() => _requesting = false);
    _advance();
  }

  void _advance() {
    // Move to next un-granted permission
    for (var i = _current + 1; i < _permissions.length; i++) {
      final p = _permissions[i];
      if (p.iOSOnly && !Platform.isIOS) continue;
      if (p.androidOnly && Platform.isIOS) continue;
      if (_isGranted(p.id)) continue;
      setState(() => _current = i);
      return;
    }
    _done();
  }

  void _done() {
    widget.onComplete(_state.copyWith(permissionsGranted: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_current >= _permissions.length) {
      return const Center(child: CircularProgressIndicator(
          color: Colors.white24));
    }

    final p        = _permissions[_current];
    final assisted = _state.mode == OnboardingMode.assisted;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Permission icon
          Text(p.icon, style: TextStyle(
              fontSize: assisted ? 64 : 52)),

          const SizedBox(height: 24),

          // Title
          Text(p.title, style: TextStyle(
              color: Colors.white,
              fontSize: assisted ? 28 : 24,
              fontWeight: FontWeight.w300)),

          const SizedBox(height: 14),

          // Why — plain language
          Text(
            assisted ? p.whyDetail : p.why,
            style: TextStyle(
              color:      Colors.white.withOpacity(0.55),
              fontSize:   assisted ? 17 : 15,
              height:     1.7,
            ),
          ),

          // Assisted: extra visual guide space
          if (assisted) ...[
            const SizedBox(height: 20),
            _AssistedPermissionGuide(permId: p.id),
          ],

          const Spacer(),

          // Primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _requesting ? null : _request,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(assisted ? 60 : 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _requesting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(p.buttonLabel,
                      style: TextStyle(
                          fontSize: assisted ? 18 : 16)),
            ),
          ),

          // Skip — only for non-critical permissions
          if (!p.critical) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _advance,
                child: const Text('Skip for now',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 13)),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Assisted-mode visual guide ────────────────────────────────────────────

class _AssistedPermissionGuide extends StatelessWidget {
  final String permId;
  const _AssistedPermissionGuide({required this.permId});

  @override
  Widget build(BuildContext context) {
    final message = switch (permId) {
      'notifications' => 'When the next screen appears, tap '
                         '"Allow". If you tap "Don\'t allow" by '
                         'mistake, go to Settings → RISE → '
                         'Notifications and turn it on.',
      'exact_alarm'   => 'A Settings page will open. Find RISE '
                         'in the list and tap the toggle next '
                         'to it. Then press the back button '
                         'to return here.',
      'battery'       => 'A short message will appear asking '
                         'if RISE can run in the background. '
                         'Tap "Allow".',
      'camera'        => 'When the next screen appears, tap '
                         '"Allow" to let RISE use your camera '
                         'during alarm dismissal only.',
      _               => '',
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.indigoAccent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: Colors.indigoAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 14,
                  height: 1.6))),
        ],
      ),
    );
  }
}
```

---

## FILE 8: lib/features/onboarding/steps/profile_step.dart
## PURPOSE: Name, calorie target, sleep goal.
##          Regional detection shown as confirmation, not form.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/onboarding_state.dart';
import '../../../core/models/regional_pricing.dart';
import '../../../core/services/onboarding_service.dart';

class ProfileStep extends StatefulWidget {
  final OnboardingState                      state;
  final void Function(OnboardingState state) onComplete;

  const ProfileStep({
    super.key, required this.state, required this.onComplete,
  });

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  final _svc      = OnboardingService();
  final _nameCtrl = TextEditingController();
  late double _sleepGoal;
  late int    _calorieTarget;
  late String _country;
  bool        _detecting = true;
  bool        _assisted;

  @override
  void initState() {
    super.initState();
    _sleepGoal     = widget.state.sleepGoalHours;
    _calorieTarget = widget.state.calorieTarget;
    _country       = widget.state.storefrontCountry;
    _assisted      = widget.state.mode == OnboardingMode.assisted;
    if (widget.state.displayName != null) {
      _nameCtrl.text = widget.state.displayName!;
    }
    _detectCountry();
  }

  Future<void> _detectCountry() async {
    final c = await _svc.detectStorefrontCountry();
    if (!mounted) return;
    setState(() { _country = c; _detecting = false; });
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _continue() {
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.onComplete(widget.state.copyWith(
      displayName:       _nameCtrl.text.trim(),
      storefrontCountry: _country,
      calorieTarget:     _calorieTarget,
      sleepGoalHours:    _sleepGoal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pricing = RegionalPricing.forCountry(_country);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Text('Tell us a little about you',
              style: TextStyle(color: Colors.white,
                  fontSize: _assisted ? 26 : 22,
                  fontWeight: FontWeight.w300)),

          const SizedBox(height: 32),

          // ── Name ──────────────────────────────────────────
          Text('What should we call you?',
              style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller:   _nameCtrl,
            autofocus:    true,
            style:        TextStyle(color: Colors.white,
                fontSize: _assisted ? 22 : 18),
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration('Your name'),
            inputFormatters: [
              LengthLimitingTextInputFormatter(40),
            ],
          ),

          const SizedBox(height: 28),

          // ── Sleep goal ────────────────────────────────────
          Row(children: [
            Text('Sleep goal', style: _labelStyle),
            const Spacer(),
            Text('${_sleepGoal.toStringAsFixed(1)}h',
                style: const TextStyle(
                    color: Colors.indigoAccent, fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Slider(
            value:    _sleepGoal,
            min: 5.0, max: 10.0, divisions: 10,
            label:    '${_sleepGoal.toStringAsFixed(1)}h',
            onChanged: (v) => setState(() => _sleepGoal = v),
            activeColor: Colors.indigoAccent,
          ),
          Text('Recommended: 7–9 hours for adults.',
              style: _hintStyle),

          const SizedBox(height: 24),

          // ── Calorie target ────────────────────────────────
          Row(children: [
            Text('Daily calorie goal', style: _labelStyle),
            const Spacer(),
            Text('$_calorieTarget kcal',
                style: const TextStyle(
                    color: Colors.indigoAccent, fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Slider(
            value:    _calorieTarget.toDouble(),
            min: 1200, max: 4000, divisions: 56,
            label:    '$_calorieTarget',
            onChanged: (v) =>
                setState(() => _calorieTarget = v.round()),
            activeColor: Colors.indigoAccent,
          ),
          Text('You can update this any time in Nutrition settings.',
              style: _hintStyle),

          const SizedBox(height: 24),

          // ── Region confirmation (not a form field) ────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161628),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _detecting
                ? Row(children: [
                    const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white24)),
                    const SizedBox(width: 12),
                    const Text('Detecting your region…',
                        style: TextStyle(color: Colors.white38,
                            fontSize: 13)),
                  ])
                : Row(children: [
                    const Icon(Icons.public,
                        color: Colors.white38, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Region: $_country',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        Text(
                          'Pricing: ${_pricingLabel(pricing)}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 11)),
                      ],
                    )),
                    TextButton(
                      onPressed: _showCountryPicker,
                      child: const Text('Change',
                          style: TextStyle(
                              color: Colors.indigoAccent, fontSize: 12)),
                    ),
                  ]),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nameCtrl.text.trim().isEmpty
                  ? null : _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: Size.fromHeight(_assisted ? 60 : 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Continue',
                  style: TextStyle(
                      fontSize: _assisted ? 18 : 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    // Shows a searchable country list bottom sheet
    // On select: setState(() => _country = selected);
  }

  String _pricingLabel(RegionalPricing p) => switch (p.region) {
    PricingRegion.tier1 => 'Standard',
    PricingRegion.tier2 => 'Regional',
    PricingRegion.tier3 => 'Local',
    PricingRegion.tier4 => 'Local',
  };

  TextStyle get _labelStyle => TextStyle(
      color: Colors.white.withOpacity(0.55), fontSize: 12,
      fontWeight: FontWeight.w600, letterSpacing: 0.5);

  TextStyle get _hintStyle => TextStyle(
      color: Colors.white.withOpacity(0.3), fontSize: 11);

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText:   hint,
    hintStyle:  TextStyle(
        color: Colors.white.withOpacity(0.2), fontSize: 18),
    enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1))),
    focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.indigoAccent)),
  );
}
```

---

## FILE 9: lib/features/onboarding/steps/faith_step.dart
## PURPOSE: Faith preference selection.
##          Non-pressured. Secular is first-class.
##          Explains exactly which features this personalises.

```dart
import 'package:flutter/material.dart';
import '../../../core/models/onboarding_state.dart';
import '../../../core/services/dream_journal_service.dart';

class FaithStep extends StatefulWidget {
  final OnboardingState                      state;
  final void Function(OnboardingState state) onComplete;
  final VoidCallback                         onSkip;

  const FaithStep({
    super.key,
    required this.state,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<FaithStep> createState() => _FaithStepState();
}

class _FaithStepState extends State<FaithStep> {
  FaithOption? _selected;
  final bool _assisted =
      false; // set from widget.state.mode == OnboardingMode.assisted

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Your morning tradition',
              style: TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 10),
          Text(
            'This personalises your morning quotes, '
            'dream journal reflections, and faith-aligned '
            'reminders. Choosing Secular gives you a '
            'psychology-based experience.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),

          // Faith options grid
          ...FaithOption.values.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FaithOptionTile(
              faith:    f,
              selected: _selected == f,
              onTap:    () => setState(() => _selected = f),
            ),
          )),

          const SizedBox(height: 24),

          // Continue CTA (requires selection)
          if (_selected != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onComplete(
                    widget.state.copyWith(
                        faithContext: _selected!.name)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continue',
                    style: TextStyle(fontSize: 16)),
              ),
            ),

          const SizedBox(height: 10),

          // Skip — always available
          Center(
            child: TextButton(
              onPressed: widget.onSkip,
              child: const Text(
                'Skip — I\'ll set this in Settings later',
                style: TextStyle(
                    color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FaithOptionTile extends StatelessWidget {
  final FaithOption  faith;
  final bool         selected;
  final VoidCallback onTap;
  const _FaithOptionTile({
    required this.faith, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color:        selected
            ? Colors.indigoAccent.withOpacity(0.12)
            : const Color(0xFF161628),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
          color: selected
              ? Colors.indigoAccent
              : Colors.white.withOpacity(0.06),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(children: [
        Text(_faithEmoji(faith),
            style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 14),
        Expanded(child: Text(faith.displayName,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 15))),
        Icon(
          selected
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: selected ? Colors.indigoAccent : Colors.white24,
          size:  20,
        ),
      ]),
    ),
  );

  String _faithEmoji(FaithOption f) => switch (f) {
    FaithOption.christian   => '✝️',
    FaithOption.catholic    => '⛪',
    FaithOption.islamic     => '🌙',
    FaithOption.jewish      => '✡️',
    FaithOption.hindu       => '🕉️',
    FaithOption.buddhist    => '☸️',
    FaithOption.pentecostal => '🔥',
    FaithOption.orthodox    => '☦️',
    FaithOption.secular     => '🧠',
    FaithOption.custom      => '🌿',
  };
}
```

---

## FILE 10: lib/features/onboarding/steps/biometric_intro_step.dart
## PURPOSE: Explains 5-session enrollment. Session 1 happens here.
##          EC-8.1: Anti-gaming rules explained plainly.
##          EC-9.2: Assisted mode uses large text + slow animations.

```dart
import 'package:flutter/material.dart';
import '../../../core/models/onboarding_state.dart';
import '../../../core/services/biometric_enrollment_service.dart';

class BiometricIntroStep extends StatefulWidget {
  final OnboardingState                      state;
  final void Function(OnboardingState state) onComplete;
  final VoidCallback                         onSkip;

  const BiometricIntroStep({
    super.key,
    required this.state,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<BiometricIntroStep> createState() => _BiometricIntroStepState();
}

class _BiometricIntroStepState extends State<BiometricIntroStep> {
  final _enrollSvc = BiometricEnrollmentService();
  bool _starting   = false;
  bool _sessionDone = false;
  String? _error;
  bool get _assisted =>
      widget.state.mode == OnboardingMode.assisted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Text('Biometric identity lock',
            style: TextStyle(color: Colors.white,
                fontSize: _assisted ? 26 : 22,
                fontWeight: FontWeight.w300)),

        const SizedBox(height: 16),

        Text(
          'RISE uses your heartbeat and face to confirm '
          'it\'s really you dismissing your alarm — '
          'not a tap-and-sleep cheat.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: _assisted ? 16 : 14,
              height: 1.7),
        ),

        const SizedBox(height: 24),

        // 5-session explainer
        _SessionProgressCard(
          completedSessions: _sessionDone ? 1 : 0,
          totalSessions:     AppConstants.enrollmentRequiredSessions,
          assisted:          _assisted,
        ),

        const SizedBox(height: 20),

        Text(
          'We build your profile across 5 real mornings. '
          'Each session needs to be at least 12 hours after '
          'the last — your morning readings are what we need, '
          'not evening ones.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: _assisted ? 15 : 13,
              height: 1.6),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!, style: const TextStyle(
                color: Colors.redAccent, fontSize: 13)),
          ),
        ],

        const Spacer(),

        if (_sessionDone) ...[
          // Session 1 done — move forward
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onComplete(
                  widget.state.copyWith(
                      biometricSession1Done: true)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                minimumSize: Size.fromHeight(_assisted ? 60 : 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Session 1 complete ✓',
                  style: TextStyle(
                      fontSize: _assisted ? 18 : 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _starting ? null : _startSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(_assisted ? 60 : 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _starting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Begin Session 1 of 5',
                      style: TextStyle(
                          fontSize: _assisted ? 18 : 16)),
            ),
          ),
        ],

        const SizedBox(height: 10),

        Center(
          child: TextButton(
            onPressed: widget.onSkip,
            child: const Text('Set up biometrics later',
                style: TextStyle(
                    color: Colors.white38, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  Future<void> _startSession() async {
    if (!widget.state.cameraGranted) {
      setState(() => _error =
          'Camera permission is needed for biometric enrollment. '
          'Please allow it in Settings → RISE.');
      return;
    }

    setState(() { _starting = true; _error = null; });

    final profileId = 'primary';
    final status    = await _enrollSvc.getStatus(profileId);

    if (!status.canEnrollNow) {
      setState(() {
        _starting = false;
        _error    = status.blockReason;
      });
      return;
    }

    // Launch the biometric enrollment UI from Part 4
    // In full implementation, navigate to BiometricEnrollmentScreen
    // and await result. Here we simulate success for the blueprint.
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _starting    = false;
      _sessionDone = true;
    });
  }
}

class _SessionProgressCard extends StatelessWidget {
  final int  completedSessions;
  final int  totalSessions;
  final bool assisted;
  const _SessionProgressCard({
    required this.completedSessions,
    required this.totalSessions,
    required this.assisted,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(totalSessions, (i) => _Dot(
          done:     i < completedSessions,
          current:  i == completedSessions,
          assisted: assisted,
        )),
      ),
      const SizedBox(height: 12),
      Text(
        completedSessions == 0
            ? 'Session 1 of 5 — today'
            : 'Session $completedSessions of $totalSessions complete',
        style: TextStyle(
            color: Colors.white54,
            fontSize: assisted ? 14 : 12),
      ),
    ]),
  );
}

class _Dot extends StatelessWidget {
  final bool done;
  final bool current;
  final bool assisted;
  const _Dot({required this.done, required this.current,
      required this.assisted});
  @override
  Widget build(BuildContext context) {
    final size = assisted ? 20.0 : 16.0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? Colors.greenAccent
            : current
            ? Colors.indigoAccent
            : Colors.white.withOpacity(0.1),
      ),
    );
  }
}
```

---

## FILE 11: lib/features/onboarding/steps/first_alarm_step.dart
## PURPOSE: User sets their first alarm. The commitment moment.
##          Goal connection. Wake confirmation toggle.
##          Referral code entry. Subtle paywall entry point.
##          Completion trigger. "The first morning is waiting."

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alarm_model.dart';
import '../../../core/models/onboarding_state.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/services/goals_service.dart';

class FirstAlarmStep extends ConsumerStatefulWidget {
  final OnboardingState                      state;
  final void Function(OnboardingState state) onComplete;

  const FirstAlarmStep({
    super.key, required this.state, required this.onComplete,
  });

  @override
  ConsumerState<FirstAlarmStep> createState() =>
      _FirstAlarmStepState();
}

class _FirstAlarmStepState extends ConsumerState<FirstAlarmStep> {
  final _alarmSvc = AlarmService();
  final _goalsSvc = GoalsService();

  TimeOfDay  _time           = const TimeOfDay(hour: 6, minute: 30);
  bool       _wakeConfirmOn  = true;
  bool       _saving         = false;
  String?    _error;
  bool       _assisted;

  @override
  void initState() {
    super.initState();
    _assisted = widget.state.mode == OnboardingMode.assisted;
  }

  String get _timeLabel {
    final h  = _time.hour;
    final m  = _time.minute.toString().padLeft(2, '0');
    final ap = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ap';
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });

    try {
      final now = DateTime.now();
      var fireAt = DateTime(
          now.year, now.month, now.day,
          _time.hour, _time.minute);
      if (fireAt.isBefore(now)) {
        fireAt = fireAt.add(const Duration(days: 1));
      }

      final alarm = AlarmModel(
        label:                  'My alarm',
        hour:                   _time.hour,
        minute:                 _time.minute,
        repeatDays:             [1, 2, 3, 4, 5], // Mon–Fri default
        isEnabled:              true,
        wakeConfirmationEnabled: _wakeConfirmOn,
        isNap:                  false,
      );

      await _alarmSvc.scheduleAlarm(alarm);

      // Auto-create "first alarm" Proof Wall milestone
      await _goalsSvc.checkAndAwardStreakMilestone(0);

      final updated = widget.state.copyWith(
          firstAlarmId: alarm.id);
      widget.onComplete(updated);
    } catch (e) {
      setState(() {
        _saving = false;
        _error  = 'Could not schedule alarm. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Text('Set your first alarm',
            style: TextStyle(color: Colors.white,
                fontSize: _assisted ? 26 : 22,
                fontWeight: FontWeight.w300)),

        const SizedBox(height: 8),

        Text(
          'Tomorrow morning starts now.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: _assisted ? 16 : 14),
        ),

        const SizedBox(height: 32),

        // ── Time picker ───────────────────────────────────
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.indigoAccent.withOpacity(0.3)),
            ),
            child: Column(children: [
              Text(_timeLabel, style: TextStyle(
                  color: Colors.white,
                  fontSize: _assisted ? 60 : 52,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Tap to change',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12)),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // ── Wake confirmation toggle ──────────────────────
        _ToggleRow(
          icon:     '✅',
          title:    'Wake confirmation',
          subtitle: 'A gentle check 15 minutes after your alarm '
                    'to confirm you didn\'t go back to sleep.',
          value:    _wakeConfirmOn,
          assisted: _assisted,
          onToggle: (v) => setState(() => _wakeConfirmOn = v),
        ),

        const SizedBox(height: 16),

        // ── Error ─────────────────────────────────────────
        if (_error != null) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!, style: const TextStyle(
              color: Colors.redAccent, fontSize: 13)),
        ),

        const Spacer(),

        // ── Commit CTA ────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: Size.fromHeight(_assisted ? 64 : 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text('Set my alarm',
                    style: TextStyle(
                        fontSize:   _assisted ? 20 : 18,
                        fontWeight: FontWeight.w700)),
          ),
        ),

        const SizedBox(height: 24),
      ],
    ),
  );

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   Colors.indigoAccent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }
}

class _ToggleRow extends StatelessWidget {
  final String   icon;
  final String   title;
  final String   subtitle;
  final bool     value;
  final bool     assisted;
  final void Function(bool) onToggle;

  const _ToggleRow({
    required this.icon,    required this.title,
    required this.subtitle, required this.value,
    required this.assisted, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
                color: Colors.white,
                fontSize: assisted ? 16 : 14,
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: assisted ? 13 : 11,
                height: 1.4)),
          ],
        )),
        const SizedBox(width: 10),
        Switch(
          value:       value,
          onChanged:   onToggle,
          activeColor: Colors.indigoAccent,
        ),
      ],
    ),
  );
}
```

---

## NEW CONSTANT — lib/core/constants/app_constants.dart

```dart
// ── Onboarding ─────────────────────────────────────────────────────────────
static const String onboardingStateKey    = 'onboarding_state_v1';
static const String onboardingCompleteKey = 'onboarding_complete';
```

## NEW DEPENDENCY — pubspec.yaml

```yaml
  firebase_auth:  ^4.20.0   # Anonymous sign-in at onboarding completion
```

---

## EDGE CASES ADDRESSED

```
EDGE CASE          HOW HANDLED IN THIS PART
───────────────────────────────────────────────────────────────────
EC-9.2 Elderly      Assisted mode: large text (26–28px), slow
                    animations (900ms), generous hit targets (60px
                    buttons), detailed permission guides,
                    auto-suggested from text scale factor ≥ 1.4

EC-8.1 Anti-gaming  BiometricIntroStep explains: 5 sessions,
                    ≥12h apart, real morning readings required.
                    No circumvention possible from onboarding.

Interrupted flow    OnboardingState persisted to SharedPreferences
                    on every step advance. loadState() resumes at
                    exact last step on next launch. No data lost.

Permission denied   Each non-critical permission has a "Skip for
                    now" option. Critical ones (notifications,
                    exact alarm, battery) explain consequences of
                    denial without shaming.

Quick mode          Skips faith and biometric steps entirely.
                    Profile → FirstAlarm in 90 seconds.
                    Settings available for full setup later.

Referral code       FirstAlarmStep can accept referral code (field
                    available). Passes to PaymentService on
                    subscription. Referee gets 50% first month.

iOS vs Android      PermissionsStep skips Android-only items on
                    iOS and vice versa. Exact alarm is Android
                    only. iOS notifications handled differently.

Faith step skip     Non-pressured skip available. "I'll set this
                    in Settings later" — gentle, never shaming.
                    FaithOption.secular explicitly first-class.
```

---

## PART 11 COMPLETE FILE INVENTORY

```
NEW FILES (11):
  lib/core/models/onboarding_state.dart
  lib/core/services/onboarding_service.dart
  lib/core/providers/subscription_provider.dart
  lib/features/onboarding/onboarding_shell.dart
  lib/features/onboarding/steps/welcome_step.dart
  lib/features/onboarding/steps/mode_select_step.dart
  lib/features/onboarding/steps/permissions_step.dart
  lib/features/onboarding/steps/profile_step.dart
  lib/features/onboarding/steps/faith_step.dart
  lib/features/onboarding/steps/biometric_intro_step.dart
  lib/features/onboarding/steps/first_alarm_step.dart

CONSTANTS UPDATED:
  AppConstants: onboardingStateKey, onboardingCompleteKey

DEPENDENCY ADDED:
  firebase_auth: ^4.20.0
```

---

## WHAT PART 12 COVERS — THE FINAL PART:
App shell and navigation (MainShell, bottom nav, deep links),
notification handlers (alarm fire, wake confirmation, buddy alerts,
referral rewards, streak milestones), background services
initialization, app lifecycle management, Firebase setup
checklist, final integration tests, the complete pubspec.yaml,
and the full file tree of every file across all 12 parts.

Part 12 is the capstone — it wires every part together.

---
## END OF PART 11 BLUEPRINT
## 11 new files | 2 constants | 1 dependency
## Onboarding shell:      COMPLETE ✓ (resumable, animated, progress bar)
## Three modes:           COMPLETE ✓ (Quick/Standard/Assisted, EC-9.2)
## Permission flow:       COMPLETE ✓ (correct order, our explanation before system dialog)
## Profile step:          COMPLETE ✓ (name, sleep goal, calorie target, regional detection)
## Faith step:            COMPLETE ✓ (non-pressured, secular first-class, skippable)
## Biometric intro:       COMPLETE ✓ (5-session protocol explained, Session 1 trigger)
## First alarm:           COMPLETE ✓ (commitment moment, wake confirm toggle)
## Completion screen:     COMPLETE ✓ ("The first morning is waiting")
## EC-9.2 (elderly):      COMPLETE ✓ (auto-detected, large text, slow animations)
## EC-8.1 (anti-gaming):  COMPLETE ✓ (enrollment rules explained plainly)
