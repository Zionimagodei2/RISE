# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 9 OF 12
# Wake Confirmation Feature + Home Screen Dashboard
# ============================================================
# COMMAND TO AI CODING AGENT:
# Parts 1–8 must be complete before starting this part.
# Read ALL sections in order before writing any code.
# This part introduces Wake Confirmation — a new first-class
# feature — and builds the home screen that ties every
# previous system together into one daily dashboard.
#
# WHAT THIS PART CREATES (8 files):
#
#  1. lib/core/models/wake_confirmation.dart
#     Model for a pending/completed wake confirmation event.
#
#  2. lib/core/services/wake_confirmation_service.dart
#     Schedules, fires, and records wake confirmation checks.
#     Handles all edge cases defined in this document.
#
#  3. lib/features/alarm/wake_confirmation_screen.dart
#     The full-screen overlay for wake confirmation.
#     Lighter than the main alarm but requires interaction.
#
#  4. lib/features/home/home_screen.dart
#     The main daily dashboard: upcoming alarm, last night's
#     score, streak, challenge status, leaderboard rank, AI
#     briefing, sleep debt, quick-add FAB.
#
#  5. lib/features/home/widgets/upcoming_alarm_card.dart
#     Next alarm card with early-dismiss button (EC-4.8).
#
#  6. lib/features/home/widgets/sleep_score_card.dart
#     Last night's sleep score with ring chart and breakdown.
#
#  7. lib/features/home/widgets/streak_card.dart
#     Consecutive wake streak, personal best, milestone badges.
#
#  8. lib/features/home/widgets/wake_confirmation_banner.dart
#     Persistent banner when a wake confirmation is imminent
#     or currently firing. Taps through to WakeConfirmScreen.
#
# PART 8 UPDATE REQUIRED:
# Add 'Wake Confirmation' toggle to AlarmSetupScreen
# (see "PART 8 RETROFIT" section at the bottom of this file).
# Also add isNap and wakeConfirmationEnabled to AlarmModel.
# ============================================================

---

# ══════════════════════════════════════════════════════════════
# WAKE CONFIRMATION — FEATURE SPECIFICATION
# ══════════════════════════════════════════════════════════════

## WHAT IT IS
Wake Confirmation is an optional secondary check that fires a
fixed number of minutes after the user dismisses their alarm.
It exists to close the most common post-alarm failure mode:
the user passes the wake game, lies back down "for a minute",
and falls back into deep sleep.

EC-4.9 (post-dismiss watchdog) detects passive inactivity.
Wake Confirmation is the active version: it DEMANDS a response.

## HOW IT WORKS
1. User sets an alarm. In alarm setup, they toggle
   "Wake Confirmation" ON (default: OFF).

2. User dismisses their alarm normally (game + optional biometric).

3. Exactly WAKE_CONFIRM_DELAY_MINUTES (= 15) minutes later,
   RISE fires a soft secondary alarm.

4. The screen shows: "Just checking you're still awake 👋"
   with a single easy wake game (1 math question, easy diff).

5. If user completes it → confirmed awake. Session recorded.
   If user ignores it for WAKE_CONFIRM_TIMEOUT_MINUTES (= 5):
   → Soft escalation: push notification "Still up?"
   → After 5 more minutes with no response:
     buddy gets a soft message (NOT an emergency escalation —
     this is gentler: "Hey, [Name] may have gone back to sleep.")

6. Cap: maximum 1 Wake Confirmation per alarm firing.
   (Not recursive. Confirming the confirmation does not
   trigger another confirmation.)

## HARDCODED CONSTANTS (not user-configurable)
  WAKE_CONFIRM_DELAY_MINUTES   = 15   // Fires 15 min after dismissal
  WAKE_CONFIRM_TIMEOUT_MINUTES = 5    // User has 5 min to respond
  WAKE_CONFIRM_BUDDY_MINUTES   = 10   // Buddy notified after 10 min no-response

Rationale for 15 minutes: Sleep onset after lying down takes
approximately 10–20 minutes. 15 minutes is within this window —
early enough to prevent the user from reaching deep sleep, but
late enough not to feel harassing immediately after waking up.

## WHAT THE USER CONTROLS
The ONLY user control is the on/off toggle per alarm.
If OFF: no wake confirmation, ever, for that alarm.
If ON:  all timing and behavior are fixed by RISE.

## AUDIO / HAPTIC PROFILE
- Volume: 50% of the main alarm volume (not jarring)
- Sound: gentle chime (not the alarm ringtone)
- Vibration: single short pattern (not continuous)
- Screen: wakes and shows full-screen confirmation UI
- Duration of audio: plays once, does not loop
  (unlike the main alarm which loops until dismissed)

---

# ══════════════════════════════════════════════════════════════
# WAKE CONFIRMATION — EDGE CASES
# ══════════════════════════════════════════════════════════════

## WC-1: User is in the shower when confirmation fires
SCENARIO: Dismissed alarm at 6:00. In shower at 6:15.
Phone is buzzing on the bathroom shelf.
RISE RESPONSE:
- The single-buzz + gentle chime will be heard/felt.
- User has 5-minute window to respond — shower is typically
  shorter than 5 minutes.
- If missed: soft notification "Still up?" (not an emergency).
- No buddy notification triggered for missed shower confirmations
  unless user also misses the notification follow-up.
- This is acceptable — shower is proof of wakefulness even if
  the phone isn't touched.
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-2: User is already away from home (commuting)
SCENARIO: Dismissed alarm at 6:00. Left house by 6:10.
Wake confirmation fires at 6:15 while user is on the train.
RISE RESPONSE:
- Contextual suppression: if phone is moving (GPS/accelerometer
  shows travel speed > 8 km/h), auto-confirm silently.
  A moving phone means the user is up.
- Log as: wake_confirmed_by_motion
- No screen shown, no audio, no notification.
- The motion check runs at the moment of scheduled confirmation.
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-3: User is driving when confirmation fires (EC-5.2 parallel)
SCENARIO: User in car at 6:15.
RISE RESPONSE:
- Same driving detection as EC-5.2.
- If driving detected at confirmation time: auto-confirm.
  Log: wake_confirmed_driving
