# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 5 OF 12
# The Sleep Detection Service
# ============================================================
# COMMAND TO AI CODING AGENT:
# Parts 1–4 must be complete before starting this part.
# The Edge Case Bible is LAW — every EC-4.x and EC-2.x
# reference below maps to a specific implementation you must
# build exactly as described.
#
# WHAT THIS PART CREATES (6 files + 1 update):
#
#  1. lib/core/services/sleep_detection_service.dart
#     The main sleep lifecycle engine. Owns the state machine
#     (awake → pre_sleep → sleeping → micro_waking → awake).
#     Integrates motion analysis, screen state, and temperature
#     monitoring. All EC-4.x cases are routed here.
#
#  2. lib/core/services/motion_analyzer.dart
#     Accelerometer signal processing. Extracts motion features:
#     stillness score, frequency (for vehicle/appliance detection),
#     amplitude variance (for tossing vs. vehicle), fall detection
#     spike detection. Feeds SleepDetectionService every 5 seconds.
#
#  3. lib/core/services/sleep_quality_scorer.dart
#     Scores a completed SleepSession 0–100. Uses duration, snooze
#     count, night wakings, motion variance during sleep window,
#     and time-of-day consistency. Produces qualityLabel and
#     estimated phase breakdown (REM/deep/light/awake minutes).
#
#  4. lib/core/services/thermal_monitor.dart
#     Monitors device temperature. EC-2.2: phone-under-pillow
#     overheating detection. Fires warning at alarm time if
#     thermal state is severe. Shows bedtime advisory once.
#
#  5. lib/core/providers/sleep_detection_provider.dart
#     Riverpod providers for live sleep detection state.
#     Exposes: current SleepState, active session stream,
#     sleep onset time, last night's scored session.
#
#  6. lib/features/sleep/sleep_tracker_screen.dart
#     The Sleep tab UI. Displays last night's session, sleep
#     history chart, quality trend, and EC-4.10 honesty labels
#     ("estimated" on all metrics). Shows pillow advisory once.
#
# UPDATES:
#  - lib/core/models/sleep_session.dart (add EC fields)
#  - lib/core/constants/app_constants.dart (sleep thresholds)
# ============================================================

## ARCHITECTURE: THE SLEEP STATE MACHINE

# The SleepDetectionService owns a state machine with these states:
#
# ┌──────────────────────────────────────────────────────────────┐
# │  AWAKE                                                       │
# │  Phone is in active use. Screen on, motion present.         │
# │  Transitions → PRE_SLEEP when:                              │
# │    • Screen off for ≥ 2 minutes AND                         │
# │    • Motion score < stillness threshold AND                  │
# │    • An alarm is set for within the next 16 hours            │
# └──────────────────┬───────────────────────────────────────────┘
#                    │ 2 min screen-off + stillness
# ┌──────────────────▼───────────────────────────────────────────┐
# │  PRE_SLEEP (confirmation window — 3 minutes)                 │
# │  Watching for sustained stillness before committing.        │
# │  Transitions → SLEEPING if: stillness holds for 3 min       │
# │  Transitions → AWAKE if: motion OR screen-on detected        │
# └──────────────────┬───────────────────────────────────────────┘
#                    │ 3 min sustained stillness
# ┌──────────────────▼───────────────────────────────────────────┐
# │  SLEEPING                                                    │
# │  sleep_onset_time recorded. Motion data sampled every 30s.  │
# │  Transitions → MICRO_WAKING if: brief motion detected        │
# │  Transitions → AWAKE if: screen on for > 5 minutes          │
# │  Transitions → AWAKE (alarm dismissed) via AlarmService      │
# │                                                              │
# │  SPECIAL MODES:                                              │
# │  • TRAVEL_MODE: Vehicle motion detected → screen proxy only  │
# │  • PILLOW_MODE: Possible under-pillow → thermal monitoring   │
# └──────────────────┬───────────────────────────────────────────┘
#                    │ brief motion < 15s
# ┌──────────────────▼───────────────────────────────────────────┐
# │  MICRO_WAKING (EC-4.2/EC-4.4)                               │
# │  Brief disturbance. Bathroom trip, baby grabbed phone, pet. │
# │  Transitions → SLEEPING if: stillness resumes within 5 min  │
# │  Transitions → AWAKE if: screen on > 5 min OR motion > 15s  │
# │  Logged as "night_waking" micro-event (sleep quality metric) │
# └──────────────────────────────────────────────────────────────┘

---

## CONSTANTS TO ADD: lib/core/constants/app_constants.dart

```dart
// ── Sleep Detection thresholds ─────────────────────────────────────────────
static const String sleepSessionsBoxName       = 'sleep_v1'; // may already exist

// Sleep onset detection
static const int    sleepScreenOffMinutes      = 2;   // Screen must be off ≥2 min
static const int    sleepPreSleepWindowMinutes = 3;   // Confirmation window
static const double sleepStillnessThreshold    = 0.15;// Acceleration magnitude m/s²
static const int    sleepLookbackHours         = 16;  // Look for sleep in past 16h
static const int    sleepAlarmWindowHours      = 16;  // Alarm must be within 16h

// Micro-waking thresholds (EC-4.2, EC-4.4)
static const int    microWakingMaxSeconds      = 15;  // Motion < 15s = micro-waking
static const int    microWakingScreenMinutes   = 5;   // Screen < 5 min = not awake
static const int    nightWakingMaxMinutes      = 5;   // Phone use < 5 min = night waking

// Vehicle/appliance detection (EC-4.1, EC-4.3)
static const double vehicleMotionFreqMinHz     = 0.5; // Vehicle oscillation range
static const double vehicleMotionFreqMaxHz     = 2.0;
static const double mechanicalVibrationMinHz   = 5.0; // Appliance vibration
static const double vehiclePatternMinutes      = 10;  // Must persist ≥10 min
static const double vehicleAmplitudeCvThresh   = 0.3; // Low CV = consistent (vehicle)

// Fall detection (EC-2.3)
static const double fallAccelThreshold         = 15.0;// m/s² — sudden spike
static const double fallPostStillnessSeconds   = 3.0; // Stillness after spike
static const double fallVolumeBoostPercent     = 15.0;// +15% max volume after fall

// Thermal monitoring (EC-2.2)
static const int    thermalCheckIntervalMinutes = 5;
static const bool   pillarAdvisoryShownOnce    = true; // Show pillow advisory once

// Quality scoring weights
static const double qualityDurationWeight       = 0.40;
static const double qualityMotionWeight         = 0.25;
static const double qualityConsistencyWeight    = 0.20;
static const double qualitySnoozeWeight         = 0.15;
```

---

## UPDATE: lib/core/models/sleep_session.dart
## ADD these new HiveFields to the existing SleepSession class.
## IMPORTANT: Only ADD new @HiveField entries — never renumber existing ones.
## Next available typeId field numbers start at 17.

```dart
// Add to SleepSession class — after @HiveField(16) createdAt:

@HiveField(17)
bool isNap; // EC-4.7: true for nap-mode alarms

@HiveField(18)
bool noSleepDetected; // EC-4.5: all-nighter flag

@HiveField(19)
bool travelModeActive; // EC-4.1: vehicle motion detected

@HiveField(20)
int nightWakingCount; // EC-4.4: how many bathroom trips / brief interactions

@HiveField(21)
bool fallDetected; // EC-2.3: phone fell off nightstand

@HiveField(22)
String? thermalWarning; // EC-2.2: 'severe' | 'critical' | null

@HiveField(23)
String timezoneAtSleep; // EC-5.4: for timezone-change detection

@HiveField(24)
List<Map<String, dynamic>> microWakingEvents; // Timestamped list of waking events

// Add to constructor:
// this.isNap = false,
// this.noSleepDetected = false,
// this.travelModeActive = false,
// this.nightWakingCount = 0,
// this.fallDetected = false,
// this.thermalWarning,
// this.timezoneAtSleep = '',
// this.microWakingEvents = const [],
```

---

## FILE 1: lib/core/services/motion_analyzer.dart
## PATH: lib/core/services/motion_analyzer.dart
## PURPOSE: Raw accelerometer signal processing. Runs at 5-second
##          intervals and produces MotionSnapshot structs used by
##          SleepDetectionService to drive state transitions.
## EDGE CASES:
##   EC-4.1: Vehicle motion — sinusoidal, consistent amplitude, 0.5–2Hz
##   EC-4.3: Appliance vibration — high-frequency >5Hz, consistent amplitude
##   EC-2.3: Fall detection — spike >15 m/s² + sustained stillness after

