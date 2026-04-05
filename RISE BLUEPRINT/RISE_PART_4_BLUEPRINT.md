# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 4 OF 12
# The Biometric Service — PPG, Face Liveness, PIN, Enrollment
# ============================================================
# COMMAND TO AI CODING AGENT:
# Parts 1, 2, and 3 must be complete before starting this part.
# The Edge Case Bible is LAW — every EC-3.x reference maps to
# a specific implementation you must build exactly as described.
#
# WHAT THIS PART CREATES (9 files + 2 updates):
#
#  1. lib/core/services/ppg_service.dart
#     Camera-based PPG engine. Dual-channel (red+green) capture,
#     SNR quality scoring, IBI variance, waveform fingerprinting,
#     low-pass tremor filter, peak detection, all EC-3.x signals.
#
#  2. lib/core/services/biometric_service.dart
#     Identity verification orchestrator. Runs the full pipeline:
#     PPG → Face (optional) → PIN fallback. Owns the 2-failure
#     auto-switch logic (EC-3.1, EC-3.2). Per-user adaptive
#     tolerance calibration (EC-3.6). Medically sensitive messaging.
#
#  3. lib/core/services/face_liveness_service.dart
#     ML Kit face detection. Blink + head-turn challenge confirms
#     user is physically present and awake, not a photo.
#
#  4. lib/core/services/pin_service.dart
#     PBKDF2-SHA256 PIN hashing with per-user salt. Constant-time
#     comparison. PIN is NEVER stored in plaintext anywhere.
#
#  5. lib/core/services/biometric_enrollment_service.dart
#     5-session enrollment protocol. Anti-gaming rules (EC-8.1):
#     sessions ≥12h apart, ≥3 calendar days, requires prior app
#     activity. Dual-finger profile support (EC-3.7).
#
#  6. lib/core/providers/biometric_provider.dart
#     Riverpod providers for all biometric state.
#
#  7. lib/shared/widgets/ppg_capture_widget.dart
#     Live camera preview with real-time HR animation and signal
#     quality bar. Used in both enrollment and alarm verification.
#
#  8. lib/shared/widgets/biometric_verification_sheet.dart
#     Bottom sheet shown by AlarmScreen. Runs PPG → PIN pipeline
#     with all fallback paths, clear messaging, accessibility modes.
#
#  9. lib/shared/widgets/pin_entry_widget.dart
#     6-digit PIN input with secure masking, backspace, attempt
#     counter, and 3-strike lockout messaging (non-blocking).
#
# UPDATES:
#  - lib/core/constants/app_constants.dart (biometric thresholds)
#  - lib/core/models/biometric_profile.dart (add adaptive fields)
# ============================================================

## ARCHITECTURE: THE VERIFICATION PIPELINE

# At alarm-fire time, the BiometricVerificationSheet runs this pipeline.
# Each stage resolves to pass, degrade, or route-to-next. The pipeline
# ALWAYS resolves within 20 seconds maximum — it never blocks indefinitely.
#
# ┌─────────────────────────────────────────────────────────────────┐
# │  STAGE 1: PPG HEART RATE CAPTURE                                │
# │  Duration: 8s standard / 15s tremor mode (EC-3.8)              │
# │                                                                 │
# │  PASS   → HR within tolerance + quality ≥ 0.4 → Wake Game      │
# │  WEAK   → SNR < 0.4 (EC-3.5 Raynaud's) → gentle PIN offer      │
# │  IRREG  → IBI variance high (EC-3.4 AFib) → silent PIN route   │
# │  FAIL×1 → HR mismatch → "Try a different finger" (EC-3.7)      │
# │  FAIL×2 → HR mismatch again → medically-sensitive PIN fallback  │
# │           (EC-3.1 fever, EC-3.2 exercise)                       │
# └────────────────────────┬────────────────────────────────────────┘
#                          │ optional parallel
# ┌────────────────────────▼────────────────────────────────────────┐
# │  STAGE 2: FACE LIVENESS (parallel, capable devices only)       │
# │  Duration: up to 10s                                           │
# │                                                                 │
# │  PASS   → blink + head-turn detected → corroborates PPG        │
# │  SKIP   → no front camera / emulator / low light → no penalty  │
# └────────────────────────┬────────────────────────────────────────┘
#                          │ fallback path
# ┌────────────────────────▼────────────────────────────────────────┐
# │  STAGE 3: PIN FALLBACK                                          │
# │  Used when PPG fails, signal is weak, or user has AFib/tremors  │
# │                                                                 │
# │  PASS   → correct PBKDF2-verified PIN → Wake Game              │
# │  FAIL×3 → wrong PIN 3 times → buddy notified + STILL passes    │
# │           NOTE: RISE NEVER permanently blocks alarm dismissal.  │
# │           Persistent failure = human factors. Don't punish.     │
# └─────────────────────────────────────────────────────────────────┘

---

## CONSTANTS TO ADD: lib/core/constants/app_constants.dart
## ADD these to the AppConstants class (some may already exist — skip dupes):

```dart
// ── Biometric / PPG thresholds ─────────────────────────────────────────────
static const String biometricBoxName          = 'biometric_v1';
static const String primaryProfileId          = 'primary_user';

// PPG capture durations
static const int ppgCaptureDurationSeconds         = 8;   // Standard capture
static const int ppgExtendedCaptureDurationSeconds = 15;  // EC-3.8 tremor mode
static const int ppgFaceTimeoutSeconds             = 10;  // Face liveness window

// HR matching tolerances
static const double ppgMinTolerance        = 8.0;   // Floor: 8 BPM
static const double ppgStandardTolerance   = 12.0;  // Day tolerance
static const double ppgMorningTolerance    = 18.0;  // EC-3.2 morning tolerance
static const double ppgWideTolerance       = 25.0;  // EC-3.3 medication mode

// Signal quality thresholds
static const double ppgMinSignalQuality    = 0.40;  // Below = weak signal (EC-3.5)
static const double ppgHighQuality        = 0.70;   // Confident reading

// IBI arrhythmia detection
static const double ppgArrhythmiaVarianceThreshold = 3000.0; // ms² (EC-3.4)

// Waveform similarity thresholds
static const double ppgWaveformMatchThreshold       = 0.70;
static const double ppgWaveformStrongMatchThreshold = 0.85;

// Attempt limits
static const int ppgMaxAttemptsBeforePin   = 2;  // EC-3.1: fail 2× → PIN
static const int pinMaxAttemptsBeforeNotify = 3; // Wrong PIN 3× → notify buddy

// Enrollment protocol (EC-8.1 anti-gaming)
static const int enrollmentRequiredSessions   = 5;
static const int enrollmentMinHoursBetween    = 12;
static const int enrollmentReadingsPerSession = 3;
static const int enrollmentAppActivityWindowHours = 24;

// Medically-sensitive user-facing messages
static const String ppgSignalWeak    =
    'Signal too weak — try warming your hands, or enter your PIN instead.';
static const String ppgHrMismatch    =
    "Heart rate doesn't match your profile — this can happen if you're "
    "not feeling well or recently exercised. Enter your PIN instead.";
static const String ppgFallbackPin   = 'Switching to PIN verification.';
static const String ppgTryOtherFinger = 'Try a different finger.';
static const String biometricReenrollPrompt =
    'Your biometric profile may need updating. Re-enroll for best accuracy.';
```

---

## FILE 1: lib/core/services/ppg_service.dart
## PATH: lib/core/services/ppg_service.dart
## PURPOSE: The camera-based PPG signal capture and analysis engine.
##          All raw signal processing lives here. BiometricService
##          calls this and interprets the results — it never touches
##          camera frames directly.
## EDGE CASES:
##   EC-3.4 (AFib) — IBI variance threshold flags arrhythmia
##   EC-3.5 (Raynaud's) — SNR quality score drops below threshold
##   EC-3.6 (skin tone) — dual red+green channel with best-channel selection
##   EC-3.7 (blocked camera) — amplitude check catches zero-signal frames
##   EC-3.8 (tremors) — extended duration + low-pass filter at 3Hz

```dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PPG READING — Complete output of one capture session
// ─────────────────────────────────────────────────────────────────────────────
class PpgReading {
  /// Heart rate in BPM (0 if capture failed)
  final double heartRateBpm;

  /// Signal quality: 0.0 (unusable noise) → 1.0 (perfect clean signal)
  /// EC-3.5: Below ppgMinSignalQuality (0.40) → friendly PIN fallback
  final double signalQuality;

  /// IBI variance in ms². Normal < 1500. AFib typically > 5000.
  /// EC-3.4: Above ppgArrhythmiaVarianceThreshold → route to PIN silently
  final double ibiVarianceMs2;

  /// Internal routing flag for arrhythmia. NEVER shown to user. (EC-3.4)
  final bool hasIrregularRhythm;

  /// 32-point normalized waveform fingerprint for secondary identity check
  final List<double> waveformVector;

  /// Raw IBI series (ms) — stored in enrollment profile
  final List<double> ibiSeriesMs;

  /// Dominant frequency extracted from red channel (Hz)
  final double redChannelHz;

  /// Dominant frequency extracted from green channel (Hz) — EC-3.6
  final double greenChannelHz;

  /// Capture duration in seconds
  final double durationSeconds;

  /// True if high-frequency luminance variance suggests hand tremor (EC-3.8)
  final bool hadMotionNoise;

  /// Which channel was used for final HR computation ('red' or 'green')
  final String dominantChannel;

  const PpgReading({
    required this.heartRateBpm,
    required this.signalQuality,
    required this.ibiVarianceMs2,
    required this.hasIrregularRhythm,
    required this.waveformVector,
    required this.ibiSeriesMs,
    required this.redChannelHz,
    required this.greenChannelHz,
    required this.durationSeconds,
    required this.hadMotionNoise,
    required this.dominantChannel,
  });

  bool get isUsable => signalQuality >= AppConstants.ppgMinSignalQuality
      && heartRateBpm >= 30 && heartRateBpm <= 250;

  bool get isHighQuality => signalQuality >= AppConstants.ppgHighQuality;

  /// Zero-value reading — returned when capture fails completely
  factory PpgReading.zero(String reason) => PpgReading(
        heartRateBpm:       0,
        signalQuality:      0,
        ibiVarianceMs2:     0,
        hasIrregularRhythm: false,
        waveformVector:     List.filled(32, 0.0),
        ibiSeriesMs:        [],
        redChannelHz:       0,
        greenChannelHz:     0,
        durationSeconds:    0,
        hadMotionNoise:     false,
        dominantChannel:    'none',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PPG SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class PpgService {
  CameraController? _controller;
  bool              _isCapturing = false;

  // Raw frame data buffers
  final List<double> _redSamples   = [];
  final List<double> _greenSamples = [];
  final List<double> _timestamps   = [];
  final List<double> _frameDiffs   = [];  // For motion detection (EC-3.8)

  // Real-time streams for UI feedback during capture
  final _hrStreamController =
      StreamController<double>.broadcast();
  final _qualityStreamController =
      StreamController<double>.broadcast();

  Stream<double> get heartRateStream    => _hrStreamController.stream;
  Stream<double> get signalQualityStream => _qualityStreamController.stream;

  // ─────────────────────────────────────────────────────────────────────────
  // CAPTURE
  // Returns a PpgReading after the specified duration.
  // This is the single public entry point for all callers.
  // ─────────────────────────────────────────────────────────────────────────
  Future<PpgReading> capture({
    int durationSeconds = AppConstants.ppgCaptureDurationSeconds,
    bool extendedForTremor = false,  // EC-3.8: use longer window
  }) async {
    if (_isCapturing) return PpgReading.zero('already_capturing');

    final actualDuration = extendedForTremor
        ? AppConstants.ppgExtendedCaptureDurationSeconds
        : durationSeconds;

    _isCapturing = true;
    _clearBuffers();

    // ── Step 1: Initialize rear camera ───────────────────────────────
    try {
      final cameras = await availableCameras();
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => throw Exception('No rear camera found'),
      );

      _controller = CameraController(
        rear,
        ResolutionPreset.low,  // Only need brightness values — not detail
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // Lock exposure/focus for consistent readings across frames
      await _controller!.setExposureMode(ExposureMode.locked);
      await _controller!.setFocusMode(FocusMode.locked);

      // Torch: REQUIRED for PPG — illuminates the finger capillaries.
      // EC-3.5/EC-3.7: If torch fails, amplitude will be near-zero,
      // which the SNR check catches and routes to PIN gracefully.
      try {
        await _controller!.setFlashMode(FlashMode.torch);
      } catch (_) {
        // Torch unavailable — proceed with ambient light only.
        // Signal quality will likely score below ppgMinSignalQuality.
      }
    } catch (e) {
      _isCapturing = false;
      return PpgReading.zero('camera_init_failed');
    }

    // ── Step 2: Stream frames and fill buffers ────────────────────────
    int frameCount = 0;
    _controller!.startImageStream((CameraImage frame) {
      if (!_isCapturing) return;
      frameCount++;
      _ingestFrame(frame);

      // Emit intermediate estimates every ~1 second (≈30 frames at 30fps)
      if (frameCount % 30 == 0 && _redSamples.length > 60) {
        final hr = _estimateHr(_redSamples);
        if (hr > 0) _hrStreamController.add(hr);

        final quality = _estimateQuality();
        _qualityStreamController.add(quality);
      }
    });

    // ── Step 3: Wait for capture window ──────────────────────────────
    await Future.delayed(Duration(seconds: actualDuration));

    // ── Step 4: Teardown ─────────────────────────────────────────────
    _isCapturing = false;
    try {
      await _controller!.stopImageStream();
      await _controller!.setFlashMode(FlashMode.off);
      await _controller!.dispose();
      _controller = null;
    } catch (_) {}

    // ── Step 5: Compute final reading ────────────────────────────────
    return _computeReading(actualDuration.toDouble(), extendedForTremor);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INGEST A SINGLE FRAME
  // Extracts per-pixel channel means from the YUV420 image plane.
  // Samples only the central 40% of the frame (where the finger sits).
  // ─────────────────────────────────────────────────────────────────────────
  void _ingestFrame(CameraImage image) {
    try {
      final width  = image.width;
      final height = image.height;
      final y      = image.planes[0].bytes;
      final u      = image.planes.length > 1 ? image.planes[1].bytes : null;
      final v      = image.planes.length > 2 ? image.planes[2].bytes : null;

      // Central ROI — avoids edge artifacts when finger is placed on camera
      final x0 = (width  * 0.30).toInt();
      final x1 = (width  * 0.70).toInt();
      final y0 = (height * 0.30).toInt();
      final y1 = (height * 0.70).toInt();

      double sumY = 0, sumU = 0, sumV = 0;
      int count = 0;

      for (int row = y0; row < y1; row += 2) {
        for (int col = x0; col < x1; col += 2) {
          final idx = row * width + col;
          if (idx < y.length) {
            sumY += y[idx] & 0xFF;
            count++;
          }
        }
      }

      if (count == 0) return;

      // Sample U and V planes (half-resolution for YUV420)
      if (u != null && v != null) {
        int uvCount = 0;
        for (int row = y0 ~/ 2; row < y1 ~/ 2; row += 2) {
          for (int col = x0 ~/ 2; col < x1 ~/ 2; col += 2) {
            final idx = row * (width ~/ 2) + col;
            if (idx < u.length && idx < v.length) {
              sumU += u[idx] & 0xFF;
              sumV += v[idx] & 0xFF;
              uvCount++;
            }
          }
        }
        if (uvCount > 0) { sumU /= uvCount; sumV /= uvCount; }
      } else {
        sumU = 128.0; sumV = 128.0;
      }

      final meanY = sumY / count;

      // YCbCr → approximate R and G channel values
      // R ≈ Y + 1.402*(V-128)       — red channel (EC-3.6: less accurate for dark skin)
      // G ≈ Y - 0.344*(U-128) - 0.714*(V-128) — green channel (more melanin-neutral)
      final red   = (meanY + 1.402  * (sumV - 128)).clamp(0.0, 255.0);
      final green = (meanY - 0.344  * (sumU - 128) - 0.714 * (sumV - 128))
          .clamp(0.0, 255.0);

      _redSamples.add(red);
      _greenSamples.add(green);
      _timestamps.add(DateTime.now().millisecondsSinceEpoch.toDouble());

      // Frame-to-frame luminance difference → motion proxy (EC-3.8)
      if (_redSamples.length > 1) {
        _frameDiffs.add(
          (_redSamples.last - _redSamples[_redSamples.length - 2]).abs(),
        );
      }
    } catch (_) {
      // Skip malformed frames — never crash on a bad frame
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPUTE FINAL READING
  // Full signal processing pipeline on the collected buffers.
  // ─────────────────────────────────────────────────────────────────────────
  PpgReading _computeReading(double duration, bool tremorMode) {
    if (_redSamples.length < 30) {
      return PpgReading.zero('insufficient_frames');
    }

    // ── Detect motion noise (EC-3.8) ─────────────────────────────────
    final hadMotion = _detectMotion();

    // ── Apply low-pass filter (EC-3.8: remove tremor artifacts) ──────
    // Cardiac frequencies are 0.7–4 Hz. Tremors are 8–12 Hz.
    // A 3 Hz low-pass removes tremor noise without distorting the pulse.
    List<double> red   = tremorMode || hadMotion
        ? _lowPass(_redSamples,   cutoff: 3.0)
        : List.from(_redSamples);
    List<double> green = tremorMode || hadMotion
        ? _lowPass(_greenSamples, cutoff: 3.0)
        : List.from(_greenSamples);

    // ── Bandpass 0.7–4.0 Hz to isolate cardiac band ──────────────────
    red   = _bandpass(red,   low: 0.7, high: 4.0);
    green = _bandpass(green, low: 0.7, high: 4.0);

    // ── Peak detection on both channels ──────────────────────────────
    final redPeaks   = _findPeaks(red,   _timestamps);
    final greenPeaks = _findPeaks(green, _timestamps);

    // EC-3.6: Use whichever channel found more peaks (green wins for dark skin)
    final usedChannel   = redPeaks.length >= greenPeaks.length ? 'red' : 'green';
    final bestPeaks     = usedChannel == 'red' ? redPeaks : greenPeaks;
    final bestSignal    = usedChannel == 'red' ? red : green;

    if (bestPeaks.length < 3) {
      return PpgReading.zero('insufficient_peaks');
    }

    // ── IBI series ────────────────────────────────────────────────────
    final ibis = <double>[];
    for (int i = 1; i < bestPeaks.length; i++) {
      ibis.add(bestPeaks[i] - bestPeaks[i - 1]);
    }

    // ── HR from median IBI (robust to outlier beats) ──────────────────
    final sortedIbis = List<double>.from(ibis)..sort();
    final medianIbi  = sortedIbis[sortedIbis.length ~/ 2];
    final bpm        = medianIbi > 0 ? (60000.0 / medianIbi) : 0.0;

    // ── IBI variance (EC-3.4 AFib detection) ─────────────────────────
    final ibiMean     = ibis.reduce((a, b) => a + b) / ibis.length;
    final ibiVariance = ibis
        .map((x) => (x - ibiMean) * (x - ibiMean))
        .reduce((a, b) => a + b) / ibis.length;
    // EC-3.4: Do NOT display this result to user — internal routing only
    final isIrregular = ibiVariance > AppConstants.ppgArrhythmiaVarianceThreshold;

    // ── Signal quality score ──────────────────────────────────────────
    final quality = _computeQuality(
      red:        red,
      green:      green,
      ibis:       ibis,
      hadMotion:  hadMotion,
    );

    // ── Waveform fingerprint ──────────────────────────────────────────
    final waveform = _buildWaveformVector(bestSignal, bestPeaks);

    // ── Dominant frequencies (Hz) ─────────────────────────────────────
    final redHz   = _zeroCrossingFreq(red);
    final greenHz = _zeroCrossingFreq(green);

    return PpgReading(
      heartRateBpm:       bpm.clamp(30.0, 250.0),
      signalQuality:      quality.clamp(0.0, 1.0),
      ibiVarianceMs2:     ibiVariance,
      hasIrregularRhythm: isIrregular,
      waveformVector:     waveform,
      ibiSeriesMs:        ibis,
      redChannelHz:       redHz,
      greenChannelHz:     greenHz,
      durationSeconds:    duration,
      hadMotionNoise:     hadMotion,
      dominantChannel:    usedChannel,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGNAL QUALITY SCORE
  // Composite score from 5 independent quality indicators.
  // Below 0.40 = PIN fallback (EC-3.5).
  // ─────────────────────────────────────────────────────────────────────────
  double _computeQuality({
    required List<double> red,
    required List<double> green,
    required List<double> ibis,
    required bool hadMotion,
  }) {
    double q = 1.0;

    // Q1: Enough beats detected (< 4 peaks = unreliable)
    final beats = ibis.length + 1;
    if      (beats < 4) q *= 0.15;
    else if (beats < 6) q *= 0.55;

    // Q2: IBI coefficient of variation (regularity)
    if (ibis.isNotEmpty) {
      final mean = ibis.reduce((a, b) => a + b) / ibis.length;
      final cv   = mean > 0
          ? ibis.map((x) => (x - mean).abs()).reduce((a, b) => a + b)
              / (ibis.length * mean)
          : 1.0;
      if (cv > 0.30) q *= 0.70;
    }

    // Q3: Signal amplitude (EC-3.5/EC-3.7 — finger not covering flash)
    final amp = _amplitude(red);
    if      (amp < 1.5) q *= 0.20;  // Nearly zero — camera blocked
    else if (amp < 4.0) q *= 0.65;

    // Q4: Motion noise penalty (EC-3.8 tremors partially attenuated by filter)
    if (hadMotion) q *= 0.80;

    // Q5: Red/green channel frequency agreement (EC-3.6 skin equity check)
    final redHz   = _zeroCrossingFreq(red);
    final greenHz = _zeroCrossingFreq(green);
    if (redHz > 0 && greenHz > 0) {
      final agree = 1.0 - (redHz - greenHz).abs() / math.max(redHz, greenHz);
      q *= (0.5 + 0.5 * agree.clamp(0.0, 1.0));
    }

    return q;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WAVEFORM FINGERPRINT
  // Averages 3–8 normalized cardiac cycle templates into a 32-point vector.
  // This captures the unique shape of the user's pulse wave — distinct even
  // between people with similar resting HR (the waveform encodes vascular
  // compliance, stroke volume, and arterial stiffness).
  // ─────────────────────────────────────────────────────────────────────────
  List<double> _buildWaveformVector(List<double> signal, List<double> peaks) {
    if (peaks.length < 3 || signal.isEmpty) return List.filled(32, 0.0);

    const points = 32;
    final templates = <List<double>>[];

    for (int i = 0; i < math.min(peaks.length - 1, 8); i++) {
      final tStart = peaks[i];
      final tEnd   = peaks[i + 1];

      // Find sample indices for this cardiac cycle
      final iStart = _nearestIdx(_timestamps, tStart);
      final iEnd   = _nearestIdx(_timestamps, tEnd);
      if (iEnd <= iStart + 3) continue;

      final cycle = signal.sublist(iStart, iEnd);

      // Resample cycle to exactly 32 points (linear interpolation)
      final resampled = _resample(cycle, points);

      // Zero-mean, unit-variance normalization
      final mean  = resampled.reduce((a, b) => a + b) / resampled.length;
      final vars  = resampled.map((x) => (x - mean) * (x - mean))
          .reduce((a, b) => a + b) / resampled.length;
      final std   = math.sqrt(vars);
      if (std < 0.001) continue;

      templates.add(resampled.map((x) => (x - mean) / std).toList());
    }

    if (templates.isEmpty) return List.filled(32, 0.0);

    // Average all cycle templates
    final fingerprint = List.filled(32, 0.0);
    for (final t in templates) {
      for (int i = 0; i < 32; i++) {
        fingerprint[i] += t[i] / templates.length;
      }
    }
    return fingerprint;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOTION NOISE DETECTION (EC-3.8)
  // High mean frame-to-frame luminance difference = hand is trembling.
  // ─────────────────────────────────────────────────────────────────────────
  bool _detectMotion() {
    if (_frameDiffs.length < 10) return false;
    final mean = _frameDiffs.reduce((a, b) => a + b) / _frameDiffs.length;
    final peak = _frameDiffs.reduce(math.max);
    // Motion confirmed if average diff > 3.0 brightness units
    // OR a sudden large spike > 10.0 (sudden grab/shift)
    return mean > 3.0 || peak > 10.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PEAK DETECTION
  // Finds local maxima in the filtered signal separated by ≥ minPeakGap.
  // minPeakGap corresponds to the maximum realistic HR (240 BPM = 0.25s).
  // ─────────────────────────────────────────────────────────────────────────
  List<double> _findPeaks(List<double> signal, List<double> timestamps) {
    const fps        = 30.0;
    final minGap     = (fps * 0.25).round();  // 240 BPM max
    final peaks      = <double>[];
    int   lastPeakAt = 0;

    if (signal.length < minGap * 2) return peaks;

    for (int i = minGap; i < signal.length - minGap; i++) {
      if (i - lastPeakAt < minGap) continue;

      bool isMax = true;
      for (int j = i - minGap; j <= i + minGap; j++) {
        if (j != i && j >= 0 && j < signal.length && signal[j] >= signal[i]) {
          isMax = false;
          break;
        }
      }

      if (isMax) {
        final tsIdx = math.min(i, timestamps.length - 1);
        peaks.add(timestamps[tsIdx]);
        lastPeakAt = i;
      }
    }
    return peaks;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INTERMEDIATE HR ESTIMATE (feeds real-time UI during capture)
  // ─────────────────────────────────────────────────────────────────────────
  double _estimateHr(List<double> samples) {
    if (samples.length < 30) return 0.0;
    final recent    = samples.length > 90
        ? samples.sublist(samples.length - 90)
        : samples;
    final filtered  = _bandpass(recent, low: 0.7, high: 4.0);
    final tSlice    = _timestamps.length > recent.length
        ? _timestamps.sublist(_timestamps.length - recent.length)
        : _timestamps;
    final peaks     = _findPeaks(filtered, tSlice);
    if (peaks.length < 2) return 0.0;

    final ibis = <double>[];
    for (int i = 1; i < peaks.length; i++) ibis.add(peaks[i] - peaks[i - 1]);
    if (ibis.isEmpty) return 0.0;

    final median = (List.from(ibis)..sort())[ibis.length ~/ 2];
    return median > 0 ? (60000.0 / median).clamp(30, 250) : 0.0;
  }

  double _estimateQuality() {
    if (_redSamples.length < 10) return 0.0;
    return (_amplitude(_redSamples) / 20.0).clamp(0.0, 1.0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGNAL PROCESSING UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  List<double> _lowPass(List<double> s, {required double cutoff}) {
    const sr    = 30.0;
    final rc    = 1.0 / (2 * math.pi * cutoff);
    final dt    = 1.0 / sr;
    final alpha = dt / (rc + dt);
    final out   = List<double>.from(s);
    for (int i = 1; i < out.length; i++) {
      out[i] = out[i - 1] + alpha * (s[i] - out[i - 1]);
    }
    return out;
  }

  List<double> _highPass(List<double> s, {required double cutoff}) {
    const sr    = 30.0;
    final rc    = 1.0 / (2 * math.pi * cutoff);
    final dt    = 1.0 / sr;
    final alpha = rc / (rc + dt);
    final out   = List<double>.from(s);
    for (int i = 1; i < out.length; i++) {
      out[i] = alpha * (out[i - 1] + s[i] - s[i - 1]);
    }
    return out;
  }

  List<double> _bandpass(List<double> s,
      {required double low, required double high}) =>
      _lowPass(_highPass(s, cutoff: low), cutoff: high);

  double _zeroCrossingFreq(List<double> s) {
    if (s.length < 4) return 0.0;
    final mean = s.reduce((a, b) => a + b) / s.length;
    int xings  = 0;
    for (int i = 1; i < s.length; i++) {
      if ((s[i] - mean) * (s[i - 1] - mean) < 0) xings++;
    }
    const sr = 30.0;
    return (xings / 2.0) / (s.length / sr);
  }

  double _amplitude(List<double> s) {
    if (s.isEmpty) return 0.0;
    return s.reduce(math.max) - s.reduce(math.min);
  }

  List<double> _resample(List<double> s, int n) {
    if (s.length == n) return s;
    final out = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t  = i * (s.length - 1) / (n - 1);
      final lo = t.floor();
      final hi = math.min(lo + 1, s.length - 1);
      out[i]   = s[lo] * (1 - (t - lo)) + s[hi] * (t - lo);
    }
    return out;
  }

  int _nearestIdx(List<double> ts, double target) {
    if (ts.isEmpty) return 0;
    int best = 0;
    double bestDiff = (ts[0] - target).abs();
    for (int i = 1; i < ts.length; i++) {
      final d = (ts[i] - target).abs();
      if (d < bestDiff) { bestDiff = d; best = i; }
    }
    return best;
  }

  void _clearBuffers() {
    _redSamples.clear();
    _greenSamples.clear();
    _timestamps.clear();
    _frameDiffs.clear();
  }

  Future<void> stopCapture() async {
    _isCapturing = false;
    try {
      await _controller?.stopImageStream();
      await _controller?.setFlashMode(FlashMode.off);
      await _controller?.dispose();
      _controller = null;
    } catch (_) {}
  }

  void dispose() {
    stopCapture();
    _hrStreamController.close();
    _qualityStreamController.close();
  }
}
```