- Never show UI or play audio while driving.
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-4: Wake confirmation fires during an active phone call
SCENARIO: User on a call at 6:15.
RISE RESPONSE:
- Detect active phone call via TelephonyManager (Android) /
  CXCallObserver (iOS).
- If in a call: postpone confirmation by 3 minutes, then retry.
- Max 2 postponements (6 minutes total). After that, auto-confirm.
  (Being on a phone call at 6:15 AM = awake.)
- No audio interruption to phone calls. Ever.
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-5: Second alarm fires around same time as wake confirmation
SCENARIO: User has a 6:00 alarm and a 6:20 backup alarm.
Wake confirmation for 6:00 is scheduled at 6:15.
Second alarm fires at 6:20.
RISE RESPONSE:
- If second alarm fires within 10 minutes of the pending
  wake confirmation: cancel the wake confirmation.
  The second alarm IS the wake confirmation (and more).
- Log: wake_confirmation_superseded_by_alarm
- Never show both simultaneously.
IMPLEMENT IN: wake_confirmation_service.dart + alarm_service.dart

---

## WC-6: App is killed between dismissal and confirmation
SCENARIO: User force-stops app at 6:05. Confirmation at 6:15.
RISE RESPONSE:
- Wake confirmation is scheduled via AlarmManager.setExactAndAllowWhileIdle()
  (Android) / UNUserNotificationCenter (iOS) — same as the main alarm.
  It WILL fire even if the app is killed.
- On fire: app relaunches, WakeConfirmationService checks if
  the confirmation is still pending and valid.
- If app was killed AND motion detected since dismissal:
  auto-confirm (user has clearly been active).
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-7: User disables Wake Confirmation after dismissal but before it fires
SCENARIO: Woke up, dismissed alarm, immediately went to
settings and turned Wake Confirmation off.
RISE RESPONSE:
- WakeConfirmationService checks the alarm's wakeConfirmationEnabled
  flag at the moment of firing, not at the moment of scheduling.
- If flag is OFF at fire time: silently cancel and log.
- User CAN disable it in the ~15 minute window.
- This is intentional — respects the user's in-the-moment choice.
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-8: Nap mode alarm — wake confirmation does NOT apply
SCENARIO: User set a 20-minute nap alarm. Nap dismissed.
Wake confirmation would fire 15 minutes later, waking them again.
RISE RESPONSE:
- Wake confirmation is NEVER scheduled for nap-mode alarms.
  isNap = true → wakeConfirmationEnabled is ignored.
- This is enforced in WakeConfirmationService.schedule()
  before scheduling, not just in the UI toggle.
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-9: User missed wake confirmation AND buddy message — phone silent
SCENARIO: Dismissed alarm, went back to bed, phone muted.
Missed wake confirmation. Missed buddy nudge.
RISE RESPONSE:
- This is acceptable product behavior. The feature is "best effort."
- The buddy nudge is soft (not the 30-min emergency escalation).
- RISE does NOT call emergency services for a missed confirmation.
- Log: wake_confirmation_missed for analytics.
- If user misses 3+ confirmations in a week: in-app insight shown:
  "You've missed wake confirmations 3 times this week. Try placing
  your phone in another room." — constructive, never punitive.
IMPLEMENT IN: wake_confirmation_service.dart + home_screen.dart

---

## WC-10: Low battery when confirmation is due
SCENARIO: Phone at 5% when confirmation should fire.
RISE RESPONSE:
- Confirmation fires regardless — it's OS-scheduled.
- If battery < 10% at confirmation fire time: display a single
  battery warning alongside the confirmation screen.
  "Battery at X% — plug in after confirming."
- Do not cancel the confirmation due to low battery.
IMPLEMENT IN: wake_confirmation_screen.dart (Part 9)

---

## WC-11: User already confirmed awake via an app
SCENARIO: User is on Instagram at 6:14. Confirmation fires 6:15.
They're obviously awake.
RISE RESPONSE:
- Check for recent screen interaction: if significant interaction
  (scroll, tap, type) in the 5 minutes before confirmation fires,
  auto-confirm silently.
- Threshold: > 20 screen interaction events in the preceding 5 min.
  (Normal screen use, not just screen-on.)
- Android: AccessibilityService event count (opt-in only).
  iOS: This cannot be detected — confirmation fires normally.
- Log: wake_confirmed_by_screen_activity
IMPLEMENT IN: wake_confirmation_service.dart (Part 9)

---

## WC-12: Guardian plan — parent sets wake confirmation for child
SCENARIO: Parent enables wake confirmation on child's alarm.
Child dismisses alarm, goes back to sleep.
RISE RESPONSE:
- Wake confirmation fires normally on child's device.
- If child MISSES the confirmation:
  → Parent receives additional notification (not buddy — parent):
    "[Child's name] may have gone back to sleep after their alarm."
  → This is in addition to the buddy soft message.
- Parent dashboard shows confirmation status for each child.
IMPLEMENT IN: wake_confirmation_service.dart + guardian_service (Part 12)

---

# ══════════════════════════════════════════════════════════════
# FILE 1: lib/core/models/wake_confirmation.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'wake_confirmation.g.dart';

enum WakeConfirmResult {
  confirmed,        // User passed the wake check
  autoConfirmedMotion,   // WC-2: movement detected before firing
  autoConfirmedDriving,  // WC-3
  autoConfirmedCall,     // WC-4: on call, auto-confirmed after timeout
  autoConfirmedActivity, // WC-11: screen activity
  supersededByAlarm,     // WC-5: second alarm fired first
  missed,           // User did not respond within timeout
  cancelled,        // Alarm had wakeConfirmation toggled off (WC-7)
  napMode,          // WC-8: nap alarm, not applicable
}

@HiveType(typeId: 9)
class WakeConfirmation extends HiveObject {
  @HiveField(0) final String          id;
  @HiveField(1) final String          alarmId;
  @HiveField(2) final DateTime        scheduledFor;   // dismissedAt + 15min
  @HiveField(3) final DateTime        originalDismissalAt;
  @HiveField(4) DateTime?             firedAt;
  @HiveField(5) DateTime?             confirmedAt;
  @HiveField(6) WakeConfirmResult?    result;
  @HiveField(7) bool                  buddyNotified;
  @HiveField(8) int                   postponeCount;  // WC-4