```dart
import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOTION SNAPSHOT
// Produced every 5 seconds by MotionAnalyzer.
// SleepDetectionService reads this to drive state transitions.
// ─────────────────────────────────────────────────────────────────────────────
class MotionSnapshot {
  /// Mean acceleration magnitude over the window (m/s²)
  /// Below sleepStillnessThreshold (0.15) = essentially still
  final double magnitude;

  /// Dominant oscillation frequency in the window (Hz)
  /// 0.5–2.0 Hz + consistent amplitude = vehicle (EC-4.1)
  /// >5.0 Hz + consistent amplitude = appliance (EC-4.3)
  final double dominantFreqHz;

  /// Coefficient of variation of amplitude — low CV = consistent (machine)
  /// High CV = irregular (tossing/turning)
  final double amplitudeCv;

  /// True if this window looks like vehicle travel (EC-4.1)
  final bool looksLikeVehicleMotion;

  /// True if this window looks like mechanical vibration (EC-4.3)
  final bool looksLikeMechanicalVibration;

  /// True if a fall-indicative spike was detected (EC-2.3)
  final bool fallSpikeDetected;

  /// Peak acceleration in the window — used for fall threshold check
  final double peakAcceleration;

  /// Orientation at end of window (for fall orientation change check)
  final _Orientation orientation;

  const MotionSnapshot({
    required this.magnitude,
    required this.dominantFreqHz,
    required this.amplitudeCv,
    required this.looksLikeVehicleMotion,
    required this.looksLikeMechanicalVibration,
    required this.fallSpikeDetected,
    required this.peakAcceleration,
    required this.orientation,
  });

  bool get isStill => magnitude < AppConstants.sleepStillnessThreshold;

  /// True if motion should be IGNORED for sleep detection
  /// (vehicle travel or appliance vibration — user's "stillness" is valid)
  bool get isAmbientMotion =>
      looksLikeVehicleMotion || looksLikeMechanicalVibration;
}

enum _Orientation { faceUp, faceDown, portrait, landscape, unknown }

// ─────────────────────────────────────────────────────────────────────────────
// MOTION ANALYZER
// ─────────────────────────────────────────────────────────────────────────────
class MotionAnalyzer {
  static final MotionAnalyzer _instance = MotionAnalyzer._internal();
  factory MotionAnalyzer() => _instance;
  MotionAnalyzer._internal();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  final _snapshotController = StreamController<MotionSnapshot>.broadcast();
  Stream<MotionSnapshot> get snapshots => _snapshotController.stream;

  // Rolling 5-second buffer of accelerometer samples
  // At ~50Hz sensor rate, this is ~250 samples per window
  final List<double> _xBuf = [];
  final List<double> _yBuf = [];
  final List<double> _zBuf = [];
  final List<double> _magBuf = [];

  Timer? _windowTimer;
  bool _running = false;

  // Track orientation history for fall detection (EC-2.3)
  _Orientation _lastOrientation = _Orientation.unknown;
  double _postSpikeStillSeconds = 0;
  bool   _spikeDetectedThisWindow = false;

  // ─────────────────────────────────────────────────────────────────────────
  // START
  // ─────────────────────────────────────────────────────────────────────────
  void start() {
    if (_running) return;
    _running = true;

    // Subscribe to accelerometer at default rate (~50Hz)
    _accelSub = accelerometerEvents.listen((event) {
      if (!_running) return;
      _xBuf.add(event.x);
      _yBuf.add(event.y);
      _zBuf.add(event.z);

      // Compute magnitude: √(x²+y²+z²) - 9.81 (subtract gravity component)
      // Result is net user-induced acceleration
      final raw = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final net = (raw - 9.81).abs();
      _magBuf.add(net);

      // Track peak for fall detection
      if (net > AppConstants.fallAccelThreshold) {
        _spikeDetectedThisWindow = true;
      }
    });

    // Emit a MotionSnapshot every 5 seconds
    _windowTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _emitSnapshot();
    });
  }

  void stop() {
    _running = false;
    _windowTimer?.cancel();
    _accelSub?.cancel();
    _clearBuffers();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMIT SNAPSHOT
  // Processes the 5-second buffer into a MotionSnapshot.
  // ─────────────────────────────────────────────────────────────────────────
  void _emitSnapshot() {
    if (_magBuf.isEmpty) {
      _snapshotController.add(MotionSnapshot(
        magnitude: 0, dominantFreqHz: 0, amplitudeCv: 0,
        looksLikeVehicleMotion: false, looksLikeMechanicalVibration: false,
        fallSpikeDetected: false, peakAcceleration: 0,
        orientation: _lastOrientation,
      ));
      return;
    }

    final mags = List<double>.from(_magBuf);
    final xs   = List<double>.from(_xBuf);
    final ys   = List<double>.from(_yBuf);
    final zs   = List<double>.from(_zBuf);

    _clearBuffers();

    // ── Basic statistics ─────────────────────────────────────────────
    final mean = mags.reduce((a, b) => a + b) / mags.length;
    final peak = mags.reduce(math.max);

    final std = math.sqrt(
      mags.map((m) => (m - mean) * (m - mean))
          .reduce((a, b) => a + b) / mags.length,
    );

    // Coefficient of variation: std/mean
    // Low CV (< 0.3) = very regular amplitude = machine pattern
    // High CV = irregular = natural human movement
    final cv = mean > 0.01 ? std / mean : 1.0;

    // ── Dominant frequency (zero-crossing method) ────────────────────
    final freq = _zeroCrossingFreq(mags, sampleRateHz: 50.0);

    // ── Vehicle motion detection (EC-4.1) ────────────────────────────
    // Signature: 0.5–2.0 Hz + low amplitude CV (consistent oscillation)
    final isVehicle = freq >= AppConstants.vehicleMotionFreqMinHz &&
        freq <= AppConstants.vehicleMotionFreqMaxHz &&
        cv < AppConstants.vehicleAmplitudeCvThresh &&
        mean > 0.05;  // Must have some motion — not just sensor noise

    // ── Mechanical vibration detection (EC-4.3) ──────────────────────
    // Signature: >5 Hz + very low CV (washing machine, dryer)
    final isMechanical = freq > AppConstants.mechanicalVibrationMinHz &&
        cv < AppConstants.vehicleAmplitudeCvThresh;

    // ── Fall detection (EC-2.3) ──────────────────────────────────────
    // Spike >15 m/s² THIS window + check if stillness follows
    final currentOrientation = _computeOrientation(xs, ys, zs);
    final orientationChanged  = currentOrientation != _lastOrientation &&
        _lastOrientation != _Orientation.unknown;
    _lastOrientation = currentOrientation;

    // Fall = spike detected + orientation changed + now still
    final isFall = _spikeDetectedThisWindow &&
        orientationChanged &&
        mean < AppConstants.sleepStillnessThreshold * 2;

    final wasSpike = _spikeDetectedThisWindow;
    _spikeDetectedThisWindow = false;

    _snapshotController.add(MotionSnapshot(
      magnitude:                 mean,
      dominantFreqHz:            freq,
      amplitudeCv:               cv,
      looksLikeVehicleMotion:    isVehicle,
      looksLikeMechanicalVibration: isMechanical,
      fallSpikeDetected:         isFall,
      peakAcceleration:          peak,
      orientation:               currentOrientation,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ORIENTATION CLASSIFICATION
  // Used for fall detection — if the phone changes from face-up to
  // landscape after a spike, it has likely been dropped.
  // ─────────────────────────────────────────────────────────────────────────
  _Orientation _computeOrientation(
    List<double> xs,
    List<double> ys,
    List<double> zs,
  ) {
    if (xs.isEmpty) return _Orientation.unknown;

    // Use last sample (most current)
    final x = xs.last;
    final y = ys.last;
    final z = zs.last;

    final az = z / math.sqrt(x * x + y * y + z * z);

    // az ≈ 1.0 = face up, az ≈ -1.0 = face down
    if (az > 0.75)  return _Orientation.faceUp;
    if (az < -0.75) return _Orientation.faceDown;

    final ax = x / math.sqrt(x * x + y * y + z * z);
    if (ax.abs() > 0.70) return _Orientation.landscape;
    return _Orientation.portrait;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ZERO-CROSSING FREQUENCY ESTIMATE
  // ─────────────────────────────────────────────────────────────────────────
  double _zeroCrossingFreq(List<double> signal, {required double sampleRateHz}) {
    if (signal.length < 4) return 0.0;
    final mean  = signal.reduce((a, b) => a + b) / signal.length;
    int crossings = 0;
    for (int i = 1; i < signal.length; i++) {
      if ((signal[i] - mean) * (signal[i - 1] - mean) < 0) crossings++;
    }
    return (crossings / 2.0) / (signal.length / sampleRateHz);
  }

  void _clearBuffers() {
    _xBuf.clear(); _yBuf.clear(); _zBuf.clear(); _magBuf.clear();
  }

  void dispose() {
    stop();
    _snapshotController.close();
  }
}
```

---