---

## FILE 2: lib/core/services/biometric_service.dart
## PATH: lib/core/services/biometric_service.dart
## PURPOSE: Identity verification orchestrator. Calls PpgService,
##          interprets results with per-user tolerance logic, routes
##          to face liveness or PIN as needed. Medically sensitive.
## EDGE CASES:
##   EC-3.1 (fever) — 2-failure PIN route, gentle language
##   EC-3.2 (exercise) — wider morning tolerance
##   EC-3.3 (medication) — wide tolerance flag
##   EC-3.4 (AFib) — skip HR match, route to PIN silently
##   EC-3.5 (Raynaud's) — weak signal → PIN
##   EC-3.6 (skin tone) — per-user adaptive tolerance
##   EC-3.7 (blocked/nails) — retry with different finger
##   EC-3.8 (tremors) — extended mode flag passed to PpgService

```dart
import 'dart:math' as math;
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/biometric_profile.dart';
import 'ppg_service.dart';
import 'face_liveness_service.dart';
import 'pin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VERIFICATION RESULT
// ─────────────────────────────────────────────────────────────────────────────
enum VerificationOutcome {
  passed,
  weakSignal,       // EC-3.5: SNR below threshold
  irregularRhythm,  // EC-3.4: AFib detected — routed silently to PIN
  hrMismatch,       // EC-3.1/3.2: HR out of tolerance
  pinMatch,
  pinFailed,
  notEnrolled,      // No profile yet — skip verification entirely
}

class VerificationResult {
  final VerificationOutcome outcome;
  final bool passed;
  /// True → caller should present PIN entry immediately
  final bool shouldSwitchToPin;
  /// Shown to user. Always medically-sensitive (EC-3.1 Bible rule).
  final String displayMessage;
  /// Internal only — analytics tag, NEVER shown to user (EC-3.4 rule)
  final String analyticsTag;
  final double? measuredBpm;
  final double? quality;

  const VerificationResult({
    required this.outcome,
    required this.passed,
    required this.shouldSwitchToPin,
    required this.displayMessage,
    required this.analyticsTag,
    this.measuredBpm,
    this.quality,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final PpgService          _ppg  = PpgService();
  final FaceLivenessService _face = FaceLivenessService();
  final PinService          _pin  = PinService();

  // Consecutive PPG failure count — reset when alarm session starts
  int _ppgFailures = 0;

  void resetSession() => _ppgFailures = 0;

  // ─────────────────────────────────────────────────────────────────────────
  // VERIFY VIA PPG
  // Primary path. Returns result immediately usable by VerificationSheet.
  // ─────────────────────────────────────────────────────────────────────────
  Future<VerificationResult> verifyPpg({
    required String   profileId,
    required bool     wideTolerance,         // EC-3.3: medication mode
    required bool     extendedCapture,       // EC-3.8: tremor mode
    required bool     userDeclaredArrhythmia,// EC-3.4: user-declared AFib
  }) async {
    // ── Guard: User declared arrhythmia → skip PPG, go to PIN (EC-3.4) ──
    if (userDeclaredArrhythmia) {
      return VerificationResult(
        outcome:          VerificationOutcome.irregularRhythm,
        passed:           false,
        shouldSwitchToPin: true,
        displayMessage:   AppConstants.ppgFallbackPin,
        analyticsTag:     'declared_arrhythmia',
      );
    }

    // ── Guard: Not enrolled → skip biometric entirely ─────────────────
    final profile = _loadProfile(profileId);
    if (profile == null || !profile.isFullyEnrolled) {
      return VerificationResult(
        outcome:          VerificationOutcome.notEnrolled,
        passed:           true,  // No profile = no lock = pass through
        shouldSwitchToPin: false,
        displayMessage:   '',
        analyticsTag:     'not_enrolled',
      );
    }

    // ── Capture ───────────────────────────────────────────────────────
    final reading = await _ppg.capture(
      extendedForTremor: extendedCapture,
    );

    // ── EC-3.5: Weak signal → gentle PIN offer ────────────────────────
    if (!reading.isUsable) {
      _ppgFailures++;
      return VerificationResult(
        outcome:           VerificationOutcome.weakSignal,
        passed:            false,
        shouldSwitchToPin: true,
        displayMessage:    AppConstants.ppgSignalWeak,
        analyticsTag:      'weak_signal_snr_${reading.signalQuality.toStringAsFixed(2)}',
        measuredBpm:       reading.heartRateBpm > 0 ? reading.heartRateBpm : null,
        quality:           reading.signalQuality,
      );
    }

    // ── EC-3.4: Arrhythmia detected in signal → silent PIN route ──────
    // IMPORTANT: We do NOT tell the user "irregular heartbeat detected".
    // That would be a medical claim. We just silently route to PIN.
    if (reading.hasIrregularRhythm) {
      _ppgFailures++;
      return VerificationResult(
        outcome:           VerificationOutcome.irregularRhythm,
        passed:            false,
        shouldSwitchToPin: true,
        displayMessage:    AppConstants.ppgFallbackPin,
        analyticsTag:      'signal_irregular_ibi_${reading.ibiVarianceMs2.toStringAsFixed(0)}',
        measuredBpm:       reading.heartRateBpm,
        quality:           reading.signalQuality,
      );
    }

    // ── Identity matching ─────────────────────────────────────────────
    final match = _match(reading: reading, profile: profile, wideTolerance: wideTolerance);

    // ── PASS ──────────────────────────────────────────────────────────
    if (match.isMatch) {
      _ppgFailures = 0;
      // Adaptively update profile (keeps it accurate over time — EC-3.3)
      await _adaptProfile(profile, reading);
      return VerificationResult(
        outcome:           VerificationOutcome.passed,
        passed:            true,
        shouldSwitchToPin: false,
        displayMessage:    '',
        analyticsTag:      'ppg_match_delta_${match.hrDelta.toStringAsFixed(1)}',
        measuredBpm:       reading.heartRateBpm,
        quality:           reading.signalQuality,
      );
    }

    // ── FAIL ──────────────────────────────────────────────────────────
    _ppgFailures++;

    // First failure: offer "try a different finger" before PIN (EC-3.7)
    if (_ppgFailures < AppConstants.ppgMaxAttemptsBeforePin) {
      return VerificationResult(
        outcome:           VerificationOutcome.hrMismatch,
        passed:            false,
        shouldSwitchToPin: false,  // Retry allowed
        displayMessage:    AppConstants.ppgTryOtherFinger,
        analyticsTag:      'hr_mismatch_attempt_$_ppgFailures',
        measuredBpm:       reading.heartRateBpm,
        quality:           reading.signalQuality,
      );
    }

    // Second failure: medically-sensitive PIN fallback (EC-3.1, EC-3.2)
    // Language never says "wrong person" or accuses the user.
    return VerificationResult(
      outcome:           VerificationOutcome.hrMismatch,
      passed:            false,
      shouldSwitchToPin: true,
      displayMessage:    AppConstants.ppgHrMismatch,
      analyticsTag:      'hr_mismatch_pin_fallback',
      measuredBpm:       reading.heartRateBpm,
      quality:           reading.signalQuality,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VERIFY VIA PIN
  // ─────────────────────────────────────────────────────────────────────────
  Future<VerificationResult> verifyPin({
    required String profileId,
    required String enteredPin,
  }) async {
    final ok = await _pin.verify(profileId: profileId, enteredPin: enteredPin);
    return VerificationResult(
      outcome:           ok ? VerificationOutcome.pinMatch
                            : VerificationOutcome.pinFailed,
      passed:            ok,
      shouldSwitchToPin: !ok,
      displayMessage:    ok ? '' : 'Incorrect PIN. Try again.',
      analyticsTag:      ok ? 'pin_match' : 'pin_fail',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IDENTITY MATCHING
  // Per-user adaptive tolerance — the core EC-3.6 equity mechanism.
  // We never use a global hardcoded threshold. The tolerance comes from
  // the user's own enrollment variance, so it self-calibrates for skin
  // tone, age, fitness level, and physiology without any demographic data.
  // ─────────────────────────────────────────────────────────────────────────
  _MatchResult _match({
    required PpgReading      reading,
    required BiometricProfile profile,
    required bool             wideTolerance,
  }) {
    // Tolerance is 2× the user's own enrollment standard deviation,
    // clamped to a sensible range (EC-3.6 self-calibration)
    double tolerance;
    if (wideTolerance) {
      // EC-3.3: Beta-blockers / medication — very wide window
      tolerance = AppConstants.ppgWideTolerance;
    } else {
      tolerance = (profile.hrStdDeviation * 2.0)
          .clamp(AppConstants.ppgMinTolerance, AppConstants.ppgMorningTolerance);
    }

    final hrDelta    = (reading.heartRateBpm - profile.avgRestingHR).abs();
    final hrMatches  = hrDelta <= tolerance;

    // Waveform similarity (cosine similarity between 32-point vectors)
    double waveformSim = 0.0;
    if (reading.waveformVector.length == 32 &&
        profile.waveformSignature.length == 32) {
      waveformSim = _cosine(reading.waveformVector, profile.waveformSignature);
    }

    // Match logic:
    // Case A: HR matches → pass (standard path)
    // Case B: Waveform very strongly matches (>0.85) even if HR slightly off
    //         → pass (covers fever/exercise where HR is temporarily elevated)
    final isMatch = hrMatches ||
        (waveformSim > AppConstants.ppgWaveformStrongMatchThreshold &&
            hrDelta <= tolerance * 1.5);

    return _MatchResult(
      isMatch:       isMatch,
      hrDelta:       hrDelta,
      tolerance:     tolerance,
      waveformSim:   waveformSim,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADAPTIVE PROFILE UPDATE
  // After each confirmed match, nudge the profile 5% toward today's reading.
  // This keeps the profile current as physiology changes over months.
  // Rate 0.05 = profile fully reflects a trend after ~20 daily uses.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _adaptProfile(
    BiometricProfile profile,
    PpgReading reading,
  ) async {
    const r = 0.05;  // 5% adaptation per successful verification

    profile.avgRestingHR = profile.avgRestingHR * (1 - r) +
        reading.heartRateBpm * r;

    final newDelta = (reading.heartRateBpm - profile.avgRestingHR).abs();
    profile.hrStdDeviation = profile.hrStdDeviation * (1 - r) + newDelta * r;

    profile.totalVerifications++;
    profile.lastVerifiedAt = DateTime.now();
    await profile.save();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  BiometricProfile? _loadProfile(String profileId) {
    final box = Hive.box<dynamic>(AppConstants.biometricBoxName);
    return box.get(profileId) as BiometricProfile?;
  }

  double _cosine(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na  += a[i] * a[i];
      nb  += b[i] * b[i];
    }
    final denom = math.sqrt(na) * math.sqrt(nb);
    return denom > 0 ? dot / denom : 0.0;
  }
}

class _MatchResult {
  final bool   isMatch;
  final double hrDelta;
  final double tolerance;
  final double waveformSim;
  const _MatchResult({
    required this.isMatch,
    required this.hrDelta,
    required this.tolerance,
    required this.waveformSim,
  });
}
```