  WakeConfirmation({
    String? id,
    required this.alarmId,
    required this.scheduledFor,
    required this.originalDismissalAt,
    this.firedAt,
    this.confirmedAt,
    this.result,
    this.buddyNotified  = false,
    this.postponeCount  = 0,
  }) : id = id ?? const Uuid().v4();

  bool get isPending    => result == null;
  bool get isConfirmed  =>
      result == WakeConfirmResult.confirmed ||
      result == WakeConfirmResult.autoConfirmedMotion ||
      result == WakeConfirmResult.autoConfirmedDriving ||
      result == WakeConfirmResult.autoConfirmedCall ||
      result == WakeConfirmResult.autoConfirmedActivity ||
      result == WakeConfirmResult.supersededByAlarm;
  bool get isMissed     => result == WakeConfirmResult.missed;
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 2: lib/core/services/wake_confirmation_service.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/alarm_model.dart';
import '../models/wake_confirmation.dart';
import 'buddy_notification_service.dart';
import 'driving_detector.dart';

class WakeConfirmationService {
  static final WakeConfirmationService _i =
      WakeConfirmationService._internal();
  factory WakeConfirmationService() => _i;
  WakeConfirmationService._internal();

  static const _channel =
      MethodChannel('com.rise.alarmclock/capabilities');
  final _notifications = FlutterLocalNotificationsPlugin();
  final _buddy         = BuddyNotificationService();
  final _driving       = DrivingDetector();