## FILE 2: lib/core/services/sleep_detection_service.dart
## PATH: lib/core/services/sleep_detection_service.dart
## PURPOSE: The main sleep lifecycle engine. Owns the state machine.
##          Integrates motion, screen state, thermal, vehicle detection.
## EDGE CASES:
##   EC-4.1: Vehicle motion → travel mode (screen-only sleep proxy)
##   EC-4.2: Baby/partner motion → micro-waking, NOT sleep end
##   EC-4.3: Appliance vibration → filtered out (isAmbientMotion)
##   EC-4.4: Bathroom trip → <5 min screen use = night waking event
##   EC-4.5: All-nighter → noSleepDetected flag, alarm fires normally
##   EC-4.6: Shift worker → purely behavior-based, no time-of-day bias
##   EC-4.7: Nap mode → isNap flag, simple detection
##   EC-4.10: Honesty policy → all metrics labeled "estimated"
##   EC-2.2: Pillow advisory → shown once, based on dark+motion pattern
##   EC-2.3: Fall detection → volume boost flag passed to AlarmService

```dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/sleep_session.dart';
import '../models/alarm_model.dart';
import 'motion_analyzer.dart';
import 'thermal_monitor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP STATE
// The state machine's current position.
// ─────────────────────────────────────────────────────────────────────────────
enum SleepState {
  awake,
  preSleep,     // Screen off + still — confirming for 3 minutes
  sleeping,     // Sleep onset committed
  microWaking,  // Brief disturbance during sleep (EC-4.2, EC-4.4)
}

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP SESSION CONTEXT
// Live context for the current session — NOT the Hive model.
// This is the in-memory working state.
// ─────────────────────────────────────────────────────────────────────────────
class SleepSessionContext {
  final String   sessionId;
  final DateTime screenOffAt;        // When screen first went dark
  DateTime?      sleepOnsetAt;       // Committed sleep onset time
  DateTime?      microWakingStartAt;
  bool           travelModeActive    = false;
  bool           fallDetectedDuring  = false;
  double         maxVolumeBoost      = 0.0;  // EC-2.3 fall compensation
  int            nightWakingCount    = 0;
  List<Map<String, dynamic>> microWakingEvents = [];
  int            vehicleWindowCount  = 0;   // Consecutive vehicle snapshots
  bool           isNap               = false;
  String         timezoneAtSleep     = '';

  SleepSessionContext({
    required this.sessionId,
    required this.screenOffAt,
    this.isNap = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP DETECTION SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class SleepDetectionService {
  static final SleepDetectionService _instance =
      SleepDetectionService._internal();
  factory SleepDetectionService() => _instance;
  SleepDetectionService._internal();

  final _motionAnalyzer  = MotionAnalyzer();
  final _thermalMonitor  = ThermalMonitor();

  SleepState           _state       = SleepState.awake;
  SleepSessionContext? _ctx;
  Timer?               _preSleepTimer;
  Timer?               _microWakingTimer;
  Timer?               _screenOnTimer;

  // How long the screen has been continuously off
  DateTime? _screenOffSince;
  bool      _screenCurrentlyOff = false;

  StreamSubscription<MotionSnapshot>? _motionSub;

  // Public state stream
  final _stateController = StreamController<SleepState>.broadcast();
  Stream<SleepState> get stateStream => _stateController.stream;
  SleepState get currentState => _state;

  // Platform channel for screen state (defined in native layer — Part 3)
  static const _channel = MethodChannel('com.rise.alarmclock/capabilities');

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZE
  // Call from AlarmService.initialize() so sleep detection starts
  // whenever there's an active alarm set.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _motionAnalyzer.start();

    _motionSub = _motionAnalyzer.snapshots.listen(_onMotionSnapshot);

    // Poll screen state every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (_) => _checkScreenState());

    // EC-2.2 thermal check every 5 minutes (when sleeping)
    Timer.periodic(const Duration(minutes: 5), (_) {
      if (_state == SleepState.sleeping) _checkThermal();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN STATE CHANGED
  // Called from AlarmService (which receives a broadcast from native code
  // when screen turns on/off). This is the primary sleep signal.
  // ─────────────────────────────────────────────────────────────────────────
  void onScreenOff() {
    _screenCurrentlyOff = true;
    _screenOffSince = DateTime.now();
    _screenOnTimer?.cancel();

    // Only transition to pre-sleep if:
    // (a) we're currently awake, AND
    // (b) an alarm is set within the next 16 hours (EC-4.6 shift workers)
    if (_state == SleepState.awake && _hasUpcomingAlarm()) {
      _startPreSleepWindow();
    }
  }

  void onScreenOn() {
    _screenCurrentlyOff = false;

    switch (_state) {
      case SleepState.preSleep:
        // Screen came back on before we committed sleep — cancel
        _cancelPreSleep('screen_on_during_pre_sleep');
        break;

      case SleepState.sleeping:
        // EC-4.4: Screen on DURING sleep — start the 5-minute grace window.
        // If screen goes back off within 5 min = night waking (bathroom).
        // If screen stays on > 5 min = actually awake.
        _startMicroWakingWindow(isScreenEvent: true);
        break;

      case SleepState.microWaking:
        // Already tracking — reset the micro-waking timer
        _microWakingTimer?.cancel();
        _startMicroWakingWindow(isScreenEvent: true);
        break;

      case SleepState.awake:
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ON MOTION SNAPSHOT
  // Receives a MotionSnapshot every 5 seconds from MotionAnalyzer.
  // ─────────────────────────────────────────────────────────────────────────
  void _onMotionSnapshot(MotionSnapshot snap) {
    // ── EC-2.3: Fall detection ────────────────────────────────────────
    if (snap.fallSpikeDetected && _state == SleepState.sleeping && _ctx != null) {
      _ctx!.fallDetectedDuring = true;
      _ctx!.maxVolumeBoost     = AppConstants.fallVolumeBoostPercent;
      _logEvent('fall_detected_during_sleep');
      // AlarmService reads ctx.maxVolumeBoost when alarm fires
    }

    // ── EC-4.1 & EC-4.3: Ambient motion detection ─────────────────────
    if (snap.isAmbientMotion && _ctx != null) {
      if (snap.looksLikeVehicleMotion) {
        _ctx!.vehicleWindowCount++;
        // EC-4.1: After 10 consecutive vehicle-pattern minutes (2 snapshots/min × 10)
        if (_ctx!.vehicleWindowCount >= 20 && !_ctx!.travelModeActive) {
          _activateTravelMode();
        }
      }
      // In travel mode OR appliance vibration: treat phone as "still" for
      // sleep detection purposes — user is actually sleeping (EC-4.1, EC-4.3)
    } else {
      if (_ctx != null) _ctx!.vehicleWindowCount = 0;
    }

    switch (_state) {
      case SleepState.preSleep:
        // In travel mode: screen-off IS the sleep proxy — motion is irrelevant
        if (_ctx?.travelModeActive ?? false) break;

        // Non-ambient significant motion cancels pre-sleep window
        if (!snap.isStill && !snap.isAmbientMotion) {
          _cancelPreSleep('motion_during_pre_sleep');
        }
        break;

      case SleepState.sleeping:
        // EC-4.2: Brief motion during sleep — might be baby, partner, or pet
        // Only trigger micro-waking if it's NOT ambient motion
        if (!snap.isStill && !snap.isAmbientMotion) {
          if (_state == SleepState.sleeping) {
            _startMicroWakingWindow(isScreenEvent: false);
          }
        }
        break;

      case SleepState.microWaking:
        // If phone is still again and screen is off → resume sleeping
        if (snap.isStill && _screenCurrentlyOff) {
          _resumeSleeping('stillness_restored');
        }
        break;

      case SleepState.awake:
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // START PRE-SLEEP WINDOW
  // Enters the 3-minute confirmation window before committing sleep onset.
  // ─────────────────────────────────────────────────────────────────────────
  void _startPreSleepWindow() {
    final alarmId = _getNextAlarmId();
    if (alarmId == null) return;

    _ctx = SleepSessionContext(
      sessionId:   _generateId(),
      screenOffAt: _screenOffSince ?? DateTime.now(),
      isNap:       _isNextAlarmNap(),
    );
    _ctx!.timezoneAtSleep = DateTime.now().timeZoneName;

    _setState(SleepState.preSleep);

    // Commit sleep onset after 3 minutes of sustained stillness
    _preSleepTimer = Timer(
      Duration(minutes: AppConstants.sleepPreSleepWindowMinutes),
      () => _commitSleepOnset(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMMIT SLEEP ONSET
  // The confirmation window passed — we're declaring the user is asleep.
  // Sleep onset time is backdated to when the screen first went off.
  // EC-4.6: No time-of-day check — purely behavior-based.
  // ─────────────────────────────────────────────────────────────────────────
  void _commitSleepOnset() {
    if (_ctx == null) return;

    // Backdate onset to screen-off time (not the confirmation end time)
    _ctx!.sleepOnsetAt = _ctx!.screenOffAt;

    _setState(SleepState.sleeping);
    _logEvent('sleep_onset_committed');

    // EC-2.2: Check for possible under-pillow scenario
    _checkPillowAdvisory();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL PRE-SLEEP WINDOW
  // ─────────────────────────────────────────────────────────────────────────
  void _cancelPreSleep(String reason) {
    _preSleepTimer?.cancel();
    _ctx = null;
    _setState(SleepState.awake);
    _logEvent('pre_sleep_cancelled: $reason');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MICRO-WAKING WINDOW (EC-4.2, EC-4.4)
  // Brief disturbance detected. Wait up to microWakingScreenMinutes (5 min)
  // before deciding if this is genuine waking or a brief interruption.
  // ─────────────────────────────────────────────────────────────────────────
  void _startMicroWakingWindow({required bool isScreenEvent}) {
    if (_ctx == null) return;

    _ctx!.microWakingStartAt = DateTime.now();
    _setState(SleepState.microWaking);
    _microWakingTimer?.cancel();

    // Grace period: 5 minutes for screen events (bathroom trip)
    // 15 seconds for motion-only events (baby grabbed phone)
    final gracePeriod = isScreenEvent
        ? Duration(minutes: AppConstants.nightWakingMaxMinutes)
        : Duration(seconds: AppConstants.microWakingMaxSeconds);

    _microWakingTimer = Timer(gracePeriod, () {
      // Grace period expired — this is genuine waking
      _endSleepSession(reason: isScreenEvent ? 'sustained_screen_use' : 'sustained_motion');
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESUME SLEEPING (after micro-waking)
  // ─────────────────────────────────────────────────────────────────────────
  void _resumeSleeping(String reason) {
    _microWakingTimer?.cancel();
    if (_ctx == null) return;

    // Log this as a night waking micro-event (sleep quality metric)
    _ctx!.nightWakingCount++;
    if (_ctx!.microWakingStartAt != null) {
      _ctx!.microWakingEvents.add({
        'at':       _ctx!.microWakingStartAt!.millisecondsSinceEpoch,
        'duration': DateTime.now()
            .difference(_ctx!.microWakingStartAt!)
            .inSeconds,
        'reason':   reason,
      });
    }
    _ctx!.microWakingStartAt = null;

    _setState(SleepState.sleeping);
    _logEvent('micro_waking_resolved: $reason');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // END SLEEP SESSION
  // Called either by alarm dismissal (normal path) or by sustained waking.
  // Returns the completed SleepSession for saving and scoring.
  // ─────────────────────────────────────────────────────────────────────────
  Future<SleepSession?> endSleepSession({
    required String alarmId,
    required String dismissMethod,
    double?  avgHrAtWake,
    bool     identityVerified = false,
    bool     buddyNotified    = false,
  }) async {
    if (_ctx == null) {
      // EC-4.5: No sleep detected — return a minimal no-sleep session
      return _buildNoSleepSession(alarmId: alarmId, dismissMethod: dismissMethod);
    }

    final ctx     = _ctx!;
    final onset   = ctx.sleepOnsetAt ?? ctx.screenOffAt;
    final wakeNow = DateTime.now();

    final session = SleepSession(
      sleepOnsetTime:      onset,
      wakeTime:            wakeNow,
      alarmId:             alarmId,
      snoozeCount:         0,       // Updated by AlarmService
      dismissMethod:       dismissMethod,
      detectionMethod:     ctx.travelModeActive ? 'screen' : 'accelerometer',
      motionData:          [],      // Raw data not stored (privacy + size)
      avgHeartRateAtWake:  avgHrAtWake,
      identityVerified:    identityVerified,
      buddyNotified:       buddyNotified,
      qualityLabel:        'unknown',  // Computed by SleepQualityScorer
      isNap:               ctx.isNap,
      noSleepDetected:     false,
      travelModeActive:    ctx.travelModeActive,
      nightWakingCount:    ctx.nightWakingCount,
      fallDetected:        ctx.fallDetectedDuring,
      timezoneAtSleep:     ctx.timezoneAtSleep,
      microWakingEvents:   ctx.microWakingEvents,
    );

    // Save to Hive
    final box = Hive.box<dynamic>(AppConstants.sleepSessionsBoxName);
    await box.put(session.id, session);

    _ctx = null;
    _setState(SleepState.awake);
    _logEvent('sleep_session_ended: $dismissMethod');

    return session;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NO-SLEEP SESSION (EC-4.5: all-nighter)
  // Alarm fires but no sleep onset was ever detected.
  // RISE fires normally. No biometric check. No guilt message. (Bible rule)
  // ─────────────────────────────────────────────────────────────────────────
  SleepSession _buildNoSleepSession({
    required String alarmId,
    required String dismissMethod,
  }) {
    final session = SleepSession(
      sleepOnsetTime:  DateTime.now().subtract(const Duration(minutes: 1)),
      wakeTime:        DateTime.now(),
      alarmId:         alarmId,
      dismissMethod:   dismissMethod,
      detectionMethod: 'none',
      qualityLabel:    'unknown',
      noSleepDetected: true,     // EC-4.5: internal flag only — NOT shown to user
    );

    final box = Hive.box<dynamic>(AppConstants.sleepSessionsBoxName);
    box.put(session.id, session);

    return session;
  }

  void _endSleepSession({required String reason}) {
    _logEvent('sleep_session_ended_internally: $reason');
    _ctx = null;
    _setState(SleepState.awake);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TRAVEL MODE ACTIVATION (EC-4.1)
  // Switches from accelerometer-based to screen-based sleep detection.
  // ─────────────────────────────────────────────────────────────────────────
  void _activateTravelMode() {
    if (_ctx == null) return;
    _ctx!.travelModeActive = true;
    _logEvent('travel_mode_activated');
    // Note: SleepTrackerScreen reads ctx.travelModeActive to display
    // "Looks like you're moving — RISE switched to travel mode."
    // This is shown as a one-time informational banner, not a persistent alert.
  }

  // ─────────────────────────────────────────────────────────────────────────
  // THERMAL / PILLOW CHECKS (EC-2.2)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _checkThermal() async {
    final level = await _thermalMonitor.getThermalState();
    if (level == ThermalLevel.severe || level == ThermalLevel.critical) {
      // AlarmService picks this up on alarm fire to show the warning
      if (_ctx != null) {
        final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
        await box.put('pending_thermal_warning', level.name);
      }
    }
  }

  Future<void> _checkPillowAdvisory() async {
    // EC-2.2: Show bedtime advisory ONCE if under-pillow conditions detected.
    // Condition: ambient light ≈ zero (screen off in dark) + phone moved at bedtime.
    // We approximate "ambient darkness" by noting the phone was set down at
    // a time consistent with bedtime behavior (screen off + became still).
    final prefs = await SharedPreferences.getInstance();
    final shownBefore = prefs.getBool('pillow_advisory_shown') ?? false;
    if (shownBefore) return;

    // Simple heuristic: if screen went off between 9pm and 3am = bedtime
    final hour = _ctx?.screenOffAt.hour ?? 0;
    final likelyBedtime = hour >= 21 || hour <= 3;

    if (likelyBedtime) {
      // Set a flag that SleepTrackerScreen will pick up and display once
      await prefs.setString('pending_pillow_advisory',
          'Sleeping with your phone under a pillow can cause overheating. '
          'Place it on the nightstand instead.');
      await prefs.setBool('pillow_advisory_shown', true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN STATE POLLING
  // Platform channel call to check if the screen is currently on.
  // The MethodChannel 'isPhoneActive' was defined in Part 3 (RiseAlarmPlugin.kt).
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _checkScreenState() async {
    try {
      final isActive = await _channel.invokeMethod<bool>('isPhoneActive') ?? false;
      if (isActive && _screenCurrentlyOff) {
        onScreenOn();
      } else if (!isActive && !_screenCurrentlyOff) {
        onScreenOff();
      }
    } catch (_) {
      // Platform channel unavailable — continue with last known state
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE CONTEXT ACCESSORS
  // Called by AlarmService to incorporate sleep data at alarm fire time.
  // ─────────────────────────────────────────────────────────────────────────

  /// Was sleep detected before this alarm? (EC-4.5 check)
  bool get sleepWasDetected =>
      _state == SleepState.sleeping || _state == SleepState.microWaking;

  /// Should the alarm volume ceiling be boosted? (EC-2.3 fall)
  double get volumeBoostPercent => _ctx?.maxVolumeBoost ?? 0.0;

  /// Was the phone in travel mode? (EC-4.1)
  bool get travelModeActive => _ctx?.travelModeActive ?? false;

  /// Did the phone fall during sleep? (EC-2.3)
  bool get fallDetectedDuringSleep => _ctx?.fallDetectedDuring ?? false;

  /// Current timezone (for EC-5.4 timezone-change detection)
  String get timezoneAtSleep => _ctx?.timezoneAtSleep ?? '';

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  bool _hasUpcomingAlarm() {
    final box    = Hive.box<dynamic>(AppConstants.alarmsBoxName);
    final now    = DateTime.now();
    final cutoff = now.add(Duration(hours: AppConstants.sleepAlarmWindowHours));
    return box.values
        .whereType<AlarmModel>()
        .any((a) => a.isEnabled && a.nextFireTime.isAfter(now) &&
            a.nextFireTime.isBefore(cutoff));
  }

  bool _isNextAlarmNap() {
    final box = Hive.box<dynamic>(AppConstants.alarmsBoxName);
    final now = DateTime.now();
    return box.values
        .whereType<AlarmModel>()
        .where((a) => a.isEnabled && a.nextFireTime.isAfter(now))
        .fold<AlarmModel?>(null, (prev, a) =>
            prev == null || a.nextFireTime.isBefore(prev.nextFireTime) ? a : prev)
        ?.isNap ?? false;
  }

  String? _getNextAlarmId() {
    final box = Hive.box<dynamic>(AppConstants.alarmsBoxName);
    final now = DateTime.now();
    final next = box.values
        .whereType<AlarmModel>()
        .where((a) => a.isEnabled && a.nextFireTime.isAfter(now))
        .fold<AlarmModel?>(null, (prev, a) =>
            prev == null || a.nextFireTime.isBefore(prev.nextFireTime) ? a : prev);
    return next?.id;
  }

  void _setState(SleepState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  String _generateId() =>
      'sleep_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _logEvent(String event) async {
    // Analytics — Firebase, Part 12
  }

  void dispose() {
    _preSleepTimer?.cancel();
    _microWakingTimer?.cancel();
    _screenOnTimer?.cancel();
    _motionSub?.cancel();
    _motionAnalyzer.dispose();
    _thermalMonitor.dispose();
    _stateController.close();
  }
}
```