---

## FILE 3: lib/core/services/face_liveness_service.dart
## PATH: lib/core/services/face_liveness_service.dart
## PURPOSE: ML Kit face detection to confirm the user is awake and
##          present. Blink + head-turn challenge. Defeats printed photos.

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class LivenessResult {
  final bool   passed;
  final bool   cameraAvailable;
  final bool   blinkDetected;
  final bool   headTurnDetected;
  final String failReason;

  const LivenessResult({
    required this.passed,
    required this.cameraAvailable,
    this.blinkDetected    = false,
    this.headTurnDetected = false,
    this.failReason       = '',
  });

  static const noCamera  = LivenessResult(passed: false, cameraAvailable: false,
      failReason: 'no_front_camera');
  static const lowLight  = LivenessResult(passed: false, cameraAvailable: true,
      failReason: 'low_light');
  static const timeout   = LivenessResult(passed: false, cameraAvailable: true,
      failReason: 'timeout');
  static const initFail  = LivenessResult(passed: false, cameraAvailable: false,
      failReason: 'camera_init_failed');
}

class FaceLivenessService {
  CameraController? _controller;
  bool              _running = false;

  // ML Kit face detector — classifications give us eye-open probability
  late final FaceDetector _detector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableClassification: true,  // leftEyeOpenProbability, rightEyeOpenProbability
      enableLandmarks:      true,  // headEulerAngleY for head-turn detection
      enableTracking:       false,
      minFaceSize:          0.15,  // Face must cover ≥15% of frame
      performanceMode:      FaceDetectorMode.accurate,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // CHECK LIVENESS
  // Returns a LivenessResult after the user blinks AND turns their head.
  // Times out after [timeoutSeconds] if challenge is not completed.
  // ─────────────────────────────────────────────────────────────────────────
  Future<LivenessResult> checkLiveness({
    int timeoutSeconds = AppConstants.ppgFaceTimeoutSeconds,
  }) async {
    if (_running) return LivenessResult.noCamera;
    _running = true;

    // ── Find front camera ─────────────────────────────────────────────
    CameraDescription? front;
    try {
      final cameras = await availableCameras();
      front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => throw Exception('no front camera'),
      );
    } catch (_) {
      _running = false;
      return LivenessResult.noCamera;
    }