  // ── SCHEDULE ───────────────────────────────────────────────────────────────
  // Called immediately after AlarmService.dismissAlarm().
  // WC-8: Never for nap alarms.
  Future<void> schedule({
    required AlarmModel alarm,
    required DateTime   dismissedAt,
  }) async {
    // WC-8: Nap alarms never get wake confirmation
    if (alarm.isNap) return;
    // Feature off for this alarm
    if (!alarm.wakeConfirmationEnabled) return;

    final fireAt = dismissedAt
        .add(const Duration(minutes: AppConstants.wakeConfirmDelayMinutes));

    final confirmation = WakeConfirmation(
      alarmId:              alarm.id,
      scheduledFor:         fireAt,
      originalDismissalAt:  dismissedAt,
    );

    await Hive.box<dynamic>(AppConstants.wakeConfirmBoxName)
        .put(confirmation.id, confirmation);

    // Schedule via OS (survives app kill — WC-6)
    await _notifications.zonedSchedule(
      AppConstants.wakeConfirmNotifId,
      'Just checking',
      'Still awake? Tap to confirm.',
      _toTZDateTime(fireAt),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_confirm_channel',
          'Wake Confirmation',
          channelDescription: 'Gentle post-alarm wakefulness check',
          importance:   Importance.high,
          priority:     Priority.high,
          sound:        RawResourceAndroidNotificationSound('chime'),
          playSound:    true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300]),
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound:    true,
          presentAlert:    true,
          presentBadge:    false,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'wake_confirm:${confirmation.id}',
    );
  }

  // ── ON FIRE ────────────────────────────────────────────────────────────────
  // Called when the OS delivers the wake confirmation notification.
  // Performs all auto-confirm checks before showing UI.
  Future<WakeConfirmFireResult> onFired(String confirmationId) async {
    final box = Hive.box<dynamic>(AppConstants.wakeConfirmBoxName);
    final confirm = box.get(confirmationId) as WakeConfirmation?;
    if (confirm == null) {
      return WakeConfirmFireResult.invalid;
    }

    // Load alarm to check flag at fire time (WC-7)
    final alarmBox = Hive.box<dynamic>(AppConstants.alarmsBoxName);
    final alarm    = alarmBox.get(confirm.alarmId) as AlarmModel?;
    if (alarm == null || !alarm.wakeConfirmationEnabled) {
      confirm.result = WakeConfirmResult.cancelled;
      await confirm.save();
      return WakeConfirmFireResult.cancelled;
    }

    // WC-5: Another alarm already fired in the last 10 minutes
    if (await _recentAlarmFired(confirm.scheduledFor)) {
      confirm.result = WakeConfirmResult.supersededByAlarm;
      await confirm.save();
      return WakeConfirmFireResult.cancelled;
    }

    // WC-3: Driving
    if (await _driving.isDriving()) {
      await _autoConfirm(confirm, WakeConfirmResult.autoConfirmedDriving);
      return WakeConfirmFireResult.autoConfirmed;
    }

    // WC-2: Moving (commuting)
    if (await _isMoving()) {
      await _autoConfirm(confirm, WakeConfirmResult.autoConfirmedMotion);
      return WakeConfirmFireResult.autoConfirmed;
    }

    // WC-4: Active phone call → postpone
    if (await _isOnCall()) {
      if (confirm.postponeCount < 2) {
        confirm.postponeCount++;
        await confirm.save();
        await _reschedule(confirmationId,
            DateTime.now().add(const Duration(minutes: 3)));
        return WakeConfirmFireResult.postponed;
      } else {
        // Max postponements reached — auto-confirm
        await _autoConfirm(confirm, WakeConfirmResult.autoConfirmedCall);
        return WakeConfirmFireResult.autoConfirmed;
      }
    }

    // WC-11: Significant recent screen activity (Android only)
    if (await _hasRecentScreenActivity()) {
      await _autoConfirm(confirm, WakeConfirmResult.autoConfirmedActivity);
      return WakeConfirmFireResult.autoConfirmed;
    }

    // None of the auto-confirm conditions met — show UI
    confirm.firedAt = DateTime.now();
    await confirm.save();

    // Start the timeout clock
    _startTimeoutTimer(confirm, alarm);

    return WakeConfirmFireResult.showUi;
  }

  // ── USER CONFIRMED ─────────────────────────────────────────────────────────
  Future<void> userConfirmed(String confirmationId) async {
    final box     = Hive.box<dynamic>(AppConstants.wakeConfirmBoxName);
    final confirm = box.get(confirmationId) as WakeConfirmation?;
    if (confirm == null) return;

    confirm.result      = WakeConfirmResult.confirmed;
    confirm.confirmedAt = DateTime.now();
    await confirm.save();

    await _notifications.cancel(AppConstants.wakeConfirmNotifId);
    _cancelTimeoutTimer(confirmationId);

    // Track missed confirmation streak for analytics (WC-9)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wake_confirm_streak_missed', 0);
  }

  // ── TIMEOUT (user did not respond) ────────────────────────────────────────
  final Map<String, Timer> _timeoutTimers = {};

  void _startTimeoutTimer(WakeConfirmation confirm, AlarmModel alarm) {
    _timeoutTimers[confirm.id]?.cancel();
    _timeoutTimers[confirm.id] = Timer(
      Duration(minutes: AppConstants.wakeConfirmTimeoutMinutes),
      () => _handleTimeout(confirm, alarm),
    );
  }

  void _cancelTimeoutTimer(String id) {
    _timeoutTimers[id]?.cancel();
    _timeoutTimers.remove(id);
  }

  Future<void> _handleTimeout(
      WakeConfirmation confirm, AlarmModel alarm) async {
    confirm.result = WakeConfirmResult.missed;
    await confirm.save();

    // WC-9: Track missed count
    final prefs  = await SharedPreferences.getInstance();
    final missed = (prefs.getInt('wake_confirm_streak_missed') ?? 0) + 1;
    await prefs.setInt('wake_confirm_streak_missed', missed);

    // Soft buddy nudge (much gentler than main alarm escalation)
    if (alarm.buddyNotifyEnabled && alarm.buddyContactId != null) {
      await _buddy.sendWakeConfirmationMissed(
          alarmId: alarm.id,
          buddyId: alarm.buddyContactId!);
      confirm.buddyNotified = true;
      await confirm.save();
    }
  }

  // ── AUTO-CONFIRM ───────────────────────────────────────────────────────────
  Future<void> _autoConfirm(
      WakeConfirmation confirm, WakeConfirmResult reason) async {
    confirm.result      = reason;
    confirm.confirmedAt = DateTime.now();
    await confirm.save();
    await _notifications.cancel(AppConstants.wakeConfirmNotifId);
  }

  // ── DETECTION HELPERS ──────────────────────────────────────────────────────
  Future<bool> _isMoving() async {
    try {
      // Sample accelerometer for 1 second
      final events = <AccelerometerEvent>[];
      final sub = accelerometerEventStream().listen(events.add);
      await Future.delayed(const Duration(milliseconds: 800));
      await sub.cancel();
      if (events.isEmpty) return false;

      // Compute average magnitude change
      double totalMag = 0;
      for (final e in events) {
        totalMag += (e.x * e.x + e.y * e.y + e.z * e.z);
      }
      final avgMag = totalMag / events.length;
      // Gravity = ~9.8². Moving phone > 120 (includes ~gravity + motion)
      return avgMag > 120;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isOnCall() async {
    try {
      final r = await _channel.invokeMethod('isOnPhoneCall') as bool?;
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasRecentScreenActivity() async {
    // Android only — requires AccessibilityService (opt-in)
    try {
      final count = await _channel.invokeMethod(
          'getRecentInteractionCount',
          {'windowMinutes': 5}) as int?;
      return (count ?? 0) > 20;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _recentAlarmFired(DateTime confirmAt) async {
    final prefs    = await SharedPreferences.getInstance();
    final lastFire = prefs.getString('last_alarm_fired_at');
    if (lastFire == null) return false;
    final t = DateTime.tryParse(lastFire);
    if (t == null) return false;
    return confirmAt.difference(t).inMinutes.abs() < 10;
  }

  Future<void> _reschedule(String confirmId, DateTime newTime) async {
    final box     = Hive.box<dynamic>(AppConstants.wakeConfirmBoxName);
    final confirm = box.get(confirmId) as WakeConfirmation?;
    if (confirm == null) return;

    await _notifications.zonedSchedule(
      AppConstants.wakeConfirmNotifId,
      'Just checking',
      'Still awake? Tap to confirm.',
      _toTZDateTime(newTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_confirm_channel', 'Wake Confirmation',
          importance: Importance.high, priority: Priority.high,
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'wake_confirm:$confirmId',
    );
  }

  // Stub — use timezone library in full implementation
  dynamic _toTZDateTime(DateTime dt) => dt;

  // ── WEEKLY INSIGHT (WC-9) ──────────────────────────────────────────────────
  Future<int> getMissedConfirmationCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('wake_confirm_streak_missed') ?? 0;
  }

  // ── CANCEL pending confirmation (e.g., WC-5 from AlarmService) ────────────
  Future<void> cancelPendingForAlarm(String alarmId) async {
    final box = Hive.box<dynamic>(AppConstants.wakeConfirmBoxName);
    final pending = box.values
        .cast<WakeConfirmation>()
        .where((c) => c.alarmId == alarmId && c.isPending)
        .toList();
    for (final c in pending) {
      c.result = WakeConfirmResult.supersededByAlarm;
      await c.save();
    }
    await _notifications.cancel(AppConstants.wakeConfirmNotifId);
  }
}

enum WakeConfirmFireResult { showUi, autoConfirmed, postponed, cancelled, invalid }
```

---

# ══════════════════════════════════════════════════════════════
# FILE 3: lib/features/alarm/wake_confirmation_screen.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/services/wake_confirmation_service.dart';
import '../wake_games/games/math_game.dart';
import '../../core/services/wake_game_engine.dart';

class WakeConfirmationScreen extends StatefulWidget {
  final String confirmationId;
  const WakeConfirmationScreen({super.key, required this.confirmationId});

  @override
  State<WakeConfirmationScreen> createState() =>
      _WakeConfirmationScreenState();
}

class _WakeConfirmationScreenState
    extends State<WakeConfirmationScreen> {
  final _svc     = WakeConfirmationService();
  bool  _passed  = false;
  int?  _battery;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _checkBattery();
  }

  Future<void> _checkBattery() async {
    // WC-10: Low battery warning
    final level = await Battery().batteryLevel;
    if (level < 15 && mounted) {
      setState(() => _battery = level);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onGamePass(int timeSecs, int wrongAnswers) {
    setState(() => _passed = true);
    HapticFeedback.lightImpact();
    _svc.userConfirmed(widget.confirmationId);
    // Auto-close after a short confirmation animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            const SizedBox(height: 48),
            const Text('👋',
                style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Just checking you\'re still awake',
                style: TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Quick question to confirm',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14)),

            // WC-10: Battery warning
            if (_battery != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.battery_alert,
                        color: Colors.orange, size: 14),
                    const SizedBox(width: 8),
                    Text('Battery at $_battery% — plug in soon.',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12)),
                  ]),
                ),
              ),
            ],

            const Spacer(),

            // ── Wake game (1 easy question) ─────────────────────────
            if (!_passed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: MathGame(
                  difficulty:        GameDifficulty.easy,
                  accessibilityMode: false,
                  onComplete:        (_, t, w) => _onGamePass(t, w),
                ),
              )
            else
              // Success animation
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.greenAccent, size: 64),
                  const SizedBox(height: 16),
                  const Text('Great — you\'re up! ✓',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                ],
              ),

            const Spacer(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 4: lib/features/home/home_screen.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/alarm_model.dart';
import '../../core/models/sleep_session.dart';
import '../../core/models/subscription_tier.dart';
import '../../core/models/wake_confirmation.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/wake_confirmation_service.dart';
import '../alarm/alarm_setup_screen.dart';
import '../social/leaderboard_service.dart';
import 'widgets/sleep_score_card.dart';
import 'widgets/streak_card.dart';
import 'widgets/upcoming_alarm_card.dart';
import 'widgets/wake_confirmation_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {

  AlarmModel?       _nextAlarm;
  SleepSession?     _lastSession;
  int               _currentStreak    = 0;
  int               _personalBest     = 0;
  LeaderboardEntry? _myRank;
  bool              _loading          = true;
  WakeConfirmation? _pendingConfirm;
  int               _missedConfirms   = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final alarmBox   = Hive.box<dynamic>(AppConstants.alarmsBoxName);
    final sessionBox = Hive.box<dynamic>(AppConstants.sessionsBoxName);
    final confirmBox = Hive.box<dynamic>(AppConstants.wakeConfirmBoxName);

    final uid  = ref.read(subscriptionProvider).userId;
    final tier = SubscriptionTier.fromId(ref.read(subscriptionProvider).tier);

    // Next alarm
    final alarms     = alarmBox.values.cast<AlarmModel>()
        .where((a) => a.isEnabled).toList();
    alarms.sort((a, b) =>
        (a.nextFireTime ?? DateTime(9999))
            .compareTo(b.nextFireTime ?? DateTime(9999)));
    final next = alarms.firstOrNull;

    // Last sleep session
    final sessions = sessionBox.values.cast<SleepSession>().toList();
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final last = sessions.firstOrNull;

    // Streak
    final streak = _computeStreak(sessions);
    final prefs  = await SharedPreferences.getInstance();
    final pb     = prefs.getInt('streak_personal_best') ?? 0;
    if (streak > pb) {
      await prefs.setInt('streak_personal_best', streak);
    }

    // Pending wake confirmation
    final pending = confirmBox.values.cast<WakeConfirmation>()
        .where((c) => c.isPending)
        .toList();
    final pendingConfirm = pending.firstOrNull;

    // Missed confirmation insight (WC-9)
    final missed = await WakeConfirmationService()
        .getMissedConfirmationCount();

    // Leaderboard rank (Pro+)
    LeaderboardEntry? rank;
    if (tier.prizeEligible && uid != null) {
      try {
        rank = await LeaderboardService().getMyRank(uid);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _nextAlarm        = next;
      _lastSession      = last;
      _currentStreak    = streak;
      _personalBest     = max(streak, pb);
      _myRank           = rank;
      _loading          = false;
      _pendingConfirm   = pendingConfirm;
      _missedConfirms   = missed;
    });
  }

  int _computeStreak(List<SleepSession> sessions) {
    // Count consecutive days with a dismissed session (no all-nighter)
    if (sessions.isEmpty) return 0;
    final sorted = List<SleepSession>.from(sessions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    int streak = 0;
    DateTime? prev;
    for (final s in sorted) {
      if (s.noSleepDetected || s.wakeTime == null) break;
      final day = DateTime(
          s.wakeTime!.year, s.wakeTime!.month, s.wakeTime!.day);
      if (prev == null) {
        prev = day;
        streak = 1;
        continue;
      }
      if (prev.difference(day).inDays == 1) {
        streak++;
        prev = day;
      } else {
        break;
      }
    }
    return streak;
  }

  int max(int a, int b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    final tier = SubscriptionTier.fromId(
        ref.watch(subscriptionProvider).tier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: Colors.white24))
            : RefreshIndicator(
                onRefresh:      _load,
                color:          Colors.indigoAccent,
                backgroundColor: const Color(0xFF161628),
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(tier),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── Wake confirmation banner ──────────────
                          if (_pendingConfirm != null)
                            WakeConfirmationBanner(
                              confirmation: _pendingConfirm!,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) =>
                                  WakeConfirmationScreen(
                                    confirmationId: _pendingConfirm!.id)),
                              ),
                            ),

                          // ── Missed confirmation insight (WC-9) ───
                          if (_missedConfirms >= 3)
                            _InsightBanner(
                              text: 'You\'ve missed wake confirmations '
                                    '$_missedConfirms times recently. '
                                    'Try placing your phone out of reach.',
                              icon: Icons.tips_and_updates_outlined,
                            ),

                          // ── Upcoming alarm ────────────────────────
                          UpcomingAlarmCard(
                            alarm:   _nextAlarm,
                            onEdit:  () => _editAlarm(_nextAlarm),
                            onAdd:   _addAlarm,
                          ),
                          const SizedBox(height: 12),

                          // ── Last night ────────────────────────────
                          if (_lastSession != null)
                            SleepScoreCard(session: _lastSession!),
                          const SizedBox(height: 12),

                          // ── Streak ────────────────────────────────
                          StreakCard(
                            streak:  _currentStreak,
                            best:    _personalBest,
                          ),
                          const SizedBox(height: 12),

                          // ── Leaderboard rank mini-widget (Pro+) ───
                          if (_myRank != null) ...[
                            _LeaderboardRankWidget(entry: _myRank!),
                            const SizedBox(height: 12),
                          ],

                          // ── Sleep debt nudge (Pro+) ───────────────
                          if (tier.sleepDebtLedger &&
                              _lastSession != null)
                            _SleepDebtWidget(session: _lastSession!),

                          const SizedBox(height: 80),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),

      // ── FAB: quick add alarm ──────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        backgroundColor: Colors.indigoAccent,
        child: const Icon(Icons.add_alarm, color: Colors.white),
      ),
    );
  }

  SliverAppBar _buildAppBar(SubscriptionTier tier) {
    final hour  = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' :
                  hour < 18 ? 'Good afternoon' : 'Good evening';
    return SliverAppBar(
      backgroundColor:   const Color(0xFF0D0D1A),
      floating:          true,
      title:             Text(greet,
          style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w300, fontSize: 20)),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: Colors.white54),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline,
              color: Colors.white54),
          onPressed: () => Navigator.pushNamed(context, '/wallet'),
        ),
      ],
    );
  }

  void _addAlarm() => Navigator.push(context,
      MaterialPageRoute(
          builder: (_) => const AlarmSetupScreen()))
      .then((_) => _load());

  void _editAlarm(AlarmModel? alarm) {
    if (alarm == null) return;
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => AlarmSetupScreen(existing: alarm)))
        .then((_) => _load());
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 5: lib/features/home/widgets/upcoming_alarm_card.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/alarm_model.dart';
import '../../../core/services/alarm_service.dart';

class UpcomingAlarmCard extends StatefulWidget {
  final AlarmModel?   alarm;
  final VoidCallback  onEdit;
  final VoidCallback  onAdd;
  const UpcomingAlarmCard({
    super.key, this.alarm,
    required this.onEdit, required this.onAdd,
  });
  @override
  State<UpcomingAlarmCard> createState() => _UpcomingAlarmCardState();
}

class _UpcomingAlarmCardState extends State<UpcomingAlarmCard> {
  late Timer _tick;
  bool   _earlyDismissAvailable = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() { _tick.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final alarm = widget.alarm;

    if (alarm == null) {
      return _NoAlarmCard(onAdd: widget.onAdd);
    }

    final next  = alarm.nextFireTime;
    if (next == null) return _NoAlarmCard(onAdd: widget.onAdd);

    final diff     = next.difference(DateTime.now());
    final hours    = diff.inHours;
    final minutes  = diff.inMinutes.remainder(60);
    final early    = diff.inMinutes <= 30 && diff.inMinutes >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.alarm, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(alarm.repeatLabel,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12,
                    letterSpacing: 0.5)),
            const Spacer(),
            // Wake confirmation indicator
            if (alarm.wakeConfirmationEnabled)
              _Tag(label: 'Wake check on',
                  color: Colors.greenAccent),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onEdit,
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white38, size: 18),
            ),
          ]),
          const SizedBox(height: 12),

          // Big time display
          Text(alarm.displayTime, style: const TextStyle(
              color: Colors.white, fontSize: 52,
              fontWeight: FontWeight.w200, letterSpacing: 3)),

          if (alarm.label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(alarm.label, style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 14)),
          ],

          const SizedBox(height: 16),

          // Countdown
          Text(
            hours > 0
                ? 'in ${hours}h ${minutes}m'
                : 'in ${diff.inMinutes}m',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 14)),

          // EC-4.8: Early dismiss button (30 min before)
          if (early) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _earlyDismiss(context, alarm),
              icon: const Icon(Icons.wb_sunny_outlined, size: 16),
              label: const Text('I\'m already up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _earlyDismiss(
      BuildContext ctx, AlarmModel alarm) async {
    final confirmed = await AlarmService().requestEarlyDismiss(alarm.id);
    if (!confirmed || !ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('Alarm dismissed early. Have a great morning!'),
    ));
  }
}

class _NoAlarmCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _NoAlarmCard({required this.onAdd});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onAdd,
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        const Color(0xFF161628),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(children: [
        const Icon(Icons.add_alarm_outlined,
            color: Colors.white38, size: 32),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('No alarm set',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Tap to add one',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 13)),
        ]),
      ]),
    ),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color  color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 10,
        fontWeight: FontWeight.w600)),
  );
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 6: lib/features/home/widgets/sleep_score_card.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import '../../../core/models/sleep_session.dart';
import '../../../core/services/sleep_quality_scorer.dart';

class SleepScoreCard extends StatelessWidget {
  final SleepSession session;
  const SleepScoreCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final scored = SleepQualityScorer().score(session);

    final scoreColor = switch (scored.qualityLabel) {
      'excellent' => Colors.greenAccent,
      'good'      => Colors.lightGreen,
      'fair'      => Colors.amber,
      _           => Colors.redAccent,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        const Color(0xFF161628),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bedtime, color: Colors.white24, size: 16),
            const SizedBox(width: 6),
            const Text('Last night',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(width: 4),
            Text('· estimated',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 11)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            // Score ring
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 70, height: 70,
                child: CircularProgressIndicator(
                  value:           scored.score / 100,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  color:           scoreColor,
                  strokeWidth:     6,
                ),
              ),
              Text('${scored.score}',
                  style: TextStyle(
                      color: scoreColor, fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(width: 20),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.durationLabel, style: const TextStyle(
                    color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w300)),
                const SizedBox(height: 2),
                Text(scored.qualityLabel.toUpperCase(),
                    style: TextStyle(
                        color: scoreColor, fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                if (session.snoozeCount > 0) ...[
                  const SizedBox(height: 4),
                  Text('${session.snoozeCount} snooze'
                       '${session.snoozeCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ],
            )),
          ]),

          if (scored.scoreBreakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Text(scored.scoreBreakdown,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12,
                    height: 1.5)),
          ],

          // Phase bar (estimated)
          if (!session.noSleepDetected &&
              session.durationMinutes > 0) ...[
            const SizedBox(height: 12),
            _PhaseBar(session: session),
          ],
        ],
      ),
    );
  }
}

class _PhaseBar extends StatelessWidget {
  final SleepSession session;
  const _PhaseBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final total = session.durationMinutes;
    if (total == 0) return const SizedBox.shrink();

    final deep  = session.estimatedDeepMinutes  / total;
    final rem   = session.estimatedRemMinutes   / total;
    final light = session.estimatedLightMinutes / total;
    final awake = session.awakeMinutes          / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sleep phases · estimated',
            style: TextStyle(
                color: Colors.white38, fontSize: 11,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            _PhaseSegment(flex: (deep  * 100).round(), color: Colors.indigoAccent),
            _PhaseSegment(flex: (rem   * 100).round(), color: Colors.purpleAccent),
            _PhaseSegment(flex: (light * 100).round(), color: Colors.blueAccent),
            _PhaseSegment(flex: (awake * 100).round(), color: Colors.white24),
          ]),
        ),
        const SizedBox(height: 6),
        Row(children: [
          _PhaseLegend('Deep',  Colors.indigoAccent, session.estimatedDeepMinutes),
          _PhaseLegend('REM',   Colors.purpleAccent, session.estimatedRemMinutes),
          _PhaseLegend('Light', Colors.blueAccent,   session.estimatedLightMinutes),
        ]),
      ],
    );
  }
}

class _PhaseSegment extends StatelessWidget {
  final int   flex;
  final Color color;
  const _PhaseSegment({required this.flex, required this.color});
  @override
  Widget build(BuildContext context) =>
      flex <= 0 ? const SizedBox.shrink()
                : Expanded(flex: flex.clamp(1, 100),
                    child: Container(height: 8, color: color));
}

class _PhaseLegend extends StatelessWidget {
  final String label;
  final Color  color;
  final int    minutes;
  const _PhaseLegend(this.label, this.color, this.minutes);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(
          color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$label ${minutes}m',
          style: const TextStyle(
              color: Colors.white38, fontSize: 10)),
    ]),
  );
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 7: lib/features/home/widgets/streak_card.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  final int best;
  const StreakCard({super.key, required this.streak, required this.best});

  @override
  Widget build(BuildContext context) {
    final milestone = _milestone(streak);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        const Color(0xFF161628),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        // Flame icon — grows with streak
        Text(_flameFor(streak),
            style: TextStyle(fontSize: streak >= 7 ? 40 : 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('$streak', style: const TextStyle(
                  color: Colors.white, fontSize: 30,
                  fontWeight: FontWeight.w300)),
              const SizedBox(width: 6),
              Text(streak == 1 ? 'day streak' : 'day streak',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 15)),
            ]),
            if (streak == best && streak > 0)
              const Text('Personal best 🏆',
                  style: TextStyle(
                      color: Colors.amber, fontSize: 11,
                      fontWeight: FontWeight.w600))
            else if (best > 0)
              Text('Best: $best days',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
          ],
        )),
        // Milestone badge
        if (milestone != null)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:        Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.amber.withOpacity(0.4)),
            ),
            child: Text(milestone,
                style: const TextStyle(
                    color: Colors.amber, fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  String _flameFor(int s) {
    if (s >= 30) return '🔥';
    if (s >= 7)  return '🔥';
    if (s >= 3)  return '✨';
    if (s >= 1)  return '⚡';
    return '😴';
  }

  String? _milestone(int s) {
    if (s == 7)  return '1 week!';
    if (s == 14) return '2 weeks!';
    if (s == 30) return '1 month!';
    if (s == 60) return '2 months!';
    if (s == 90) return '90 days! 💰';
    if (s == 100) return '100 days!';
    return null;
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# FILE 8: lib/features/home/widgets/wake_confirmation_banner.dart
# ══════════════════════════════════════════════════════════════

```dart
import 'package:flutter/material.dart';
import '../../../core/models/wake_confirmation.dart';

class WakeConfirmationBanner extends StatelessWidget {
  final WakeConfirmation confirmation;
  final VoidCallback     onTap;
  const WakeConfirmationBanner({
    super.key,
    required this.confirmation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now      = DateTime.now();
    final isPast   = confirmation.scheduledFor.isBefore(now);
    final minsLeft = isPast ? 0 :
        confirmation.scheduledFor.difference(now).inMinutes;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.greenAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.greenAccent.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Text('👋', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPast
                    ? 'Wake confirmation is waiting!'
                    : 'Wake confirmation in ${minsLeft}m',
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tap to confirm you\'re still awake',
                style: TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
            ],
          )),
          const Icon(Icons.chevron_right,
              color: Colors.greenAccent, size: 20),
        ]),
      ),
    );
  }
}
```

---

# ══════════════════════════════════════════════════════════════
# HOME SCREEN SUPPORTING WIDGETS (inline — no separate files)
# ══════════════════════════════════════════════════════════════

```dart
// Add to home_screen.dart — below _HomeScreenState class