---

## FILE 3: lib/core/services/thermal_monitor.dart
## PATH: lib/core/services/thermal_monitor.dart
## PURPOSE: Device temperature monitoring. EC-2.2 phone-under-pillow
##          overheating detection. Cross-platform: Android PowerManager
##          thermalStatus, iOS ProcessInfo.thermalState.

```dart
import 'dart:io';
import 'package:flutter/services.dart';

enum ThermalLevel { nominal, fair, serious, severe, critical, unknown }

class ThermalMonitor {
  static const _channel = MethodChannel('com.rise.alarmclock/capabilities');

  Future<ThermalLevel> getThermalState() async {
    try {
      if (Platform.isAndroid) {
        // Android API 29+: PowerManager.getThermalHeadroom()
        // Returns: THERMAL_STATUS_NONE(0), LIGHT(1), MODERATE(2),
        //          SEVERE(3), CRITICAL(4), EMERGENCY(5), SHUTDOWN(6)
        final level = await _channel.invokeMethod<int>('getThermalStatus') ?? 0;
        return switch (level) {
          0     => ThermalLevel.nominal,
          1     => ThermalLevel.fair,
          2     => ThermalLevel.serious,
          3     => ThermalLevel.severe,
          >= 4  => ThermalLevel.critical,
          _     => ThermalLevel.unknown,
        };
      } else if (Platform.isIOS) {
        // iOS: ProcessInfo.ThermalState
        // Returns: 0=nominal, 1=fair, 2=serious, 3=critical
        final level = await _channel.invokeMethod<int>('getThermalStatus') ?? 0;
        return switch (level) {
          0 => ThermalLevel.nominal,
          1 => ThermalLevel.fair,
          2 => ThermalLevel.serious,
          3 => ThermalLevel.critical,
          _ => ThermalLevel.unknown,
        };
      }
    } catch (_) {}
    return ThermalLevel.unknown;
  }

  bool isConcerning(ThermalLevel level) =>
      level == ThermalLevel.severe || level == ThermalLevel.critical;

  void dispose() {}
}
```