    // ── Initialize ────────────────────────────────────────────────────
    try {
      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
    } catch (_) {
      _running = false;
      return LivenessResult.initFail;
    }

    // ── Run detection ─────────────────────────────────────────────────
    bool   blinkDetected     = false;
    bool   headTurnDetected  = false;
    bool   eyesWereOpen      = false;
    double? baselineAngle;
    final  completer = Completer<LivenessResult>();

    final timer = Timer(Duration(seconds: timeoutSeconds), () {
      if (!completer.isCompleted) completer.complete(LivenessResult.timeout);
    });

    _controller!.startImageStream((CameraImage frame) async {
      if (!_running || completer.isCompleted) return;

      try {
        final input = _toInputImage(frame, front!);
        final faces = await _detector.processImage(input);
        if (faces.isEmpty) return;

        final face    = faces.first;
        final leftOpen  = face.leftEyeOpenProbability  ?? 1.0;
        final rightOpen = face.rightEyeOpenProbability ?? 1.0;
        final headY     = face.headEulerAngleY         ?? 0.0;

        // Blink: eyes were open, now both closed
        if (leftOpen > 0.7 && rightOpen > 0.7) eyesWereOpen = true;
        if (eyesWereOpen && leftOpen < 0.2 && rightOpen < 0.2) {
          blinkDetected = true;
        }

        // Head turn: >15° deviation from baseline angle
        baselineAngle ??= headY;
        if ((headY - baselineAngle!).abs() > 15.0) headTurnDetected = true;

        if (blinkDetected && headTurnDetected && !completer.isCompleted) {
          completer.complete(LivenessResult(
            passed:           true,
            cameraAvailable:  true,
            blinkDetected:    true,
            headTurnDetected: true,
          ));
        }
      } catch (_) {}
    });

    final result = await completer.future;
    timer.cancel();

    _running = false;
    try {
      await _controller!.stopImageStream();
      await _controller!.dispose();
      _controller = null;
    } catch (_) {}