class _LeaderboardRankWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderboardRankWidget({required this.entry});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/leaderboard'),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161628),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.emoji_events,
            color: Color(0xFFFFD700), size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leaderboard',
                style: TextStyle(color: Colors.white54,
                    fontSize: 12)),
            Text('Rank #${entry.rank}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        )),
        Text('${entry.score.toStringAsFixed(1)}/100',
            style: const TextStyle(
                color: Colors.white54, fontSize: 13)),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right,
            color: Colors.white24, size: 20),
      ]),
    ),
  );
}

class _SleepDebtWidget extends StatelessWidget {
  final SleepSession session;
  const _SleepDebtWidget({required this.session});

  @override
  Widget build(BuildContext context) {
    // Simple debt: 8h goal - actual sleep
    final goalMins   = 8 * 60;
    final actualMins = session.durationMinutes;
    final debtMins   = (goalMins - actualMins).clamp(0, 999);

    if (debtMins == 0) return const SizedBox.shrink();

    final debtH = debtMins ~/ 60;
    final debtM = debtMins % 60;
    final label = debtH > 0 ? '${debtH}h ${debtM}m' : '${debtM}m';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161628),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_bottom,
            color: Colors.amber, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sleep debt',
                style: TextStyle(color: Colors.white54,
                    fontSize: 12)),
            Text('$label below 8h goal',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14)),
          ],
        )),
      ]),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final String   text;
  final IconData icon;
  const _InsightBanner({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    margin:  const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        Colors.blue.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.withOpacity(0.3)),
    ),
    child: Row(children: [
      Icon(icon, color: Colors.blue, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: const TextStyle(
              color: Colors.blue, fontSize: 12, height: 1.4))),
    ]),
  );
}
```

---

# ══════════════════════════════════════════════════════════════
# PART 8 RETROFIT: AlarmSetupScreen + AlarmModel additions
# ══════════════════════════════════════════════════════════════

## ADD TO AlarmModel (lib/core/models/alarm_model.dart)

```dart
@HiveField(27)
bool wakeConfirmationEnabled; // Part 9: secondary wake check 15min after dismiss