## NATIVE: Add to RiseAlarmPlugin.kt (inside when(call.method) block):
```kotlin
"getThermalStatus" -> {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val pm = context.getSystemService(Context.POWER_SERVICE)
            as android.os.PowerManager
        // getThermalHeadroom requires API 31+
        val status = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            when (pm.currentThermalStatus) {
                android.os.PowerManager.THERMAL_STATUS_NONE     -> 0
                android.os.PowerManager.THERMAL_STATUS_LIGHT    -> 1
                android.os.PowerManager.THERMAL_STATUS_MODERATE -> 2
                android.os.PowerManager.THERMAL_STATUS_SEVERE   -> 3
                android.os.PowerManager.THERMAL_STATUS_CRITICAL -> 4
                else -> 0
            }
        } else 0
        result.success(status)
    } else {
        result.success(0)
    }
}
```

## NATIVE: Add to AppDelegate.swift (inside methodChannel handler):
```swift
case "getThermalStatus":
    let state = ProcessInfo.processInfo.thermalState
    let level: Int
    switch state {
    case .nominal:  level = 0
    case .fair:     level = 1
    case .serious:  level = 2
    case .critical: level = 3
    @unknown default: level = 0
    }
    result(level)
```

---

## FILE 4: lib/core/services/sleep_quality_scorer.dart
## PATH: lib/core/services/sleep_quality_scorer.dart
## PURPOSE: Scores a completed SleepSession 0–100 and assigns quality
##          label. Estimates sleep phase breakdown (REM/deep/light/awake).
##          All outputs are explicitly marked "estimated" — EC-4.10
##          honesty policy. No sensor fusion guarantees real phase data.