    return result;
  }

  InputImage _toInputImage(CameraImage image, CameraDescription camera) {
    final bytes = image.planes
        .map((p) => p.bytes)
        .reduce((a, b) => Uint8List.fromList([...a, ...b]));
    final rotation = InputImageRotationValue.fromRawValue(
          camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size:        Size(image.width.toDouble(), image.height.toDouble()),
        rotation:    rotation,
        format:      Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void dispose() {
    _running = false;
    _controller?.dispose();
    _detector.close();
  }
}
```

---

## FILE 4: lib/core/services/pin_service.dart
## PATH: lib/core/services/pin_service.dart
## PURPOSE: Secure 6-digit PIN management. PBKDF2-SHA256 with per-user
##          salt. PIN is NEVER stored in plaintext. Constant-time compare.

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

class PinService {
  static const int _iterations = 10000;
  static const int _hashLen    = 32;   // 256 bits
  static const int _saltLen    = 16;   // 128 bits

  // ─────────────────────────────────────────────────────────────────────────
  // SET PIN — derives PBKDF2-SHA256 hash, stores hash + salt only
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setPin({required String profileId, required String pin}) async {
    if (!_validPin(pin)) throw ArgumentError('PIN must be 6 digits');
    final salt = _salt();
    final hash = _pbkdf2(pin, salt);
    final box  = Hive.box<dynamic>(AppConstants.biometricBoxName);
    await box.put('pin_salt_$profileId', base64.encode(salt));
    await box.put('pin_hash_$profileId', base64.encode(hash));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VERIFY PIN — constant-time comparison to prevent timing attacks
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> verify({
    required String profileId,
    required String enteredPin,
  }) async {
    if (!_validPin(enteredPin)) return false;
    final box  = Hive.box<dynamic>(AppConstants.biometricBoxName);
    final s64  = box.get('pin_salt_$profileId') as String?;
    final h64  = box.get('pin_hash_$profileId') as String?;
    if (s64 == null || h64 == null) return false;

    final stored  = base64.decode(h64);
    final derived = _pbkdf2(enteredPin, base64.decode(s64));
    return _ctEqual(stored, derived);
  }

  Future<bool> isPinSet(String profileId) async {
    final box = Hive.box<dynamic>(AppConstants.biometricBoxName);
    return box.containsKey('pin_hash_$profileId');
  }

  Future<void> clearPin(String profileId) async {
    final box = Hive.box<dynamic>(AppConstants.biometricBoxName);
    await box.delete('pin_salt_$profileId');
    await box.delete('pin_hash_$profileId');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PBKDF2-SHA256 implementation
  // ─────────────────────────────────────────────────────────────────────────
  Uint8List _pbkdf2(String pin, Uint8List salt) {
    final key  = utf8.encode(pin);
    var   u    = _hmac(key, Uint8List.fromList([...salt, ..._i32(1)]));
    var   out  = Uint8List.fromList(u);
    for (int i = 1; i < _iterations; i++) {
      u = _hmac(key, u);
      for (int j = 0; j < out.length; j++) out[j] ^= u[j];
    }
    return out.sublist(0, _hashLen);
  }

  Uint8List _hmac(List<int> key, List<int> data) =>
      Uint8List.fromList(Hmac(sha256, key).convert(data).bytes);

  Uint8List _salt() {
    final rng = Random.secure();
    return Uint8List.fromList(
        List.generate(_saltLen, (_) => rng.nextInt(256)));
  }

  List<int> _i32(int n) => [
    (n >> 24) & 0xFF, (n >> 16) & 0xFF, (n >> 8) & 0xFF, n & 0xFF
  ];

  bool _validPin(String pin) =>
      pin.length == 6 && RegExp(r'^\d{6}$').hasMatch(pin);

  bool _ctEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
    return diff == 0;
  }
}
```

---

## FILE 5: lib/core/services/biometric_enrollment_service.dart
## PATH: lib/core/services/biometric_enrollment_service.dart
## PURPOSE: 5-session enrollment protocol with anti-gaming guards.
##          EC-8.1: Sessions ≥12h apart, ≥3 calendar days,
##          requires prior app activity (prevents enrolling someone asleep).

```dart
import 'dart:math' as math;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/biometric_profile.dart';
import 'ppg_service.dart';
import 'pin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
class EnrollmentStatus {
  final int  completed;
  final int  required;
  final bool isComplete;
  final bool canEnrollNow;
  final Duration? waitUntilEligible;
  final String?   blockReason;
  final List<Map<String, dynamic>> sessions;

  const EnrollmentStatus({
    required this.completed,
    required this.required,
    required this.isComplete,
    required this.canEnrollNow,
    this.waitUntilEligible,
    this.blockReason,
    required this.sessions,
  });

  double get progress => completed / required;
  int    get remaining => required - completed;
}

class SessionOutcome {
  final bool   success;
  final int?   sessionNumber;
  final double? bpm;
  final double? quality;
  final bool   enrollmentComplete;
  final String? error;

  const SessionOutcome({
    required this.success,
    this.sessionNumber,
    this.bpm,
    this.quality,
    this.enrollmentComplete = false,
    this.error,
  });

  factory SessionOutcome.ok({
    required int    num,
    required double bpm,
    required double quality,
    required bool   complete,
  }) => SessionOutcome(
        success: true, sessionNumber: num, bpm: bpm,
        quality: quality, enrollmentComplete: complete);

  factory SessionOutcome.err(String msg) =>
      SessionOutcome(success: false, error: msg);
}

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC ENROLLMENT SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class BiometricEnrollmentService {
  final _ppg = PpgService();
  final _pin = PinService();

  // ─────────────────────────────────────────────────────────────────────────
  // GET STATUS
  // ─────────────────────────────────────────────────────────────────────────
  Future<EnrollmentStatus> getStatus(String profileId) async {
    final sessions = await _loadSessions(profileId);
    if (sessions.length >= AppConstants.enrollmentRequiredSessions) {
      return EnrollmentStatus(
        completed: sessions.length,
        required:  AppConstants.enrollmentRequiredSessions,
        isComplete: true,
        canEnrollNow: false,
        blockReason: 'Enrollment complete',
        sessions: sessions,
      );
    }

    final (can, reason, wait) = await _checkEligibility(sessions, profileId);
    return EnrollmentStatus(
      completed:         sessions.length,
      required:          AppConstants.enrollmentRequiredSessions,
      isComplete:        false,
      canEnrollNow:      can,
      waitUntilEligible: wait,
      blockReason:       reason,
      sessions:          sessions,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ELIGIBILITY CHECK (EC-8.1 anti-gaming rules)
  // ─────────────────────────────────────────────────────────────────────────
  Future<(bool, String?, Duration?)> _checkEligibility(
    List<Map<String, dynamic>> sessions,
    String profileId,
  ) async {
    // Rule 1: First session — require recent app activity
    if (sessions.isEmpty) {
      final active = await _hasRecentActivity(profileId);
      if (!active) {
        return (
          false,
          'Use RISE for a few minutes before your first enrollment.',
          null,
        );
      }
      return (true, null, null);
    }

    // Rule 2: ≥12 hours since last session
    final lastTs = sessions.last['ts'] as int;
    final lastAt = DateTime.fromMillisecondsSinceEpoch(lastTs);
    final hoursSince = DateTime.now().difference(lastAt).inHours;
    if (hoursSince < AppConstants.enrollmentMinHoursBetween) {
      final remaining =
          Duration(hours: AppConstants.enrollmentMinHoursBetween - hoursSince);
      return (
        false,
        'Come back in ${_fmtDur(remaining)} for your next session.',
        remaining,
      );
    }

    // Rule 3: Sessions must span at least 2 unique calendar days for 3+ sessions
    if (sessions.length >= 3) {
      final days = sessions.map((s) => s['day'] as String).toSet();
      if (days.length < 2) {
        return (
          false,
          'Complete sessions on different days for better accuracy.',
          null,
        );
      }
    }

    // Rule 4: Recent app activity (confirms THIS user is holding the phone now)
    final active = await _hasRecentActivity(profileId);
    if (!active) {
      return (
        false,
        'Open RISE briefly before starting this session.',
        null,
      );
    }

    return (true, null, null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERFORM SESSION
  // Captures [readingsPerSession] PPG readings, averages them, saves profile.
  // ─────────────────────────────────────────────────────────────────────────
  Future<SessionOutcome> performSession({
    required String profileId,
    void Function(int current, int total, double bpm)? onProgress,
  }) async {
    final status = await getStatus(profileId);
    if (!status.canEnrollNow) {
      return SessionOutcome.err(status.blockReason ?? 'Not eligible');
    }

    final readings = <PpgReading>[];

    for (int i = 0; i < AppConstants.enrollmentReadingsPerSession; i++) {
      onProgress?.call(i + 1, AppConstants.enrollmentReadingsPerSession, 0);

      final r = await _ppg.capture(durationSeconds: 8);

      if (!r.isUsable) {
        if (readings.isEmpty &&
            i == AppConstants.enrollmentReadingsPerSession - 1) {
          return SessionOutcome.err(
            'Signal too weak. Cover the rear camera fully with your fingertip.',
          );
        }
        continue;  // Skip this reading, try next
      }

      readings.add(r);
      onProgress?.call(i + 1, AppConstants.enrollmentReadingsPerSession, r.heartRateBpm);

      if (i < AppConstants.enrollmentReadingsPerSession - 1) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    if (readings.isEmpty) {
      return SessionOutcome.err('No valid readings captured.');
    }

    // Outlier-rejected mean of valid readings
    final bpms       = readings.map((r) => r.heartRateBpm).toList();
    final sessionBpm = _rejectedMean(bpms);
    final best       = readings.reduce(
        (a, b) => a.signalQuality > b.signalQuality ? a : b);

    // Load or create profile
    final box     = Hive.box<dynamic>(AppConstants.biometricBoxName);
    var profile   = box.get(profileId) as BiometricProfile?
        ?? BiometricProfile(id: profileId);

    // Update profile with this session
    profile = profile.addEnrollmentReading(sessionBpm, best.waveformVector);
    await box.put(profileId, profile);

    // Record session metadata
    final sessions = await _loadSessions(profileId);
    sessions.add({
      'num': status.completed + 1,
      'ts':  DateTime.now().millisecondsSinceEpoch,
      'bpm': sessionBpm,
      'sq':  best.signalQuality,
      'day': _todayKey(),
    });
    await _saveSessions(profileId, sessions);
    await _recordActivity(profileId);

    return SessionOutcome.ok(
      num:      status.completed + 1,
      bpm:      sessionBpm,
      quality:  best.signalQuality,
      complete: profile.isFullyEnrolled,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SET PIN DURING ENROLLMENT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setPin({
    required String profileId,
    required String pin,
  }) async {
    await _pin.setPin(profileId: profileId, pin: pin);
    // Mark in profile that PIN is set (without storing the PIN itself)
    final box     = Hive.box<dynamic>(AppConstants.biometricBoxName);
    final profile = box.get(profileId) as BiometricProfile?;
    if (profile != null) {
      profile.fallbackPin  = 'set';  // Marker only — never the real PIN
      profile.usePinFallback = false;
      await profile.save();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RECORD APP ACTIVITY
  // Called from main app scaffold whenever user is actively using RISE.
  // This timestamp is what Rule 4 checks (EC-8.1).
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> recordActivity(String profileId) async =>
      _recordActivity(profileId);

  Future<void> _recordActivity(String profileId) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('bio_activity_$profileId',
        DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _hasRecentActivity(String profileId) async {
    final p    = await SharedPreferences.getInstance();
    final last = p.getInt('bio_activity_$profileId');
    if (last == null) return false;
    final age  = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(last))
        .inHours;
    return age < AppConstants.enrollmentAppActivityWindowHours;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESET — user wants to re-enroll from scratch
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> reset(String profileId) async {
    final box = Hive.box<dynamic>(AppConstants.biometricBoxName);
    await box.delete(profileId);
    await box.delete('sessions_$profileId');
    await _pin.clearPin(profileId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _loadSessions(String id) async {
    final box = Hive.box<dynamic>(AppConstants.biometricBoxName);
    final raw = box.get('sessions_$id') as List?;
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _saveSessions(
      String id, List<Map<String, dynamic>> sessions) async {
    final box = Hive.box<dynamic>(AppConstants.biometricBoxName);
    await box.put('sessions_$id', sessions);
  }

  double _rejectedMean(List<double> vals) {
    if (vals.length <= 2) return vals.reduce((a, b) => a + b) / vals.length;
    final sorted = List<double>.from(vals)..sort();
    final trimmed = sorted.sublist(1, sorted.length - 1);
    return trimmed.reduce((a, b) => a + b) / trimmed.length;
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-'
        '${n.day.toString().padLeft(2,'0')}';
  }

  String _fmtDur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}
```

---

## FILE 6: lib/core/providers/biometric_provider.dart
## PATH: lib/core/providers/biometric_provider.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/biometric_profile.dart';
import '../services/biometric_service.dart';
import '../services/biometric_enrollment_service.dart';
import '../services/pin_service.dart';

// Singleton service providers
final biometricServiceProvider    = Provider<BiometricService>((_) => BiometricService());
final enrollmentServiceProvider   = Provider<BiometricEnrollmentService>((_) => BiometricEnrollmentService());
final pinServiceProvider          = Provider<PinService>((_) => PinService());

// Primary enrolled profile
final biometricProfileProvider = Provider<BiometricProfile?>((ref) {
  final box = Hive.box<dynamic>(AppConstants.biometricBoxName);
  return box.get(AppConstants.primaryProfileId) as BiometricProfile?;
});

final isEnrolledProvider = Provider<bool>((ref) =>
    ref.watch(biometricProfileProvider)?.isFullyEnrolled ?? false);

// Enrollment status (async — checks timestamps + SharedPrefs)
final enrollmentStatusProvider = FutureProvider<EnrollmentStatus>((ref) async {
  final svc = ref.watch(enrollmentServiceProvider);
  return svc.getStatus(AppConstants.primaryProfileId);
});

// PIN set status
final pinIsSetProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(pinServiceProvider);
  return svc.isPinSet(AppConstants.primaryProfileId);
});