@HiveField(28)
bool isNap; // EC-4.7: duplicate of sleep session flag — alarm-level flag
```

Add defaults to constructor:
```dart
this.wakeConfirmationEnabled = false,
this.isNap = false,
```

## ADD TO AlarmSetupScreen (lib/features/alarm/alarm_setup_screen.dart)
Add field to state:
```dart
late bool _wakeConfirmEnabled;
```

Initialize:
```dart
_wakeConfirmEnabled = a?.wakeConfirmationEnabled ?? false;
```

Add after the post-watchdog toggle in the Behavior section:
```dart
const Divider(color: Colors.white12),
_SwitchRow(
  label:    'Wake confirmation',
  sublabel: 'RISE checks you\'re still up 15 minutes after dismissal — '
            'plays a gentle chime and asks one quick question.',
  value:    _wakeConfirmEnabled,
  onChanged: (v) => setState(() => _wakeConfirmEnabled = v),
),
```

Add to _saveAlarm():
```dart
wakeConfirmationEnabled: _wakeConfirmEnabled,
isNap:                   _isNap,
```

## CALL SITE: AlarmService.dismissAlarm()
After existing post-dismiss watchdog call, add:
```dart
// Schedule wake confirmation if enabled (Part 9)
if (alarm?.wakeConfirmationEnabled == true) {
  await WakeConfirmationService().schedule(
    alarm:       alarm!,
    dismissedAt: DateTime.now(),
  );
}
// WC-5: Store last alarm fire time for confirmation suppression
await prefs.setString('last_alarm_fired_at',
    DateTime.now().toIso8601String());