```dart
import 'dart:math' as math;
import '../models/sleep_session.dart';
import '../constants/app_constants.dart';

class ScoredSession {
  final int    score;          // 0–100
  final String qualityLabel;  // 'excellent' | 'good' | 'fair' | 'poor'
  final int    estimatedRemMinutes;
  final int    estimatedDeepMinutes;
  final int    estimatedLightMinutes;
  final int    awakeMinutes;
  final String scoreBreakdown; // Human-readable explanation (for UI)

  const ScoredSession({
    required this.score,
    required this.qualityLabel,
    required this.estimatedRemMinutes,
    required this.estimatedDeepMinutes,
    required this.estimatedLightMinutes,
    required this.awakeMinutes,
    required this.scoreBreakdown,
  });
}

class SleepQualityScorer {
  // ─────────────────────────────────────────────────────────────────────────
  // SCORE SESSION
  // All factors weighted to produce a 0–100 score.
  // EC-4.10: Every output labeled "estimated" in the UI layer.
  // ─────────────────────────────────────────────────────────────────────────
  ScoredSession score(SleepSession session) {
    // ── Guard: no-sleep session (EC-4.5 all-nighter) ─────────────────
    if (session.noSleepDetected) {
      return _noSleepScore(session);
    }

    // ── Guard: nap session (EC-4.7) ──────────────────────────────────
    if (session.isNap) {
      return _napScore(session);
    }

    final durationMins = session.durationMinutes.clamp(0, 600);

    // ── Factor 1: Duration (weight 40%) ──────────────────────────────
    // Optimal: 420–540 min (7–9 hours). Below 360 (6h) scores poorly.
    double durationScore;
    if      (durationMins >= 420 && durationMins <= 540) durationScore = 100;
    else if (durationMins >= 360 && durationMins <  420) durationScore = 80;
    else if (durationMins >= 300 && durationMins <  360) durationScore = 60;
    else if (durationMins >= 240 && durationMins <  300) durationScore = 40;
    else if (durationMins >= 180 && durationMins <  240) durationScore = 25;
    else if (durationMins >  540)                        durationScore = 85; // Oversleeping
    else                                                 durationScore = 10;

    // ── Factor 2: Night waking count (weight 25%) ────────────────────
    // 0 wakings = 100, each waking reduces score
    final wakings = session.nightWakingCount;
    double wakingScore;
    if      (wakings == 0) wakingScore = 100;
    else if (wakings == 1) wakingScore = 85;
    else if (wakings == 2) wakingScore = 65;
    else if (wakings == 3) wakingScore = 45;
    else                   wakingScore = 25;

    // ── Factor 3: Snooze stubbornness (weight 15%) ───────────────────
    // Snoozing a lot = fragmented sleep or alarm resistance
    final snoozes = session.snoozeCount;
    double snoozeScore;
    if      (snoozes == 0) snoozeScore = 100;
    else if (snoozes == 1) snoozeScore = 80;
    else if (snoozes == 2) snoozeScore = 60;
    else if (snoozes == 3) snoozeScore = 40;
    else                   snoozeScore = 20;

    // ── Factor 4: Sleep timing consistency (weight 20%) ──────────────
    // Compare this session's onset time to the rolling average of the last
    // 7 sessions. Consistent sleep times → better circadian rhythm.
    final consistencyScore = _computeConsistencyScore(session);

    // ── Weighted total ────────────────────────────────────────────────
    final total = (durationScore   * AppConstants.qualityDurationWeight) +
                  (wakingScore     * AppConstants.qualityMotionWeight)   +
                  (consistencyScore * AppConstants.qualityConsistencyWeight) +
                  (snoozeScore     * AppConstants.qualitySnoozeWeight);

    final finalScore = total.round().clamp(0, 100);

    // ── Quality label ─────────────────────────────────────────────────
    final label = switch (finalScore) {
      >= 85 => 'excellent',
      >= 70 => 'good',
      >= 50 => 'fair',
      _     => 'poor',
    };

    // ── Estimated phase breakdown ─────────────────────────────────────
    // EC-4.10: These are population-average estimates, not measured.
    // The UI must always label them "estimated."
    // Standard sleep architecture: 20-25% REM, 15-20% deep, rest light/awake
    final awakeMins = session.nightWakingCount * 5; // Rough estimate
    final sleepMins = (durationMins - awakeMins).clamp(0, 600);
    final remMins   = (sleepMins * 0.22).round();
    final deepMins  = (sleepMins * 0.18).round();
    final lightMins = (sleepMins - remMins - deepMins).clamp(0, sleepMins);

    // ── Score breakdown text ──────────────────────────────────────────
    final breakdown = _buildBreakdown(
      durationScore:    durationScore.round(),
      wakingScore:      wakingScore.round(),
      snoozeScore:      snoozeScore.round(),
      consistencyScore: consistencyScore.round(),
      durationMins:     durationMins,
      wakingCount:      wakings,
    );

    return ScoredSession(
      score:                  finalScore,
      qualityLabel:           label,
      estimatedRemMinutes:    remMins,
      estimatedDeepMinutes:   deepMins,
      estimatedLightMinutes:  lightMins,
      awakeMinutes:           awakeMins,
      scoreBreakdown:         breakdown,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONSISTENCY SCORE
  // Compares tonight's sleep onset hour to the user's 7-day rolling average.
  // Within 30 min = 100, within 1h = 75, within 2h = 50, > 2h = 20.
  // ─────────────────────────────────────────────────────────────────────────
  double _computeConsistencyScore(SleepSession session) {
    final box = Hive.box<dynamic>(AppConstants.sleepSessionsBoxName);
    final sessions = box.values
        .whereType<SleepSession>()
        .where((s) => s.id != session.id && !s.isNap && !s.noSleepDetected)
        .toList()
        ..sort((a, b) => b.sleepOnsetTime.compareTo(a.sleepOnsetTime));

    if (sessions.length < 3) {
      return 70.0; // Not enough history — return neutral score
    }

    final recent  = sessions.take(7).toList();
    final avgHour = recent
            .map((s) => s.sleepOnsetTime.hour + s.sleepOnsetTime.minute / 60.0)
            .reduce((a, b) => a + b) /
        recent.length;

    final thisHour = session.sleepOnsetTime.hour +
        session.sleepOnsetTime.minute / 60.0;

    // Handle midnight wrap-around (e.g., 23:30 vs 00:30 = only 1 hour apart)
    double delta = (thisHour - avgHour).abs();
    if (delta > 12) delta = 24 - delta;

    if      (delta <= 0.5) return 100.0;
    else if (delta <= 1.0) return 75.0;
    else if (delta <= 2.0) return 50.0;
    else                   return 20.0;
  }

  ScoredSession _noSleepScore(SleepSession session) {
    // EC-4.5: All-nighter. RISE doesn't show a score or any guilt message.
    // Return a neutral "unknown" score — the UI hides the score card.
    return ScoredSession(
      score:                 0,
      qualityLabel:          'unknown',
      estimatedRemMinutes:   0,
      estimatedDeepMinutes:  0,
      estimatedLightMinutes: 0,
      awakeMinutes:          0,
      scoreBreakdown:        '',
    );
  }

  ScoredSession _napScore(SleepSession session) {
    // EC-4.7: Nap — simplified scoring (duration only)
    final durationMins = session.durationMinutes;
    final score = switch (durationMins) {
      >= 15 && < 30 => 90,  // Power nap — optimal
      >= 10 && < 15 => 75,
      >= 30 && < 60 => 70,  // Longer nap — potentially groggy
      >= 60         => 50,  // Very long nap — sleep inertia risk
      _             => 40,
    };

    return ScoredSession(
      score:                 score,
      qualityLabel:          score >= 70 ? 'good' : 'fair',
      estimatedRemMinutes:   0,
      estimatedDeepMinutes:  (session.durationMinutes * 0.10).round(),
      estimatedLightMinutes: session.durationMinutes,
      awakeMinutes:          0,
      scoreBreakdown:        'Nap: ${session.durationMinutes} minutes',
    );
  }

  String _buildBreakdown({
    required int durationScore,
    required int wakingScore,
    required int snoozeScore,
    required int consistencyScore,
    required int durationMins,
    required int wakingCount,
  }) {
    final hours = durationMins ~/ 60;
    final mins  = durationMins % 60;
    final durStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    final parts = <String>[];
    if (durationScore < 70)   parts.add('$durStr of sleep (aim for 7–9h)');
    if (wakingCount > 0)      parts.add('$wakingCount interruption${wakingCount > 1 ? 's' : ''}');
    if (snoozeScore < 70)     parts.add('multiple snoozes');
    if (consistencyScore < 70) parts.add('irregular sleep timing');

    return parts.isEmpty ? 'Well done!' : parts.join(' · ');
  }
}
```

---

## FILE 5: lib/core/providers/sleep_detection_provider.dart
## PATH: lib/core/providers/sleep_detection_provider.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/sleep_session.dart';
import '../services/sleep_detection_service.dart';
import '../services/sleep_quality_scorer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────
final sleepDetectionServiceProvider = Provider<SleepDetectionService>(
  (ref) {
    final svc = SleepDetectionService();
    ref.onDispose(svc.dispose);
    return svc;
  },
);

final sleepQualityScorerProvider = Provider<SleepQualityScorer>(
  (_) => SleepQualityScorer(),
);

// ─────────────────────────────────────────────────────────────────────────────
// LIVE SLEEP STATE
// Streams the current SleepState so the UI can show live status.
// ─────────────────────────────────────────────────────────────────────────────
final sleepStateProvider = StreamProvider<SleepState>((ref) {
  final svc = ref.watch(sleepDetectionServiceProvider);
  return svc.stateStream;
});