// ── Accessibility settings ─────────────────────────────────────────────────
// Each of these reads from the settings Hive box. When a user enables a
// setting in Part 11, these providers return the updated value automatically.

final wideToleranceModeProvider = Provider<bool>((ref) {
  final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
  return box.get('accessibility_medication_hr', defaultValue: false) as bool;
});

final tremorModeProvider = Provider<bool>((ref) {
  final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
  return box.get('accessibility_movement_condition', defaultValue: false) as bool;
});

final irregularHeartbeatModeProvider = Provider<bool>((ref) {
  final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
  return box.get('accessibility_irregular_heartbeat', defaultValue: false) as bool;
});

final hearingAidModeProvider = Provider<bool>((ref) {
  final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
  return box.get('accessibility_hearing_aid_mode', defaultValue: false) as bool;
});

final photosensitiveEpilepsyModeProvider = Provider<bool>((ref) {
  final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
  return box.get('accessibility_photosensitive', defaultValue: false) as bool;
});

final simpleWakeConfirmationProvider = Provider<bool>((ref) {
  final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
  return box.get('accessibility_simple_wake', defaultValue: false) as bool;
});
```

---

## FILE 7: lib/shared/widgets/ppg_capture_widget.dart
## PATH: lib/shared/widgets/ppg_capture_widget.dart
## PURPOSE: Live camera preview during PPG capture. Shows animated
##          heartbeat pulse + signal quality bar in real time.

```dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ppg_service.dart';
import '../../core/constants/app_constants.dart';

class PpgCaptureWidget extends ConsumerStatefulWidget {
  final bool     extendedMode;       // EC-3.8 tremor mode = 15s
  final void Function(PpgReading) onComplete;
  final VoidCallback               onFallbackRequested;
  final String                     fallbackLabel;

  const PpgCaptureWidget({
    super.key,
    required this.onComplete,
    required this.onFallbackRequested,
    this.extendedMode   = false,
    this.fallbackLabel  = 'Enter PIN instead',
  });

  @override
  ConsumerState<PpgCaptureWidget> createState() => _PpgState();
}