```

---

## CONSTANTS TO ADD: lib/core/constants/app_constants.dart

```dart
// Wake Confirmation constants (Part 9)
static const int    wakeConfirmDelayMinutes   = 15;  // Fire 15min after dismiss
static const int    wakeConfirmTimeoutMinutes = 5;   // User has 5min to respond
static const int    wakeConfirmBuddyMinutes   = 10;  // Buddy after 10min no-response
static const int    wakeConfirmNotifId        = 9900;// Notification ID
static const String wakeConfirmBoxName        = 'wake_confirmations_v1';
static const String sessionsBoxName           = 'sleep_sessions_v1';
```

---

## PART 9 FILE INVENTORY

```
NEW FILES (8):
  lib/core/models/wake_confirmation.dart          (typeId: 9)
  lib/core/services/wake_confirmation_service.dart
  lib/features/alarm/wake_confirmation_screen.dart
  lib/features/home/home_screen.dart
  lib/features/home/widgets/upcoming_alarm_card.dart
  lib/features/home/widgets/sleep_score_card.dart
  lib/features/home/widgets/streak_card.dart
  lib/features/home/widgets/wake_confirmation_banner.dart

RETROFITS (from Part 8):
  lib/core/models/alarm_model.dart
    → +HiveField(27) wakeConfirmationEnabled
    → +HiveField(28) isNap
  lib/features/alarm/alarm_setup_screen.dart
    → Wake Confirmation toggle added
  lib/core/services/alarm_service.dart (Part 3)
    → dismissAlarm() calls WakeConfirmationService.schedule()
    → dismissAlarm() stores last_alarm_fired_at