final isSleepingProvider = Provider<bool>((ref) {
  return ref.watch(sleepStateProvider).maybeWhen(
    data: (s) => s == SleepState.sleeping || s == SleepState.microWaking,
    orElse: () => false,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// SESSION HISTORY
// ─────────────────────────────────────────────────────────────────────────────
final sleepSessionsProvider = Provider<List<SleepSession>>((ref) {
  final box = Hive.box<dynamic>(AppConstants.sleepSessionsBoxName);
  final all = box.values
      .whereType<SleepSession>()
      .toList()
    ..sort((a, b) => b.sleepOnsetTime.compareTo(a.sleepOnsetTime));
  return all;
});

final lastNightSessionProvider = Provider<SleepSession?>((ref) {
  final sessions = ref.watch(sleepSessionsProvider);
  return sessions.isNotEmpty ? sessions.first : null;
});

final lastNightScoredProvider = Provider<ScoredSession?>((ref) {
  final session = ref.watch(lastNightSessionProvider);
  if (session == null) return null;
  final scorer = ref.watch(sleepQualityScorerProvider);
  return scorer.score(session);
});

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP TREND (last 7 days)
// ─────────────────────────────────────────────────────────────────────────────
final sleepTrendProvider = Provider<List<ScoredSession>>((ref) {
  final sessions = ref.watch(sleepSessionsProvider);
  final scorer   = ref.watch(sleepQualityScorerProvider);
  final cutoff   = DateTime.now().subtract(const Duration(days: 7));
  return sessions
      .where((s) => s.sleepOnsetTime.isAfter(cutoff) && !s.isNap)
      .take(7)
      .map(scorer.score)
      .toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// AVERAGE SLEEP DURATION (last 7 days)
// ─────────────────────────────────────────────────────────────────────────────
final avgSleepDurationProvider = Provider<Duration>((ref) {
  final trend = ref.watch(sleepTrendProvider);
  if (trend.isEmpty) return Duration.zero;
  final scored = ref.watch(sleepSessionsProvider)
      .where((s) => s.sleepOnsetTime
          .isAfter(DateTime.now().subtract(const Duration(days: 7))))
      .toList();
  if (scored.isEmpty) return Duration.zero;
  final totalMins = scored
      .map((s) => s.durationMinutes)
      .reduce((a, b) => a + b);
  return Duration(minutes: (totalMins / scored.length).round());
});
```

---

## FILE 6: lib/features/sleep/sleep_tracker_screen.dart
## PATH: lib/features/sleep/sleep_tracker_screen.dart
## PURPOSE: The Sleep tab. Shows last night's session card, 7-day trend,
##          pillow advisory (once), EC-4.10 honesty labels everywhere.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/sleep_session.dart';
import '../../core/providers/sleep_detection_provider.dart';
import '../../core/services/sleep_detection_service.dart';

class SleepTrackerScreen extends ConsumerStatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  ConsumerState<SleepTrackerScreen> createState() =>
      _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends ConsumerState<SleepTrackerScreen> {
  String? _pillowAdvisory;
  bool    _travelBannerShown = false;

  @override
  void initState() {
    super.initState();
    _loadPendingAdvisories();
  }

  Future<void> _loadPendingAdvisories() async {
    final prefs   = await SharedPreferences.getInstance();
    final pillow  = prefs.getString('pending_pillow_advisory');
    if (pillow != null && mounted) {
      setState(() => _pillowAdvisory = pillow);
      await prefs.remove('pending_pillow_advisory');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(sleepStateProvider);
    final lastSession = ref.watch(lastNightSessionProvider);
    final lastScored  = ref.watch(lastNightScoredProvider);
    final trend       = ref.watch(sleepTrendProvider);
    final avgDuration = ref.watch(avgSleepDurationProvider);
    final svc         = ref.watch(sleepDetectionServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Header ────────────────────────────────────────────────
            Text('Sleep', style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),

            // ── EC-4.10 Honesty label ─────────────────────────────────
            // BIBLE RULE: Always label sleep metrics as estimated.
            Text(
              'Sleep estimated from screen-off time and motion. '
              'For greater accuracy, connect a wearable.',
              style: TextStyle(color: Colors.white.withOpacity(0.45),
                  fontSize: 12),
            ),

            const SizedBox(height: 20),

            // ── Pillow advisory (EC-2.2) — shown at most ONCE ─────────
            if (_pillowAdvisory != null)
              _AdvisoryBanner(
                message: _pillowAdvisory!,
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                onDismiss: () => setState(() => _pillowAdvisory = null),
              ),

            // ── Travel mode banner (EC-4.1) ───────────────────────────
            if (svc.travelModeActive && !_travelBannerShown)
              _AdvisoryBanner(
                message: "Looks like you were moving — RISE switched to "
                    "travel mode for sleep detection.",
                icon: Icons.directions_transit,
                color: Colors.blueAccent,
                onDismiss: () => setState(() => _travelBannerShown = true),
              ),

            // ── Live sleep state ──────────────────────────────────────
            state.when(
              data: (s) => _LiveStateCard(sleepState: s),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // ── Last night's session card ─────────────────────────────
            if (lastSession != null && lastScored != null)
              _SessionCard(session: lastSession, scored: lastScored)
            else
              _EmptySessionCard(),

            const SizedBox(height: 20),

            // ── 7-day average ─────────────────────────────────────────
            _AverageTile(avgDuration: avgDuration),

            const SizedBox(height: 20),

            // ── 7-day trend chart ─────────────────────────────────────
            if (trend.isNotEmpty) _TrendChart(trend: trend),

            const SizedBox(height: 20),

            // ── Recent sessions list ──────────────────────────────────
            _RecentSessionsList(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADVISORY BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _AdvisoryBanner extends StatelessWidget {
  final String   message;
  final IconData icon;
  final Color    color;
  final VoidCallback onDismiss;

  const _AdvisoryBanner({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin:  const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message,
                style: TextStyle(color: Colors.white.withOpacity(0.85),
                    fontSize: 13))),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: Colors.white38, size: 18),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE STATE CARD
// Shows current sleep detection status while app is open
// ─────────────────────────────────────────────────────────────────────────────
class _LiveStateCard extends StatelessWidget {
  final SleepState sleepState;
  const _LiveStateCard({required this.sleepState});

  @override
  Widget build(BuildContext context) {
    if (sleepState == SleepState.awake) return const SizedBox.shrink();

    final (label, color, icon) = switch (sleepState) {
      SleepState.preSleep    => ('Detecting sleep…', Colors.blueAccent, Icons.bedtime_outlined),
      SleepState.sleeping    => ('Sleeping', Colors.indigo, Icons.bedtime),
      SleepState.microWaking => ('Brief waking detected', Colors.orange, Icons.brightness_low),
      _                      => ('', Colors.transparent, Icons.bedtime),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final SleepSession session;
  final ScoredSession scored;

  const _SessionCard({required this.session, required this.scored});

  @override
  Widget build(BuildContext context) {
    final scoreColor = switch (scored.qualityLabel) {
      'excellent' => Colors.greenAccent,
      'good'      => Colors.lightGreenAccent,
      'fair'      => Colors.amber,
      _           => Colors.redAccent,
    };

    // EC-4.5: Don't show a score card for all-nighter sessions
    if (session.noSleepDetected) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Last night', style: _labelStyle()),
          const SizedBox(height: 8),
          const Text('No sleep detected',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 4),
          Text('(No data recorded — alarm fired normally)',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Last night', style: _labelStyle())),
          Text(
            scored.qualityLabel.toUpperCase(),
            style: TextStyle(color: scoreColor, fontSize: 12,
                fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ]),
        const SizedBox(height: 16),

        // Duration + score ring
        Row(children: [
          _BigStat(
            value: session.durationLabel,
            label: 'estimated sleep',  // EC-4.10: "estimated"
          ),
          const Spacer(),
          _ScoreRing(score: scored.score, color: scoreColor),
        ]),

        const SizedBox(height: 16),

        // Phase breakdown — all labeled "est."
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _PhaseStat(
              label: 'REM\n(est.)', value: '${scored.estimatedRemMinutes}m',
              color: Colors.purpleAccent),
          _PhaseStat(
              label: 'Deep\n(est.)', value: '${scored.estimatedDeepMinutes}m',
              color: Colors.indigoAccent),
          _PhaseStat(
              label: 'Light\n(est.)', value: '${scored.estimatedLightMinutes}m',
              color: Colors.blueAccent),
          _PhaseStat(
              label: 'Awake\n(est.)', value: '${scored.awakeMinutes}m',
              color: Colors.white38),
        ]),

        if (scored.scoreBreakdown.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Text(scored.scoreBreakdown,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],

        // Fall detected warning (EC-2.3)
        if (session.fallDetected) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.phone_android, color: Colors.orange, size: 14),
            const SizedBox(width: 6),
            const Text('Phone may have fallen during sleep — '
                'alarm volume was increased to compensate.',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
          ]),
        ],

        // Travel mode notice (EC-4.1)
        if (session.travelModeActive) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.directions_transit, color: Colors.blueAccent, size: 14),
            const SizedBox(width: 6),
            const Text('Travel mode was active — '
                'sleep tracked via screen-off time.',
                style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
          ]),
        ],
      ]),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color:        const Color(0xFF161628),
    borderRadius: BorderRadius.circular(16),
    border:       Border.all(color: Colors.white.withOpacity(0.07)),
  );

  TextStyle _labelStyle() => const TextStyle(
    color: Colors.white54, fontSize: 13, letterSpacing: 0.5);
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _BigStat extends StatelessWidget {
  final String value, label;
  const _BigStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300)),
      Text(label, style: const TextStyle(
          color: Colors.white38, fontSize: 12)),
    ],
  );
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 64, height: 64,
        child: CircularProgressIndicator(
          value:            score / 100,
          backgroundColor: Colors.white.withOpacity(0.08),
          color:           color,
          strokeWidth:     5,
        ),
      ),
      Text('$score', style: TextStyle(
          color: color, fontSize: 18, fontWeight: FontWeight.w700)),
    ],
  );
}

class _PhaseStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PhaseStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 16,
          fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(
          color: Colors.white38, fontSize: 10), textAlign: TextAlign.center),
    ],
  );
}

class _AverageTile extends StatelessWidget {
  final Duration avgDuration;
  const _AverageTile({required this.avgDuration});

  @override
  Widget build(BuildContext context) {
    final h = avgDuration.inHours;
    final m = avgDuration.inMinutes.remainder(60);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFF161628),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        const Icon(Icons.bar_chart, color: Colors.white38, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('7-day average', style: const TextStyle(
              color: Colors.white54, fontSize: 12)),
          Text(avgDuration == Duration.zero
              ? 'Not enough data'
              : '${h}h ${m}m estimated sleep',
              style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<ScoredSession> trend;
  const _TrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('7-day quality trend',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: trend.reversed.map((s) {
            final h = (s.score / 100 * 64).clamp(4.0, 64.0);
            final color = switch (s.qualityLabel) {
              'excellent' => Colors.greenAccent,
              'good'      => Colors.lightGreenAccent,
              'fair'      => Colors.amber,
              _           => Colors.redAccent,
            };
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 24, height: h,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${s.score}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EmptySessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color:        const Color(0xFF161628),
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: const Column(children: [
      Icon(Icons.bedtime_outlined, color: Colors.white24, size: 48),
      SizedBox(height: 12),
      Text('No sleep data yet',
          style: TextStyle(color: Colors.white54, fontSize: 16)),
      SizedBox(height: 4),
      Text('Set an alarm and let RISE track your sleep tonight.',
          style: TextStyle(color: Colors.white38, fontSize: 13),
          textAlign: TextAlign.center),
    ]),
  );
}

class _RecentSessionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sleepSessionsProvider).take(14).toList();
    final scorer   = ref.watch(sleepQualityScorerProvider);

    if (sessions.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('History',
            style: TextStyle(color: Colors.white54, fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...sessions.skip(1).map((s) {
          final scored = scorer.score(s);
          final color  = switch (scored.qualityLabel) {
            'excellent' => Colors.greenAccent,
            'good'      => Colors.lightGreenAccent,
            'fair'      => Colors.amber,
            _           => Colors.redAccent,
          };
          final day = '${s.sleepOnsetTime.day}/${s.sleepOnsetTime.month}';

          return Container(
            margin:  const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:        const Color(0xFF161628),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Text(day, style: const TextStyle(color: Colors.white54,
                  fontSize: 13, fontFamily: 'monospace')),
              const SizedBox(width: 16),
              Text(s.durationLabel, style: const TextStyle(
                  color: Colors.white70, fontSize: 14)),
              const Spacer(),
              if (!s.noSleepDetected) ...[
                Text('${scored.score}',
                    style: TextStyle(color: color, fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('/100', style: TextStyle(color: Colors.white38,
                    fontSize: 11)),
              ],
            ]),
          );
        }),
      ],
    );
  }
}
```

---

## PART 5 FILE INVENTORY

```
NEW FILES:
  lib/core/services/motion_analyzer.dart          ← Accelerometer engine
  lib/core/services/sleep_detection_service.dart  ← Sleep state machine
  lib/core/services/sleep_quality_scorer.dart     ← Score + phase estimation
  lib/core/services/thermal_monitor.dart          ← EC-2.2 temperature check
  lib/core/providers/sleep_detection_provider.dart← Riverpod providers
  lib/features/sleep/sleep_tracker_screen.dart    ← Sleep tab UI

UPDATED FILES:
  lib/core/models/sleep_session.dart   (add HiveField 17–24)
  lib/core/constants/app_constants.dart (sleep thresholds)
  android/.../RiseAlarmPlugin.kt        (add getThermalStatus case)
  ios/Runner/AppDelegate.swift          (add getThermalStatus case)
```

---

## WIRING: Connect SleepDetectionService to AlarmService (Part 3)

In `alarm_service.dart`, add these calls at the appropriate points:

```dart
// 1. In AlarmService.initialize() — start sleep detection:
final _sleep = SleepDetectionService();
await _sleep.initialize();

// 2. When alarm fires (in _fireAlarm()):
final hadSleep  = _sleep.sleepWasDetected;
final volBoost  = _sleep.volumeBoostPercent;
// Pass volBoost to AudioRouteManager to raise max volume ceiling

// 3. After alarm is dismissed (in dismissAlarm()):
final session = await _sleep.endSleepSession(
  alarmId:          alarm.id,
  dismissMethod:    method,
  avgHrAtWake:      ppgReading?.heartRateBpm,
  identityVerified: verificationResult?.passed ?? false,
);

// Score the session immediately
if (session != null) {
  final scored = SleepQualityScorer().score(session);
  session.qualityLabel            = scored.qualityLabel;
  session.estimatedRemMinutes     = scored.estimatedRemMinutes;
  session.estimatedDeepMinutes    = scored.estimatedDeepMinutes;
  session.estimatedLightMinutes   = scored.estimatedLightMinutes;
  session.awakeMinutes            = scored.awakeMinutes;
  await session.save();
}

// 4. Screen state — in the platform channel message handler (MainActivity.kt):
// When Android fires ACTION_SCREEN_ON / ACTION_SCREEN_OFF broadcast:
// → call Flutter method channel → AlarmService routes to SleepDetectionService
```

---

## WIRING: Screen State Broadcasts (Android)

Add a screen state receiver to `AndroidManifest.xml` and `MainActivity.kt`:

```kotlin
// In MainActivity.kt — register a BroadcastReceiver for screen events:

private val screenReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val isOn = intent?.action == Intent.ACTION_SCREEN_ON
        flutterEngine?.dartExecutor?.let { executor ->
            MethodChannel(executor.binaryMessenger,
                "com.rise.alarmclock/capabilities")
                .invokeMethod(if (isOn) "screenOn" else "screenOff", null)
        }
    }
}

override fun onResume() {
    super.onResume()
    val filter = IntentFilter().apply {
        addAction(Intent.ACTION_SCREEN_ON)
        addAction(Intent.ACTION_SCREEN_OFF)
    }
    registerReceiver(screenReceiver, filter)
}

override fun onPause() {
    super.onPause()
    try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
}
```

Then in `SleepDetectionService`, handle these method calls:
```dart
// In the method channel handler (add to existing capabilities channel):
case 'screenOn':  SleepDetectionService().onScreenOn();  break;
case 'screenOff': SleepDetectionService().onScreenOff(); break;
```

---

## EDGE CASE COVERAGE CHECKLIST

```
EC-4.1  (vehicle motion)    ✓ vehicleWindowCount ≥20 → travelMode
                              screen-off = sleep proxy in travel mode
                              banner shown to user, NOT logged as awake

EC-4.2  (baby/partner)      ✓ motion < 15s → MICRO_WAKING, not AWAKE
                              only sustained screen use > 5 min ends session

EC-4.3  (washing machine)   ✓ isAmbientMotion flag filters appliance
                              vibration >5Hz, consistent amplitude

EC-4.4  (bathroom trip)     ✓ screenOn → microWakingWindow (5 min grace)
                              screen goes dark → resumes SLEEPING
                              nightWakingCount++ (sleep quality metric)

EC-4.5  (all-nighter)       ✓ _ctx == null at alarm fire → noSleepDetected
                              no biometric check, no guilt message
                              score card hidden in UI for this session

EC-4.6  (shift worker)      ✓ no time-of-day logic anywhere
                              purely screen-off + stillness + alarm exists

EC-4.7  (nap mode)          ✓ isNap flag from AlarmModel propagated
                              simplified _napScore() (duration only)
                              separate score scale (15-30 min = optimal)

EC-4.10 (insomnia honesty)  ✓ "estimated" on every metric label in UI
                              disclaimer at top of SleepTrackerScreen
                              "For accuracy, connect a wearable"

EC-2.2  (phone under pillow)✓ ThermalMonitor at alarm fire
                              bedtime pillow advisory shown ONCE
                              SharedPrefs guards against repeat

EC-2.3  (fall off nightstand)✓ spike >15 m/s² + orientation change
                               maxVolumeBoost = 15% passed to AlarmService
                               session.fallDetected flag → UI notice
```

---

## AFTER CREATING ALL FILES — RUN:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

The `build_runner` step is needed because SleepSession gained new HiveFields.
Expected: 0 errors, 0 warnings.

---

## WHAT PART 6 WILL COVER:
The complete Wake Games system — 5 distinct games (math challenge,
word unscramble, memory grid, barcode scan, trace pattern), difficulty
scaling by snooze count, accessibility variants (EC-3.8 tremors,
EC-3.9 deaf, EC-3.10 epilepsy, EC-3.11 cognitive), anti-circumvention
logic (EC-2.6 pets, random tap filtering), and the game engine that
selects and grades each session.

---
## END OF PART 5 BLUEPRINT
## 6 new files | 4 file updates
## Motion analyzer:      COMPLETE ✓ (vehicle, appliance, fall detection)
## Sleep state machine:  COMPLETE ✓ (awake→preSleep→sleeping→microWaking)
## Quality scorer:       COMPLETE ✓ (0–100, phase breakdown, all-nighter)
## Thermal monitor:      COMPLETE ✓ (EC-2.2 pillow overheating)
## Providers:            COMPLETE ✓ (state, sessions, trend, average)
## Sleep tracker UI:     COMPLETE ✓ (EC-4.10 honesty labels, advisories)
## AlarmService wiring:  COMPLETE ✓ (sleep data flows into alarm fire)
## Screen state wiring:  COMPLETE ✓ (Android broadcast → Flutter channel)