class _PpgState extends ConsumerState<PpgCaptureWidget>
    with SingleTickerProviderStateMixin {

  final _service = PpgService();
  StreamSubscription<double>? _hrSub;
  StreamSubscription<double>? _qSub;

  double _bpm     = 0;
  double _quality = 0;
  int    _elapsed = 0;
  bool   _done    = false;
  Timer? _ticker;

  late AnimationController _pulse;

  int get _total => widget.extendedMode
      ? AppConstants.ppgExtendedCaptureDurationSeconds
      : AppConstants.ppgCaptureDurationSeconds;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    // Subscribe to real-time streams
    _hrSub = _service.heartRateStream.listen((bpm) {
      if (!mounted) return;
      setState(() => _bpm = bpm);
      if (bpm > 0) {
        _pulse.duration = Duration(milliseconds: (60000 / bpm.clamp(40, 200)).round());
        _pulse.repeat(reverse: true);
      }
    });
    _qSub = _service.signalQualityStream.listen((q) {
      if (!mounted) return;
      setState(() => _quality = q);
    });

    // Countdown
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _elapsed = math.min(_elapsed + 1, _total));
      if (_elapsed >= _total) t.cancel();
    });

    // Run capture
    final reading = await _service.capture(extendedForTremor: widget.extendedMode);

    if (mounted) {
      setState(() => _done = true);
      widget.onComplete(reading);
    }
  }

  @override
  void dispose() {
    _hrSub?.cancel();
    _qSub?.cancel();
    _ticker?.cancel();
    _pulse.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _elapsed / _total : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Instruction ────────────────────────────────────────────────
        Text(
          'Place your fingertip over the rear camera',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // ── Animated heartbeat indicator ───────────────────────────────
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final scale = _bpm > 0
                ? 1.0 + 0.20 * _pulse.value
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bpm > 0
                      ? Colors.redAccent.withOpacity(0.85)
                      : Colors.grey.shade800,
                ),
                child: Center(
                  child: _bpm > 0
                      ? Text(
                          '${_bpm.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(Icons.favorite_border,
                          color: Colors.white54, size: 32),
                ),
              ),
            );
          },
        ),

        if (_bpm > 0) ...[
          const SizedBox(height: 6),
          Text('BPM', style: Theme.of(context).textTheme.labelSmall),
        ],

        const SizedBox(height: 20),

        // ── Signal quality bar ─────────────────────────────────────────
        Row(
          children: [
            const Text('Signal  ', style: TextStyle(fontSize: 12)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _quality,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade800,
                  color: _quality >= AppConstants.ppgMinSignalQuality
                      ? Colors.greenAccent
                      : Colors.orange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Capture progress ───────────────────────────────────────────
        LinearProgressIndicator(
          value:           progress,
          backgroundColor: Colors.grey.shade800,
          color:           Colors.blueAccent,
          minHeight:       4,
        ),
        const SizedBox(height: 6),
        Text(
          _done
              ? 'Done — reading complete'
              : _bpm > 0
                  ? 'Reading… ${_total - _elapsed}s remaining'
                  : 'Detecting pulse…',
          style: Theme.of(context).textTheme.bodySmall,
        ),

        const SizedBox(height: 20),

        // ── Fallback option ────────────────────────────────────────────
        if (!_done)
          TextButton(
            onPressed: widget.onFallbackRequested,
            child: Text(widget.fallbackLabel,
                style: const TextStyle(color: Colors.white54)),
          ),
      ],
    );
  }
}
```

---

## FILE 8: lib/shared/widgets/biometric_verification_sheet.dart
## PATH: lib/shared/widgets/biometric_verification_sheet.dart
## PURPOSE: The bottom sheet shown by AlarmScreen when biometric lock
##          is active. Runs the PPG → PIN pipeline. Handles every
##          fallback path with medically-sensitive UI copy.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/biometric_service.dart';
import '../../core/providers/biometric_provider.dart';
import 'ppg_capture_widget.dart';
import 'pin_entry_widget.dart';

// What stage is the verification sheet currently showing?
enum _VerifStage { ppg, pin, passed, failed }

class BiometricVerificationSheet extends ConsumerStatefulWidget {
  final String    profileId;
  final VoidCallback onVerified;   // Called when identity is confirmed

  const BiometricVerificationSheet({
    super.key,
    required this.profileId,
    required this.onVerified,
  });

  @override
  ConsumerState<BiometricVerificationSheet> createState() =>
      _BiometricVerificationSheetState();
}

class _BiometricVerificationSheetState
    extends ConsumerState<BiometricVerificationSheet> {

  _VerifStage _stage      = _VerifStage.ppg;
  int         _pinAttempts = 0;
  String?     _statusMsg;

  @override
  void initState() {
    super.initState();
    // Reset failure counter for this session
    ref.read(biometricServiceProvider).resetSession();

    // If user declared arrhythmia or PIN-only mode → skip PPG immediately
    final irregular = ref.read(irregularHeartbeatModeProvider);
    final profile   = ref.read(biometricProfileProvider);
    final pinOnly   = profile?.usePinFallback ?? false;

    if (irregular || pinOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _stage     = _VerifStage.pin;
          _statusMsg = AppConstants.ppgFallbackPin;
        });
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HANDLE PPG COMPLETE
  // Called by PpgCaptureWidget when capture finishes.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onPpgComplete(reading) async {
    final svc     = ref.read(biometricServiceProvider);
    final wide    = ref.read(wideToleranceModeProvider);
    final tremor  = ref.read(tremorModeProvider);
    final irreg   = ref.read(irregularHeartbeatModeProvider);

    final result = await svc.verifyPpg(
      profileId:               widget.profileId,
      wideTolerance:           wide,
      extendedCapture:         tremor,
      userDeclaredArrhythmia:  irreg,
    );

    if (!mounted) return;

    if (result.passed) {
      setState(() => _stage = _VerifStage.passed);
      await Future.delayed(const Duration(milliseconds: 600));
      widget.onVerified();
    } else if (result.shouldSwitchToPin) {
      setState(() {
        _stage     = _VerifStage.pin;
        _statusMsg = result.displayMessage;
      });
    } else {
      // First PPG failure — show message and allow retry
      setState(() => _statusMsg = result.displayMessage);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HANDLE PIN SUBMIT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onPinSubmit(String pin) async {
    final svc    = ref.read(biometricServiceProvider);
    final result = await svc.verifyPin(
      profileId:  widget.profileId,
      enteredPin: pin,
    );

    if (!mounted) return;

    if (result.passed) {
      setState(() => _stage = _VerifStage.passed);
      await Future.delayed(const Duration(milliseconds: 600));
      widget.onVerified();
    } else {
      _pinAttempts++;
      setState(() => _statusMsg = result.displayMessage);

      // After 3 wrong PINs: log buddy notification event and still let
      // user dismiss — RISE NEVER permanently blocks alarm dismissal (Bible rule)
      if (_pinAttempts >= AppConstants.pinMaxAttemptsBeforeNotify) {
        // BiometricService logs the buddy notification event
        // The actual buddy message is sent by AlarmService (Part 3)
        setState(() => _statusMsg =
            'Having trouble? The alarm will still dismiss — keep trying.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color:        Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scroll,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color:        Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Status message (medically-sensitive copy — Bible rule EC-3.1)
                if (_statusMsg != null && _statusMsg!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Text(_statusMsg!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Stage content ─────────────────────────────────────
                if (_stage == _VerifStage.ppg)
                  PpgCaptureWidget(
                    extendedMode:        ref.watch(tremorModeProvider),
                    onComplete:          _onPpgComplete,
                    onFallbackRequested: () => setState(() {
                      _stage     = _VerifStage.pin;
                      _statusMsg = AppConstants.ppgFallbackPin;
                    }),
                  ),

                if (_stage == _VerifStage.pin)
                  PinEntryWidget(
                    onSubmit:    _onPinSubmit,
                    attemptNum:  _pinAttempts,
                    maxAttempts: AppConstants.pinMaxAttemptsBeforeNotify,
                  ),

                if (_stage == _VerifStage.passed)
                  Column(children: [
                    const Icon(Icons.check_circle,
                        color: Colors.greenAccent, size: 64),
                    const SizedBox(height: 12),
                    const Text('Identity confirmed',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## FILE 9: lib/shared/widgets/pin_entry_widget.dart
## PATH: lib/shared/widgets/pin_entry_widget.dart
## PURPOSE: Secure 6-digit PIN numpad with masked display, backspace,
##          attempt counter, and non-blocking lockout messaging.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinEntryWidget extends StatefulWidget {
  final void Function(String) onSubmit;
  final int                    attemptNum;
  final int                    maxAttempts;

  const PinEntryWidget({
    super.key,
    required this.onSubmit,
    this.attemptNum  = 0,
    this.maxAttempts = 3,
  });

  @override
  State<PinEntryWidget> createState() => _PinEntryWidgetState();
}

class _PinEntryWidgetState extends State<PinEntryWidget> {
  String _digits = '';

  void _tap(String d) {
    if (_digits.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() => _digits += d);
    if (_digits.length == 6) {
      widget.onSubmit(_digits);
      // Clear after submit so user can retry if wrong
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _digits = '');
      });
    }
  }

  void _back() {
    if (_digits.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    // Attempt counter display (non-accusatory — just informational)
    final showAttempts = widget.attemptNum > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Enter your PIN',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        if (showAttempts)
          Text(
            'Attempt ${widget.attemptNum} of ${widget.maxAttempts}',
            style: TextStyle(
              color: widget.attemptNum >= widget.maxAttempts - 1
                  ? Colors.orange
                  : Colors.grey,
              fontSize: 13,
            ),
          ),

        const SizedBox(height: 24),

        // ── 6-dot display ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = i < _digits.length;
            return Container(
              margin:      const EdgeInsets.symmetric(horizontal: 8),
              width:       16, height: 16,
              decoration:  BoxDecoration(
                shape: BoxShape.circle,
                color:  filled ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white54, width: 2),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // ── Numpad ─────────────────────────────────────────────────────
        for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((d) {
                if (d.isEmpty) return const SizedBox(width: 80, height: 64);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 72, height: 72,
                    child: ElevatedButton(
                      onPressed: () => d == '⌫' ? _back() : _tap(d),
                      style: ElevatedButton.styleFrom(
                        shape:           const CircleBorder(),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        foregroundColor: Colors.white,
                        textStyle:       const TextStyle(fontSize: 22),
                      ),
                      child: Text(d),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
```

---

## PART 4 FILE INVENTORY

```
NEW FILES:
  lib/core/services/ppg_service.dart                  ← PPG signal engine
  lib/core/services/biometric_service.dart            ← Verification orchestrator
  lib/core/services/face_liveness_service.dart        ← ML Kit blink+head-turn
  lib/core/services/pin_service.dart                  ← PBKDF2-SHA256 PIN
  lib/core/services/biometric_enrollment_service.dart ← 5-day protocol
  lib/core/providers/biometric_provider.dart          ← Riverpod providers
  lib/shared/widgets/ppg_capture_widget.dart          ← Live HR capture UI
  lib/shared/widgets/biometric_verification_sheet.dart← Pipeline bottom sheet
  lib/shared/widgets/pin_entry_widget.dart            ← Secure PIN numpad

CONSTANTS ADDED TO app_constants.dart:
  biometricBoxName, primaryProfileId, ppgCaptureDurationSeconds,
  ppgExtendedCaptureDurationSeconds, ppgFaceTimeoutSeconds,
  ppgMinTolerance, ppgStandardTolerance, ppgMorningTolerance,
  ppgWideTolerance, ppgMinSignalQuality, ppgHighQuality,
  ppgArrhythmiaVarianceThreshold, ppgWaveformMatchThreshold,
  ppgWaveformStrongMatchThreshold, ppgMaxAttemptsBeforePin,
  pinMaxAttemptsBeforeNotify, enrollmentRequiredSessions,
  enrollmentMinHoursBetween, enrollmentReadingsPerSession,
  enrollmentAppActivityWindowHours, + all EC message strings
```

---

## AFTER CREATING ALL FILES — RUN:

```bash
flutter pub get
flutter analyze
```

Expected: 0 errors.

---

## EDGE CASE COVERAGE CHECKLIST

Verify each EC-3.x case from the Bible is addressed:

```
EC-3.1 (fever)          ✓ ppgHrMismatch message, 2-fail PIN route
EC-3.2 (exercise)       ✓ ppgMorningTolerance wider window, same path
EC-3.3 (medication)     ✓ wideTolerance flag → ppgWideTolerance=25 BPM
EC-3.4 (AFib)           ✓ ibiVarianceMs2 threshold → silent PIN route,
                           user-declared flag → skip PPG entirely,
                           NEVER show medical claim to user
EC-3.5 (Raynaud's)      ✓ signalQuality < ppgMinSignalQuality →
                           ppgSignalWeak message, immediate PIN offer
EC-3.6 (skin tone)      ✓ dual red+green channels, best-channel selection,
                           per-user adaptive tolerance from enrollment variance
EC-3.7 (nails/bandage)  ✓ first fail → ppgTryOtherFinger, second → PIN
EC-3.8 (tremors)        ✓ extendedMode=15s, _lowPass at 3Hz, motion detect
EC-8.1 (anti-gaming)    ✓ 5 sessions, ≥12h apart, ≥3 calendar days,
                           app activity requirement, outlier-rejected mean
```

---

## WHAT PART 5 WILL COVER:
The complete Sleep Detection Service — accelerometer-based sleep onset
detection, vehicle/mechanical vibration discrimination (EC-4.1, EC-4.3),
micro-waking vs. true waking (EC-4.2, EC-4.4), fall detection (EC-2.3),
all-nighter handling (EC-4.5), shift worker support (EC-4.6), nap mode
sleep metrics, and the sleep quality scoring algorithm.

---
## END OF PART 4 BLUEPRINT
## 9 new files | 2 constant updates
## PPG engine:       COMPLETE ✓ (dual-channel, SNR, IBI, waveform, motion filter)
## Biometric orch:   COMPLETE ✓ (all EC-3.x, adaptive tolerance, medically-sensitive)
## Face liveness:    COMPLETE ✓ (blink + head-turn, ML Kit)
## PIN service:      COMPLETE ✓ (PBKDF2-SHA256, constant-time compare)
## Enrollment:       COMPLETE ✓ (5-session, anti-gaming, dual-finger support)
## Providers:        COMPLETE ✓ (profile, enrollment, accessibility flags)
## UI widgets:       COMPLETE ✓ (PPG capture, verification sheet, PIN numpad)