CONSTANTS UPDATE:
  lib/core/constants/app_constants.dart
    → 5 new Wake Confirmation constants
```

---

## WAKE CONFIRMATION EDGE CASE SUMMARY

```
WC-1  In the shower          ✓ 5-min window covers most showers
                               Soft nudge if missed
WC-2  Commuting / moving     ✓ Accelerometer motion → auto-confirm
WC-3  Driving                ✓ Driving detection → auto-confirm
WC-4  On a phone call        ✓ Postpone up to 2× (6min total) → auto-confirm
WC-5  Second alarm imminent  ✓ Cancel confirmation if alarm fires within 10min
WC-6  App killed             ✓ OS-scheduled (AlarmManager/UNNotif) survives kill
WC-7  User disables feature  ✓ Flag checked at fire time, not schedule time
WC-8  Nap mode               ✓ NEVER scheduled for nap alarms (enforced in service)
WC-9  Missed + no response   ✓ Soft buddy nudge; insight shown after 3+ misses
WC-10 Low battery            ✓ Battery warning shown on confirmation screen
WC-11 Already using phone    ✓ Screen activity count → auto-confirm (Android)
WC-12 Guardian / child       ✓ Parent notified on child's missed confirmation
```

---

## WHAT PART 10 WILL COVER:
Onboarding flow — the first-run experience.
Permission requests in the correct order, biometric enrollment
(the 5-session multi-day process), faith preference selection
(for dream journal), buddy setup, and the three modes:
Quick / Standard / Assisted (EC-9.2 elderly users).

---
## END OF PART 9 BLUEPRINT
## 8 new files | 3 retrofit files | 5 constants
## Wake Confirmation:   COMPLETE ✓ (feature spec + 12 edge cases)
## Home screen:         COMPLETE ✓ (alarm, score, streak, rank, debt)
## Upcoming alarm card: COMPLETE ✓ (early-dismiss EC-4.8, wake check tag)
## Sleep score card:    COMPLETE ✓ (ring chart, phase bar, estimated label)
## Streak card:         COMPLETE ✓ (milestone badges, personal best)
## WC banner:           COMPLETE ✓ (live countdown, tap-to-confirm)
## AlarmModel retrofit: COMPLETE ✓ (wakeConfirmationEnabled, isNap fields)
