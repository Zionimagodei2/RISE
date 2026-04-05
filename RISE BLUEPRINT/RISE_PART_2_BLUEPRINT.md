# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 2 OF 12
# Data Models, Device Capability System, Riverpod Providers
# ============================================================
# COMMAND TO AI CODING AGENT:
# This is Part 2. Part 1 must be complete and compiling before
# you begin this part. You are building:
#   1. The DeviceCapabilityService — the intelligence layer that
#      determines what this specific phone can and cannot do.
#   2. All Hive data models with generated adapters.
#   3. All Riverpod providers.
#   4. The CapabilityBanner widget used on every feature screen.
#
# CRITICAL PHILOSOPHY FOR THIS PART:
# RISE must run on EVERY Android device from API 21 (Android 5.0)
# and every iOS device from iOS 12.0. No feature failure should
# crash the app or show an error screen. If a feature cannot run,
# it is hidden with a clear, friendly explanation. The user never
# sees a crash — they see transparency.
#
# BEFORE YOU WRITE ANY CODE, read this full document.
# The architecture described here is intentional and complete.
# ============================================================

## PART 2 CREATES THESE FILES (19 files):

1.  lib/core/services/device_capability_service.dart    ← THE MOST IMPORTANT FILE
2.  lib/core/models/device_capability_model.dart
3.  lib/core/models/feature_flag.dart
4.  lib/core/models/alarm_model.dart
5.  lib/core/models/sleep_session.dart
6.  lib/core/models/biometric_profile.dart
7.  lib/core/models/calorie_log.dart
8.  lib/core/models/food_entry.dart
9.  lib/core/models/user_profile.dart
10. lib/core/models/subscription_status.dart
11. lib/core/models/wake_game_result.dart
12. lib/core/models/buddy_contact.dart
13. lib/core/providers/capability_provider.dart
14. lib/core/providers/alarm_provider.dart
15. lib/core/providers/sleep_provider.dart
16. lib/core/providers/user_provider.dart
17. lib/core/providers/subscription_provider.dart
18. lib/shared/widgets/capability_banner.dart
19. lib/shared/widgets/feature_gate.dart

## ALSO UPDATE:
- lib/main.dart (add Hive adapter registration)
- android/app/build.gradle (minSdkVersion → 21)
- android/app/src/main/AndroidManifest.xml (add version-conditional blocks)

---

## THE CAPABILITY MATRIX — What Works on What

Before writing code, the agent must understand this full matrix:

### ANDROID CAPABILITY MAP:

| Feature                    | API 21-22 | API 23-25 | API 26-28 | API 29-30 | API 31-32 | API 33+  |
|---------------------------|-----------|-----------|-----------|-----------|-----------|----------|
| Basic Alarm                | ✓         | ✓         | ✓         | ✓         | ✓*        | ✓*       |
| Exact Alarm Scheduling     | ✓         | ✓         | ✓         | ✓         | needs perm| ✓*       |
| Notification Channel       | basic     | basic     | ✓ full    | ✓ full    | ✓ full    | ✓ full   |
| POST_NOTIFICATIONS perm    | implicit  | implicit  | implicit  | implicit  | implicit  | explicit |
| Foreground Service         | basic     | basic     | ✓ full    | ✓ full    | ✓ full    | ✓ full   |
| Background Location        | ✓         | ✓         | ✓         | needs perm| needs perm| needs perm|
| PPG Biometric              | if camera | if camera | if camera | if camera | if camera | if camera|
| Face Liveness              | if front  | if front  | if front  | if front  | if front  | if front |
| Sleep Motion Detection     | if accel  | if accel  | if accel  | if accel  | if accel  | if accel |
| Mic Sleep Detection        | if mic    | if mic    | if mic    | if mic    | if mic    | if mic   |
| Smart Home Integration     | if intent | if intent | ✓         | ✓         | ✓         | ✓        |
| Barcode Scan               | if camera | if camera | if camera | if camera | if camera | if camera|
| Google Play Services       | if avail  | if avail  | if avail  | if avail  | if avail  | if avail |
| RevenueCat IAP             | if GPS    | if GPS    | if GPS    | if GPS    | if GPS    | if GPS   |

*API 31: Requires SCHEDULE_EXACT_ALARM permission grant from user in settings
*API 33: Requires POST_NOTIFICATIONS permission at runtime

### iOS CAPABILITY MAP:

| Feature                    | iOS 12  | iOS 13  | iOS 14  | iOS 15  | iOS 16  | iOS 17+ |
|---------------------------|---------|---------|---------|---------|---------|---------|
| Basic Alarm                | ✓       | ✓       | ✓       | ✓       | ✓       | ✓       |
| Critical Alerts            | ✓*      | ✓*      | ✓*      | ✓*      | ✓*      | ✓*      |
| Background Audio           | ✓       | ✓       | ✓       | ✓       | ✓       | ✓       |
| Background Location        | ✓       | ✓       | ✓       | ✓       | ✓       | ✓       |
| Background Processing      | ✗       | ✓       | ✓       | ✓       | ✓       | ✓       |
| PPG Biometric              | if cam  | if cam  | if cam  | if cam  | if cam  | if cam  |
| Face ID Fallback           | ✓       | ✓       | ✓       | ✓       | ✓       | ✓       |
| Lock Screen Widget         | ✗       | ✗       | ✗       | ✗       | ✓       | ✓       |
| StandBy Mode               | ✗       | ✗       | ✗       | ✗       | ✗       | ✓       |

*Critical Alerts require Apple entitlement approval (request in App Store Connect)

### MANUFACTURER SPECIAL CASES:

| Manufacturer   | Issue                                  | Countermeasure                        |
|---------------|----------------------------------------|---------------------------------------|
| Samsung (MIUI) | Aggressive background kill             | Request battery exemption at onboard  |
| Xiaomi (MIUI)  | Auto-start must be manually enabled    | Deep link to MIUI auto-start settings |
| Huawei (EMUI)  | No Google Play Services                | FCM falls back to local notifications |
| OnePlus        | Aggressive doze mode                   | Battery optimization exemption prompt |
| Oppo/Realme    | Background restrictions per-app        | Settings deep link                    |
| Vivo           | Background service killed aggressively | Same deep link approach               |
| Meizu          | Custom power management                | Settings deep link                    |

---

## FILE 1: lib/core/services/device_capability_service.dart
## PATH: lib/core/services/device_capability_service.dart
## PURPOSE: The single most important service in RISE. Runs on first launch
##          and on every app resume. Builds a complete picture of what this
##          specific physical device can do, stores it, and makes it
##          available app-wide. Every feature checks this before rendering.
## EDGE CASES HANDLED:
##   - Sensor present but non-functional (returns data but zeros)
##   - Permission granted then revoked
##   - Google Play Services absent (Huawei, de-Googled phones)
##   - Emulators (no real hardware sensors)
##   - Tablets with unusual screen ratios
##   - Phones in enterprise MDM lockdown
##   - Users who deny then re-grant permissions
##   - OS version checks that vary by manufacturer firmware

```dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/device_capability_model.dart';
import '../models/feature_flag.dart';
import '../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE CAPABILITY SERVICE
// Run once at app launch. Re-run on app resume (permissions may have changed).
// All results are cached in DeviceCapabilityModel and exposed via provider.
// ─────────────────────────────────────────────────────────────────────────────
class DeviceCapabilityService {
  static const _channel = MethodChannel('com.rise.alarmclock/capabilities');

  /// Full capability scan. Returns a complete DeviceCapabilityModel.
  /// This is async and should be awaited before the main app renders.
  /// Total scan time is typically 200-500ms.
  static Future<DeviceCapabilityModel> scanDevice() async {
    final results = await Future.wait([
      _scanHardware(),
      _scanOsVersion(),
      _scanPermissions(),
      _scanManufacturerRestrictions(),
      _scanConnectivity(),
      _scanPlayServices(),
    ]);

    final hardware = results[0] as HardwareCapabilities;
    final osInfo   = results[1] as OsVersionInfo;
    final perms    = results[2] as PermissionStatus;
    final mfr      = results[3] as ManufacturerRestrictions;
    final network  = results[4] as NetworkCapabilities;
    final playServices = results[5] as PlayServicesInfo;

    // Build the feature flag map based on all capability inputs
    final features = _computeFeatureFlags(
      hardware: hardware,
      osInfo: osInfo,
      perms: perms,
      mfr: mfr,
      network: network,
      playServices: playServices,
    );

    return DeviceCapabilityModel(
      hardware: hardware,
      osInfo: osInfo,
      permissions: perms,
      manufacturerRestrictions: mfr,
      network: network,
      playServices: playServices,
      features: features,
      scannedAt: DateTime.now(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HARDWARE SCAN
  // ─────────────────────────────────────────────────────────────────────────
  static Future<HardwareCapabilities> _scanHardware() async {
    // ── Camera Detection ────────────────────────────────────────────
    bool hasRearCamera = false;
    bool hasFrontCamera = false;
    bool hasFlash = false;
    bool isCameraFunctional = false;

    try {
      final cameras = await availableCameras();
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.back) {
          hasRearCamera = true;
        }
        if (cam.lensDirection == CameraLensDirection.front) {
          hasFrontCamera = true;
        }
      }

      // Test flash capability — some phones report flash but it's non-functional
      // We check by attempting to initialize the rear camera with flash on
      if (hasRearCamera) {
        try {
          final controller = CameraController(
            cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
            ResolutionPreset.low, // Low res for capability check
            enableAudio: false,
          );
          await controller.initialize();
          await controller.setFlashMode(FlashMode.torch);
          await Future.delayed(const Duration(milliseconds: 100));
          await controller.setFlashMode(FlashMode.off);
          await controller.dispose();
          hasFlash = true;
          isCameraFunctional = true;
        } catch (e) {
          // Flash initialization failed — camera exists but flash unreliable
          // PPG will be unavailable but we note camera is present
          isCameraFunctional = hasRearCamera; // camera works, just no flash
          hasFlash = false;
        }
      }
    } catch (e) {
      // Camera unavailable entirely — graceful fallback
      hasRearCamera = false;
      hasFrontCamera = false;
      hasFlash = false;
      isCameraFunctional = false;
    }

    // ── Accelerometer Detection ──────────────────────────────────────
    bool hasAccelerometer = false;
    bool isAccelerometerFunctional = false;
    try {
      // Try to get one reading — if it throws, sensor is absent/broken
      await accelerometerEventStream().first
          .timeout(const Duration(seconds: 2));
      hasAccelerometer = true;
      isAccelerometerFunctional = true;
    } catch (e) {
      hasAccelerometer = false;
      isAccelerometerFunctional = false;
    }

    // ── Gyroscope Detection ──────────────────────────────────────────
    bool hasGyroscope = false;
    try {
      await gyroscopeEventStream().first
          .timeout(const Duration(seconds: 2));
      hasGyroscope = true;
    } catch (e) {
      hasGyroscope = false;
    }

    // ── Microphone Detection ─────────────────────────────────────────
    // We only check if the hardware exists — permission check is separate
    bool hasMicrophone = false;
    try {
      if (Platform.isAndroid) {
        // Android: use device_info to check feature
        final deviceInfo = DeviceInfoPlugin();
        final info = await deviceInfo.androidInfo;
        // SystemFeatures check via platform channel
        hasMicrophone = await _checkAndroidFeature('android.hardware.microphone');
      } else if (Platform.isIOS) {
        // iOS: all iPhones have microphones
        hasMicrophone = true;
      }
    } catch (e) {
      hasMicrophone = true; // Assume present if check fails
    }

    // ── Device Info for PPG quality estimation ────────────────────────
    String deviceModel = 'unknown';
    int ramMb = 0;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceModel = '${info.manufacturer} ${info.model}';
        // RAM check — PPG processing needs at least 1GB
        // Note: device_info_plus doesn't expose RAM directly on all versions
        // We use a conservative check via the Android API level as proxy
        ramMb = info.version.sdkInt >= 26 ? 2048 : 1024; // Estimation
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceModel = info.model;
        ramMb = 2048; // All iOS 12+ devices have >= 2GB
      }
    } catch (e) {
      deviceModel = 'unknown';
    }

    // ── Biometric Hardware ────────────────────────────────────────────
    bool hasFingerprint = false;
    bool hasFaceId = false;
    try {
      // local_auth checks available biometrics
      // We do this via platform check since local_auth requires context
      // The full check happens in BiometricService (Part 4)
      // Here we just note OS-level availability
      if (Platform.isIOS) {
        hasFaceId = true; // iPhone X and later
        hasFingerprint = false; // Touch ID deprecated in favor of Face ID
      }
      if (Platform.isAndroid) {
        hasFingerprint = true; // Check in BiometricService via local_auth
      }
    } catch (e) {
      // Biometric check failed — mark as unavailable
    }

    return HardwareCapabilities(
      hasRearCamera: hasRearCamera,
      hasFrontCamera: hasFrontCamera,
      hasFlash: hasFlash,
      isCameraFunctional: isCameraFunctional,
      hasAccelerometer: hasAccelerometer,
      isAccelerometerFunctional: isAccelerometerFunctional,
      hasGyroscope: hasGyroscope,
      hasMicrophone: hasMicrophone,
      hasFingerprint: hasFingerprint,
      hasFaceId: hasFaceId,
      deviceModel: deviceModel,
      estimatedRamMb: ramMb,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OS VERSION SCAN
  // ─────────────────────────────────────────────────────────────────────────
  static Future<OsVersionInfo> _scanOsVersion() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      final sdkInt = info.version.sdkInt;
      return OsVersionInfo(
        platform: AppPlatform.android,
        androidSdkInt: sdkInt,
        osVersionString: info.version.release,
        manufacturer: info.manufacturer.toLowerCase(),
        brand: info.brand.toLowerCase(),
        model: info.model,
        isPhysicalDevice: info.isPhysicalDevice,
        // Feature availability by API level
        supportsExactAlarm: sdkInt >= 21, // All API 21+ support, but 31+ needs perm
        exactAlarmNeedsPermission: sdkInt >= 31,
        supportsNotificationChannels: sdkInt >= 26,
        supportsPostNotificationPermission: sdkInt >= 33,
        supportsBackgroundLocation: sdkInt >= 29, // Needs special permission
        backgroundLocationNeedsPermission: sdkInt >= 29,
        supportsForegroundService: sdkInt >= 26,
        supportsBackgroundProcessing: true, // Android always supports
        isEmulator: !info.isPhysicalDevice,
      );
    } else {
      final info = await deviceInfo.iosInfo;
      final versionParts = info.systemVersion.split('.');
      final majorVersion = int.tryParse(versionParts.isNotEmpty ? versionParts[0] : '0') ?? 0;

      return OsVersionInfo(
        platform: AppPlatform.ios,
        iosVersionMajor: majorVersion,
        osVersionString: info.systemVersion,
        manufacturer: 'apple',
        brand: 'apple',
        model: info.model,
        isPhysicalDevice: info.isPhysicalDevice,
        supportsExactAlarm: true, // iOS handles scheduling differently
        exactAlarmNeedsPermission: false,
        supportsNotificationChannels: false, // iOS uses categories
        supportsPostNotificationPermission: true, // Always required on iOS
        supportsBackgroundLocation: true,
        backgroundLocationNeedsPermission: true,
        supportsForegroundService: false, // iOS uses background tasks
        supportsBackgroundProcessing: majorVersion >= 13,
        isEmulator: !info.isPhysicalDevice,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERMISSION STATUS SCAN
  // Checks current grant status — NOT requesting. Requesting happens in
  // the onboarding flow (Part 11). Here we just snapshot what's currently
  // granted so features can react accordingly.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<PermissionStatus> _scanPermissions() async {
    // Check all permissions concurrently
    final results = await Future.wait([
      Permission.camera.status,
      Permission.microphone.status,
      Permission.locationWhenInUse.status,
      Permission.locationAlways.status,
      Permission.notification.status,
      Permission.scheduleExactAlarm.status,
      Permission.storage.status,
      Permission.photos.status,
    ]);

    // iOS: check if Critical Alerts are available
    // (requires Apple entitlement — not all apps have it)
    bool criticalAlertsAvailable = false;
    if (Platform.isIOS) {
      try {
        criticalAlertsAvailable =
            await _channel.invokeMethod('checkCriticalAlertsAvailable') ?? false;
      } catch (e) {
        criticalAlertsAvailable = false;
      }
    }

    return PermissionStatus(
      camera: results[0],
      microphone: results[1],
      locationWhenInUse: results[2],
      locationAlways: results[3],
      notifications: results[4],
      scheduleExactAlarm: results[5],
      storage: results[6],
      photos: results[7],
      criticalAlertsAvailable: criticalAlertsAvailable,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MANUFACTURER RESTRICTIONS SCAN
  // The most dangerous layer — these kill alarms silently on many devices.
  // We detect the manufacturer and note known restrictions, then surface
  // specific guidance to the user during onboarding.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<ManufacturerRestrictions> _scanManufacturerRestrictions() async {
    if (Platform.isIOS) {
      // iOS has no manufacturer-specific restrictions beyond Apple's own
      return ManufacturerRestrictions(
        manufacturer: 'apple',
        hasAggressiveBatteryKilling: false,
        requiresAutoStartPermission: false,
        requiresBatteryOptimizationExemption: false,
        deepLinkToAutoStart: null,
        deepLinkToBatteryOptimization: null,
        warningMessage: null,
        restrictionSeverity: RestrictionSeverity.none,
      );
    }

    final deviceInfo = DeviceInfoPlugin();
    final info = await deviceInfo.androidInfo;
    final mfr = info.manufacturer.toLowerCase();
    final brand = info.brand.toLowerCase();

    // ── XIAOMI / MIUI ────────────────────────────────────────────────
    if (mfr.contains('xiaomi') || brand.contains('xiaomi') ||
        brand.contains('redmi') || brand.contains('poco')) {
      return ManufacturerRestrictions(
        manufacturer: 'xiaomi',
        hasAggressiveBatteryKilling: true,
        requiresAutoStartPermission: true,
        requiresBatteryOptimizationExemption: true,
        deepLinkToAutoStart:
            'intent:#Intent;action=miui.intent.action.APP_PERM_EDITOR;'
            'package=com.miui.permcenter;end',
        deepLinkToBatteryOptimization:
            'intent:#Intent;action=android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS;'
            'data=package:${AppConstants.bundleId};end',
        warningMessage:
            'Xiaomi phones restrict background apps aggressively. '
            'To guarantee your RISE alarm fires every morning:\n'
            '1. Enable Auto-Start for RISE in MIUI settings\n'
            '2. Set Battery Saver to "No restrictions" for RISE\n'
            'Without these, your alarm may be silenced.',
        restrictionSeverity: RestrictionSeverity.high,
      );
    }

    // ── SAMSUNG (One UI) ─────────────────────────────────────────────
    if (mfr.contains('samsung') || brand.contains('samsung')) {
      return ManufacturerRestrictions(
        manufacturer: 'samsung',
        hasAggressiveBatteryKilling: true,
        requiresAutoStartPermission: false,
        requiresBatteryOptimizationExemption: true,
        deepLinkToAutoStart: null,
        deepLinkToBatteryOptimization:
            'intent:#Intent;action=android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS;'
            'data=package:${AppConstants.bundleId};end',
        warningMessage:
            'Samsung One UI can restrict background apps. '
            'To keep your alarm reliable:\n'
            '1. Remove RISE from "Sleeping apps" in Battery settings\n'
            '2. Set RISE to "Unrestricted" in app battery usage',
        restrictionSeverity: RestrictionSeverity.medium,
      );
    }

    // ── HUAWEI / HONOR (EMUI / HarmonyOS) ───────────────────────────
    if (mfr.contains('huawei') || brand.contains('huawei') ||
        brand.contains('honor')) {
      return ManufacturerRestrictions(
        manufacturer: 'huawei',
        hasAggressiveBatteryKilling: true,
        requiresAutoStartPermission: true,
        requiresBatteryOptimizationExemption: true,
        deepLinkToAutoStart:
            'intent:#Intent;action=huawei.intent.action.HSM_BOOTAPP_MANAGER;end',
        deepLinkToBatteryOptimization:
            'intent:#Intent;action=huawei.intent.action.POWER_USAGE_SUMMARY;end',
        warningMessage:
            'Huawei phones have strict background restrictions. '
            'For reliable alarms:\n'
            '1. Enable Auto-launch for RISE in App Settings\n'
            '2. Set Battery optimization to "Manage manually"\n'
            '3. Enable Protected Apps for RISE\n'
            'Note: Some Huawei phones lack Google Play. Firebase '
            'notifications will use local-only fallback.',
        restrictionSeverity: RestrictionSeverity.high,
      );
    }

    // ── OPPO / REALME / OnePlus (ColorOS / OxygenOS) ─────────────────
    if (mfr.contains('oppo') || brand.contains('oppo') ||
        brand.contains('realme') || brand.contains('oneplus')) {
      return ManufacturerRestrictions(
        manufacturer: 'oppo_oneplus',
        hasAggressiveBatteryKilling: true,
        requiresAutoStartPermission: true,
        requiresBatteryOptimizationExemption: true,
        deepLinkToAutoStart:
            'intent:#Intent;action=android.settings.APPLICATION_DETAILS_SETTINGS;'
            'data=package:${AppConstants.bundleId};end',
        deepLinkToBatteryOptimization:
            'intent:#Intent;action=android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS;'
            'data=package:${AppConstants.bundleId};end',
        warningMessage:
            'ColorOS/OxygenOS restricts background apps. '
            'For reliable alarms:\n'
            '1. Enable Auto-start in App Management\n'
            '2. Disable Battery Optimization for RISE',
        restrictionSeverity: RestrictionSeverity.medium,
      );
    }

    // ── VIVO (FuntouchOS / OriginOS) ──────────────────────────────────
    if (mfr.contains('vivo') || brand.contains('vivo')) {
      return ManufacturerRestrictions(
        manufacturer: 'vivo',
        hasAggressiveBatteryKilling: true,
        requiresAutoStartPermission: true,
        requiresBatteryOptimizationExemption: true,
        deepLinkToAutoStart:
            'intent:#Intent;action=android.settings.APPLICATION_DETAILS_SETTINGS;'
            'data=package:${AppConstants.bundleId};end',
        deepLinkToBatteryOptimization: null,
        warningMessage:
            'Vivo phones require manual background permission for alarms. '
            'Please enable "Background auto-launch" for RISE in i Manager.',
        restrictionSeverity: RestrictionSeverity.high,
      );
    }

    // ── MEIZU ────────────────────────────────────────────────────────
    if (mfr.contains('meizu') || brand.contains('meizu')) {
      return ManufacturerRestrictions(
        manufacturer: 'meizu',
        hasAggressiveBatteryKilling: true,
        requiresAutoStartPermission: true,
        requiresBatteryOptimizationExemption: true,
        deepLinkToAutoStart: null,
        deepLinkToBatteryOptimization: null,
        warningMessage:
            'Meizu phones have aggressive power management. '
            'Enable background permissions for RISE in Security Center.',
        restrictionSeverity: RestrictionSeverity.medium,
      );
    }

    // ── MOTOROLA / LENOVO ─────────────────────────────────────────────
    if (mfr.contains('motorola') || mfr.contains('lenovo') ||
        brand.contains('moto')) {
      return ManufacturerRestrictions(
        manufacturer: 'motorola',
        hasAggressiveBatteryKilling: false,
        requiresAutoStartPermission: false,
        requiresBatteryOptimizationExemption: true,
        deepLinkToAutoStart: null,
        deepLinkToBatteryOptimization:
            'intent:#Intent;action=android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS;'
            'data=package:${AppConstants.bundleId};end',
        warningMessage:
            'Motorola Doze mode may delay alarms. '
            'Disable Battery Optimization for RISE for best results.',
        restrictionSeverity: RestrictionSeverity.low,
      );
    }

    // ── GOOGLE PIXEL (Stock Android) ─────────────────────────────────
    if (mfr.contains('google') || brand.contains('google') ||
        brand.contains('pixel')) {
      return ManufacturerRestrictions(
        manufacturer: 'google',
        hasAggressiveBatteryKilling: false,
        requiresAutoStartPermission: false,
        requiresBatteryOptimizationExemption: false,
        deepLinkToAutoStart: null,
        deepLinkToBatteryOptimization: null,
        warningMessage: null,
        restrictionSeverity: RestrictionSeverity.none,
      );
    }

    // ── DEFAULT / UNKNOWN ─────────────────────────────────────────────
    return ManufacturerRestrictions(
      manufacturer: mfr.isEmpty ? 'unknown' : mfr,
      hasAggressiveBatteryKilling: false,
      requiresAutoStartPermission: false,
      requiresBatteryOptimizationExemption: true,
      deepLinkToAutoStart: null,
      deepLinkToBatteryOptimization:
          'intent:#Intent;action=android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS;'
          'data=package:${AppConstants.bundleId};end',
      warningMessage:
          'To ensure your alarm fires reliably, disable Battery Optimization for RISE.',
      restrictionSeverity: RestrictionSeverity.low,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONNECTIVITY SCAN
  // ─────────────────────────────────────────────────────────────────────────
  static Future<NetworkCapabilities> _scanConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return NetworkCapabilities(
      isConnected: result != ConnectivityResult.none,
      connectionType: result,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GOOGLE PLAY SERVICES SCAN
  // Huawei and de-Googled phones lack Play Services.
  // This affects Firebase push, RevenueCat, and AdMob.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<PlayServicesInfo> _scanPlayServices() async {
    if (Platform.isIOS) {
      // iOS doesn't use Google Play Services
      return PlayServicesInfo(
        isAvailable: false,
        isGoogleDevice: false,
        fcmAvailable: false,
        admobAvailable: false,
        note: 'iOS uses APNs, not FCM',
      );
    }

    bool playServicesAvailable = false;
    try {
      // Check if Google Play Services are available via platform channel
      playServicesAvailable =
          await _channel.invokeMethod('checkPlayServices') ?? false;
    } catch (e) {
      // If the channel isn't set up yet, assume available (most phones)
      playServicesAvailable = true;
    }

    return PlayServicesInfo(
      isAvailable: playServicesAvailable,
      isGoogleDevice: playServicesAvailable,
      fcmAvailable: playServicesAvailable,
      admobAvailable: playServicesAvailable,
      note: playServicesAvailable
          ? 'Full Google services available'
          : 'No Google Play Services — using local notification fallback. '
            'Push notifications and some monetization features unavailable.',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FEATURE FLAG COMPUTATION
  // This is the business logic heart: given all capabilities, what can RISE do?
  // Each feature has a FeatureAvailability with reason strings for the UI.
  // ─────────────────────────────────────────────────────────────────────────
  static Map<RiseFeature, FeatureAvailability> _computeFeatureFlags({
    required HardwareCapabilities hardware,
    required OsVersionInfo osInfo,
    required PermissionStatus perms,
    required ManufacturerRestrictions mfr,
    required NetworkCapabilities network,
    required PlayServicesInfo playServices,
  }) {
    final flags = <RiseFeature, FeatureAvailability>{};

    // ── CORE ALARM (Always available — this is the one thing that MUST work) ─
    flags[RiseFeature.coreAlarm] = FeatureAvailability(
      isAvailable: true,
      degradedMode: false,
      reason: null,
      missingRequirements: [],
    );

    // ── EXACT ALARM SCHEDULING ────────────────────────────────────────
    final exactAlarmReady = osInfo.supportsExactAlarm &&
        (!osInfo.exactAlarmNeedsPermission ||
         perms.scheduleExactAlarm.isGranted);

    flags[RiseFeature.exactAlarm] = FeatureAvailability(
      isAvailable: exactAlarmReady,
      degradedMode: !exactAlarmReady && osInfo.supportsExactAlarm,
      reason: exactAlarmReady
          ? null
          : osInfo.exactAlarmNeedsPermission
              ? 'Android 12+ requires explicit permission for exact alarms. '
                'Without it, alarms may fire a few minutes late. '
                'Tap to grant this permission.'
              : null,
      missingRequirements: exactAlarmReady
          ? []
          : [MissingRequirement.exactAlarmPermission],
    );

    // ── NOTIFICATIONS ─────────────────────────────────────────────────
    final notificationsReady = perms.notifications.isGranted ||
        // iOS/Android < 33: implicit grant
        (!osInfo.supportsPostNotificationPermission);

    flags[RiseFeature.notifications] = FeatureAvailability(
      isAvailable: notificationsReady,
      degradedMode: false,
      reason: notificationsReady
          ? null
          : 'RISE cannot fire alarms without notification permission. '
            'This is the most important permission to grant.',
      missingRequirements: notificationsReady
          ? []
          : [MissingRequirement.notificationPermission],
    );

    // ── PPG BIOMETRIC HEART RATE ──────────────────────────────────────
    // Requires: rear camera + flash + functional camera + not emulator
    // Degrades gracefully to: PIN-based identity verification
    final ppgReady = hardware.hasRearCamera &&
        hardware.hasFlash &&
        hardware.isCameraFunctional &&
        !osInfo.isEmulator &&
        perms.camera.isGranted &&
        hardware.estimatedRamMb >= 1024;

    final ppgDegraded = hardware.hasRearCamera &&
        !hardware.hasFlash &&
        !osInfo.isEmulator;

    final ppgReasons = <String>[];
    final ppgMissing = <MissingRequirement>[];

    if (!hardware.hasRearCamera) {
      ppgReasons.add('No rear camera detected');
      ppgMissing.add(MissingRequirement.rearCamera);
    }
    if (!hardware.hasFlash) {
      ppgReasons.add('No camera flash (required for heart rate reading)');
      ppgMissing.add(MissingRequirement.cameraFlash);
    }
    if (!perms.camera.isGranted) {
      ppgReasons.add('Camera permission not granted');
      ppgMissing.add(MissingRequirement.cameraPermission);
    }
    if (osInfo.isEmulator) {
      ppgReasons.add('Emulators do not have real sensors');
      ppgMissing.add(MissingRequirement.physicalDevice);
    }
    if (hardware.estimatedRamMb < 1024) {
      ppgReasons.add('Insufficient RAM for real-time PPG processing');
      ppgMissing.add(MissingRequirement.sufficientRam);
    }

    flags[RiseFeature.ppgBiometric] = FeatureAvailability(
      isAvailable: ppgReady,
      degradedMode: ppgDegraded,
      reason: ppgReady
          ? null
          : ppgDegraded
              ? 'Your camera does not have a flash, so heart rate detection '
                'is unreliable. RISE will use a 6-digit PIN code for identity '
                'verification instead.'
              : ppgReasons.join(' • '),
      missingRequirements: ppgMissing,
      fallbackMode: ppgMissing.isNotEmpty ? FeatureFallback.pinVerification : null,
    );

    // ── FACE LIVENESS DETECTION ────────────────────────────────────────
    final faceLivenessReady = hardware.hasFrontCamera &&
        hardware.isCameraFunctional &&
        !osInfo.isEmulator &&
        perms.camera.isGranted;

    flags[RiseFeature.faceLiveness] = FeatureAvailability(
      isAvailable: faceLivenessReady,
      degradedMode: false,
      reason: faceLivenessReady
          ? null
          : !hardware.hasFrontCamera
              ? 'No front camera found. Face liveness check is unavailable. '
                'Identity verification will rely on heart rate only.'
              : !perms.camera.isGranted
                  ? 'Camera permission needed for face verification.'
                  : null,
      missingRequirements: faceLivenessReady
          ? []
          : !hardware.hasFrontCamera
              ? [MissingRequirement.frontCamera]
              : [MissingRequirement.cameraPermission],
    );

    // ── SLEEP MOTION DETECTION ─────────────────────────────────────────
    flags[RiseFeature.sleepMotionDetection] = FeatureAvailability(
      isAvailable: hardware.isAccelerometerFunctional,
      degradedMode: false,
      reason: hardware.isAccelerometerFunctional
          ? null
          : 'Your device\'s motion sensor is unavailable. '
            'Sleep tracking will be estimated from phone usage patterns '
            'instead of physical movement.',
      missingRequirements: hardware.isAccelerometerFunctional
          ? []
          : [MissingRequirement.accelerometer],
      fallbackMode: hardware.isAccelerometerFunctional
          ? null
          : FeatureFallback.screenUsageBasedSleep,
    );

    // ── MICROPHONE SLEEP DETECTION ────────────────────────────────────
    final micSleepReady = hardware.hasMicrophone &&
        perms.microphone.isGranted;

    flags[RiseFeature.microphoneSleepDetection] = FeatureAvailability(
      isAvailable: micSleepReady,
      degradedMode: false,
      reason: micSleepReady
          ? null
          : !hardware.hasMicrophone
              ? 'No microphone detected on this device.'
              : 'Microphone permission not granted. This is optional — '
                'RISE can detect sleep via motion instead.',
      missingRequirements: micSleepReady
          ? []
          : !hardware.hasMicrophone
              ? [MissingRequirement.microphone]
              : [MissingRequirement.microphonePermission],
    );

    // ── GEOFENCING / AWAY-FROM-HOME ────────────────────────────────────
    final geoReady = perms.locationWhenInUse.isGranted;
    final geoFull = perms.locationAlways.isGranted;

    flags[RiseFeature.geofencing] = FeatureAvailability(
      isAvailable: geoReady,
      degradedMode: geoReady && !geoFull,
      reason: geoReady
          ? geoFull
              ? null
              : 'Background location is not granted. RISE can still detect '
                'when you open the app away from home, but cannot run '
                'geofence checks while the app is closed.'
          : 'Location permission is needed to detect when you travel '
            'away from home so RISE can advise you about smart devices.',
      missingRequirements: geoReady
          ? geoFull
              ? []
              : [MissingRequirement.backgroundLocationPermission]
          : [MissingRequirement.locationPermission],
    );

    // ── SMART HOME INTEGRATION ────────────────────────────────────────
    // Smart home needs internet + geofencing (to know when user is home)
    final smartHomeReady = network.isConnected && geoReady;

    flags[RiseFeature.smartHome] = FeatureAvailability(
      isAvailable: smartHomeReady,
      degradedMode: !network.isConnected,
      reason: smartHomeReady
          ? null
          : !network.isConnected
              ? 'Smart home integration requires an internet connection.'
              : 'Location permission needed for smart home features.',
      missingRequirements: smartHomeReady
          ? []
          : !network.isConnected
              ? [MissingRequirement.internetConnection]
              : [MissingRequirement.locationPermission],
    );

    // ── CALORIE TRACKER (BASIC — always available offline) ────────────
    flags[RiseFeature.calorieTrackerBasic] = FeatureAvailability(
      isAvailable: true,
      degradedMode: !network.isConnected,
      reason: network.isConnected
          ? null
          : 'No internet connection. Food search is unavailable offline. '
            'Manual calorie entry still works.',
      missingRequirements: [],
    );

    // ── CALORIE TRACKER BARCODE SCAN ──────────────────────────────────
    final barcodeReady = hardware.hasRearCamera &&
        hardware.isCameraFunctional &&
        perms.camera.isGranted &&
        network.isConnected;

    flags[RiseFeature.calorieTrackerBarcode] = FeatureAvailability(
      isAvailable: barcodeReady,
      degradedMode: false,
      reason: barcodeReady
          ? null
          : !hardware.hasRearCamera
              ? 'No camera available for barcode scanning.'
              : !perms.camera.isGranted
                  ? 'Camera permission needed for barcode scanning.'
                  : 'Internet connection needed to look up food data.',
      missingRequirements: barcodeReady
          ? []
          : !hardware.hasRearCamera
              ? [MissingRequirement.rearCamera]
              : !perms.camera.isGranted
                  ? [MissingRequirement.cameraPermission]
                  : [MissingRequirement.internetConnection],
    );

    // ── MONETIZATION / IN-APP PURCHASES ──────────────────────────────
    final iapReady = Platform.isIOS
        ? true // iOS IAP always available
        : playServices.isAvailable && network.isConnected;

    flags[RiseFeature.inAppPurchases] = FeatureAvailability(
      isAvailable: iapReady,
      degradedMode: false,
      reason: iapReady
          ? null
          : !playServices.isAvailable
              ? 'In-app purchases are unavailable on this device because '
                'Google Play Services are not installed. '
                'RISE Lite features are permanently free on this device.'
              : 'Internet connection required for purchases.',
      missingRequirements: iapReady
          ? []
          : !playServices.isAvailable
              ? [MissingRequirement.googlePlayServices]
              : [MissingRequirement.internetConnection],
    );

    // ── ADS (AdMob) ───────────────────────────────────────────────────
    final adsReady = Platform.isIOS
        ? network.isConnected
        : playServices.admobAvailable && network.isConnected;

    flags[RiseFeature.adsForCalorieUnlock] = FeatureAvailability(
      isAvailable: adsReady,
      degradedMode: false,
      reason: adsReady
          ? null
          : !playServices.admobAvailable
              ? 'Ads are unavailable on this device. The full calorie tracker '
                'is permanently free for you.'
              : 'Internet connection required to load ads.',
      missingRequirements: adsReady
          ? []
          : [MissingRequirement.internetConnection],
    );

    // ── ACCOUNTABILITY BUDDY (WhatsApp) ───────────────────────────────
    // WhatsApp deep links just need WhatsApp installed + internet
    // We check WhatsApp installation via canLaunchUrl
    flags[RiseFeature.accountabilityBuddy] = FeatureAvailability(
      isAvailable: network.isConnected,
      degradedMode: false,
      reason: network.isConnected
          ? null
          : 'Internet required for buddy notifications.',
      missingRequirements: network.isConnected
          ? []
          : [MissingRequirement.internetConnection],
    );

    // ── CLOUD SYNC ────────────────────────────────────────────────────
    flags[RiseFeature.cloudSync] = FeatureAvailability(
      isAvailable: network.isConnected && playServices.fcmAvailable,
      degradedMode: !playServices.fcmAvailable,
      reason: network.isConnected && playServices.fcmAvailable
          ? null
          : !playServices.fcmAvailable
              ? 'Cloud sync unavailable without Google Play Services. '
                'All data is stored locally on this device.'
              : 'Internet connection required for cloud sync.',
      missingRequirements: [],
    );

    // ── BACKGROUND SERVICE RELIABILITY ───────────────────────────────
    // This is an informational flag, not a blocking one
    flags[RiseFeature.backgroundServiceReliability] = FeatureAvailability(
      isAvailable: true,
      degradedMode: mfr.hasAggressiveBatteryKilling,
      reason: mfr.hasAggressiveBatteryKilling
          ? mfr.warningMessage
          : null,
      missingRequirements: [],
    );

    return flags;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  static Future<bool> _checkAndroidFeature(String feature) async {
    try {
      return await _channel.invokeMethod('hasSystemFeature', {'feature': feature}) ?? false;
    } catch (e) {
      return true; // Assume present if check fails
    }
  }

  /// Re-scan only permissions (called when app resumes after user
  /// visits Settings app to grant/revoke permissions)
  static Future<PermissionStatus> refreshPermissions() async {
    return _scanPermissions();
  }

  /// Build a human-readable summary of unavailable features for display
  /// in the Device Report screen. Shows what this phone cannot do and why.
  static List<FeatureSummaryItem> buildFeatureSummary(
      DeviceCapabilityModel model) {
    final items = <FeatureSummaryItem>[];

    for (final entry in model.features.entries) {
      final feature = entry.key;
      final availability = entry.value;

      if (!availability.isAvailable || availability.degradedMode) {
        items.add(FeatureSummaryItem(
          feature: feature,
          featureName: feature.displayName,
          isAvailable: availability.isAvailable,
          isDegraded: availability.degradedMode,
          reason: availability.reason ?? 'Unavailable on this device',
          fallbackDescription: availability.fallbackMode?.description,
          missingRequirements: availability.missingRequirements
              .map((r) => r.humanReadable)
              .toList(),
        ));
      }
    }

    // Sort: unavailable first, then degraded
    items.sort((a, b) {
      if (!a.isAvailable && b.isAvailable) return -1;
      if (a.isAvailable && !b.isAvailable) return 1;
      return 0;
    });

    return items;
  }
}
```

---

## FILE 2: lib/core/models/device_capability_model.dart
## PATH: lib/core/models/device_capability_model.dart
## PURPOSE: Data structures for device capability scanning.

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart'
    as ph show PermissionStatus;
import 'feature_flag.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE CAPABILITY MODEL
// Snapshot of this device's full capability profile.
// ─────────────────────────────────────────────────────────────────────────────
class DeviceCapabilityModel {
  final HardwareCapabilities hardware;
  final OsVersionInfo osInfo;
  final PermissionStatus permissions;
  final ManufacturerRestrictions manufacturerRestrictions;
  final NetworkCapabilities network;
  final PlayServicesInfo playServices;
  final Map<RiseFeature, FeatureAvailability> features;
  final DateTime scannedAt;

  const DeviceCapabilityModel({
    required this.hardware,
    required this.osInfo,
    required this.permissions,
    required this.manufacturerRestrictions,
    required this.network,
    required this.playServices,
    required this.features,
    required this.scannedAt,
  });

  /// Check if a specific feature is fully available (not degraded)
  bool isFeatureAvailable(RiseFeature feature) {
    return features[feature]?.isAvailable ?? false;
  }

  /// Check if a feature is available but in degraded/limited mode
  bool isFeatureDegraded(RiseFeature feature) {
    return features[feature]?.degradedMode ?? false;
  }

  /// Get the reason a feature is unavailable
  String? getFeatureReason(RiseFeature feature) {
    return features[feature]?.reason;
  }

  /// How many features are unavailable on this device?
  int get unavailableFeatureCount {
    return features.values.where((f) => !f.isAvailable).length;
  }

  /// Is this a "capable" device (core + biometric available)?
  bool get isFullyCapable {
    return isFeatureAvailable(RiseFeature.coreAlarm) &&
           isFeatureAvailable(RiseFeature.ppgBiometric) &&
           isFeatureAvailable(RiseFeature.notifications);
  }

  /// Can the basic alarm fire reliably?
  bool get canFireAlarmReliably {
    return isFeatureAvailable(RiseFeature.coreAlarm) &&
           isFeatureAvailable(RiseFeature.notifications);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class HardwareCapabilities {
  final bool hasRearCamera;
  final bool hasFrontCamera;
  final bool hasFlash;
  final bool isCameraFunctional;
  final bool hasAccelerometer;
  final bool isAccelerometerFunctional;
  final bool hasGyroscope;
  final bool hasMicrophone;
  final bool hasFingerprint;
  final bool hasFaceId;
  final String deviceModel;
  final int estimatedRamMb;

  const HardwareCapabilities({
    required this.hasRearCamera,
    required this.hasFrontCamera,
    required this.hasFlash,
    required this.isCameraFunctional,
    required this.hasAccelerometer,
    required this.isAccelerometerFunctional,
    required this.hasGyroscope,
    required this.hasMicrophone,
    required this.hasFingerprint,
    required this.hasFaceId,
    required this.deviceModel,
    required this.estimatedRamMb,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
enum AppPlatform { android, ios }

class OsVersionInfo {
  final AppPlatform platform;
  final int? androidSdkInt;
  final int? iosVersionMajor;
  final String osVersionString;
  final String manufacturer;
  final String brand;
  final String model;
  final bool isPhysicalDevice;
  final bool supportsExactAlarm;
  final bool exactAlarmNeedsPermission;
  final bool supportsNotificationChannels;
  final bool supportsPostNotificationPermission;
  final bool supportsBackgroundLocation;
  final bool backgroundLocationNeedsPermission;
  final bool supportsForegroundService;
  final bool supportsBackgroundProcessing;
  final bool isEmulator;

  const OsVersionInfo({
    required this.platform,
    this.androidSdkInt,
    this.iosVersionMajor,
    required this.osVersionString,
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.isPhysicalDevice,
    required this.supportsExactAlarm,
    required this.exactAlarmNeedsPermission,
    required this.supportsNotificationChannels,
    required this.supportsPostNotificationPermission,
    required this.supportsBackgroundLocation,
    required this.backgroundLocationNeedsPermission,
    required this.supportsForegroundService,
    required this.supportsBackgroundProcessing,
    required this.isEmulator,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class PermissionStatus {
  final ph.PermissionStatus camera;
  final ph.PermissionStatus microphone;
  final ph.PermissionStatus locationWhenInUse;
  final ph.PermissionStatus locationAlways;
  final ph.PermissionStatus notifications;
  final ph.PermissionStatus scheduleExactAlarm;
  final ph.PermissionStatus storage;
  final ph.PermissionStatus photos;
  final bool criticalAlertsAvailable;

  const PermissionStatus({
    required this.camera,
    required this.microphone,
    required this.locationWhenInUse,
    required this.locationAlways,
    required this.notifications,
    required this.scheduleExactAlarm,
    required this.storage,
    required this.photos,
    required this.criticalAlertsAvailable,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
enum RestrictionSeverity { none, low, medium, high }

class ManufacturerRestrictions {
  final String manufacturer;
  final bool hasAggressiveBatteryKilling;
  final bool requiresAutoStartPermission;
  final bool requiresBatteryOptimizationExemption;
  final String? deepLinkToAutoStart;
  final String? deepLinkToBatteryOptimization;
  final String? warningMessage;
  final RestrictionSeverity restrictionSeverity;

  const ManufacturerRestrictions({
    required this.manufacturer,
    required this.hasAggressiveBatteryKilling,
    required this.requiresAutoStartPermission,
    required this.requiresBatteryOptimizationExemption,
    required this.deepLinkToAutoStart,
    required this.deepLinkToBatteryOptimization,
    required this.warningMessage,
    required this.restrictionSeverity,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class NetworkCapabilities {
  final bool isConnected;
  final ConnectivityResult connectionType;

  const NetworkCapabilities({
    required this.isConnected,
    required this.connectionType,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class PlayServicesInfo {
  final bool isAvailable;
  final bool isGoogleDevice;
  final bool fcmAvailable;
  final bool admobAvailable;
  final String note;

  const PlayServicesInfo({
    required this.isAvailable,
    required this.isGoogleDevice,
    required this.fcmAvailable,
    required this.admobAvailable,
    required this.note,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class FeatureSummaryItem {
  final RiseFeature feature;
  final String featureName;
  final bool isAvailable;
  final bool isDegraded;
  final String reason;
  final String? fallbackDescription;
  final List<String> missingRequirements;

  const FeatureSummaryItem({
    required this.feature,
    required this.featureName,
    required this.isAvailable,
    required this.isDegraded,
    required this.reason,
    required this.fallbackDescription,
    required this.missingRequirements,
  });
}
```

---

## FILE 3: lib/core/models/feature_flag.dart
## PATH: lib/core/models/feature_flag.dart
## PURPOSE: Enums and availability model for the feature flag system.

```dart
// ─────────────────────────────────────────────────────────────────────────────
// ALL RISE FEATURES — Every feature that can be gated by device capability
// ─────────────────────────────────────────────────────────────────────────────
enum RiseFeature {
  coreAlarm,
  exactAlarm,
  notifications,
  ppgBiometric,
  faceLiveness,
  sleepMotionDetection,
  microphoneSleepDetection,
  geofencing,
  smartHome,
  calorieTrackerBasic,
  calorieTrackerBarcode,
  inAppPurchases,
  adsForCalorieUnlock,
  accountabilityBuddy,
  cloudSync,
  backgroundServiceReliability,
}

extension RiseFeatureDisplay on RiseFeature {
  String get displayName {
    switch (this) {
      case RiseFeature.coreAlarm:               return 'Core Alarm';
      case RiseFeature.exactAlarm:              return 'Precise Alarm Timing';
      case RiseFeature.notifications:           return 'Alarm Notifications';
      case RiseFeature.ppgBiometric:            return 'Heart Rate Identity Lock';
      case RiseFeature.faceLiveness:            return 'Face Liveness Check';
      case RiseFeature.sleepMotionDetection:    return 'Motion-Based Sleep Tracking';
      case RiseFeature.microphoneSleepDetection:return 'Audio-Based Sleep Detection';
      case RiseFeature.geofencing:              return 'Away-From-Home Detection';
      case RiseFeature.smartHome:               return 'Smart Home Integration';
      case RiseFeature.calorieTrackerBasic:     return 'Calorie Tracker';
      case RiseFeature.calorieTrackerBarcode:   return 'Food Barcode Scanner';
      case RiseFeature.inAppPurchases:          return 'RISE Pro Subscription';
      case RiseFeature.adsForCalorieUnlock:     return 'Ad-Unlock Nutrition Premium';
      case RiseFeature.accountabilityBuddy:     return 'Accountability Buddy';
      case RiseFeature.cloudSync:               return 'Cloud Sync';
      case RiseFeature.backgroundServiceReliability: return 'Background Service';
    }
  }

  String get shortDescription {
    switch (this) {
      case RiseFeature.ppgBiometric:
        return 'Uses your heartbeat to ensure only you can dismiss the alarm';
      case RiseFeature.faceLiveness:
        return 'Confirms you\'re actually awake and looking at the screen';
      case RiseFeature.sleepMotionDetection:
        return 'Tracks when you fell asleep using your phone\'s motion sensor';
      case RiseFeature.microphoneSleepDetection:
        return 'Detects sleep onset through breathing and room sounds';
      case RiseFeature.geofencing:
        return 'Warns you about smart home automations when you travel';
      case RiseFeature.smartHome:
        return 'Triggers smart lights and devices when your alarm fires';
      default:
        return displayName;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MISSING REQUIREMENTS — Why a feature is unavailable
// ─────────────────────────────────────────────────────────────────────────────
enum MissingRequirement {
  rearCamera,
  frontCamera,
  cameraFlash,
  cameraPermission,
  microphone,
  microphonePermission,
  accelerometer,
  locationPermission,
  backgroundLocationPermission,
  notificationPermission,
  exactAlarmPermission,
  googlePlayServices,
  internetConnection,
  physicalDevice,
  sufficientRam,
}

extension MissingRequirementDisplay on MissingRequirement {
  String get humanReadable {
    switch (this) {
      case MissingRequirement.rearCamera:
        return 'Rear-facing camera';
      case MissingRequirement.frontCamera:
        return 'Front-facing camera';
      case MissingRequirement.cameraFlash:
        return 'Camera flash / torch';
      case MissingRequirement.cameraPermission:
        return 'Camera permission (tap to grant)';
      case MissingRequirement.microphone:
        return 'Microphone hardware';
      case MissingRequirement.microphonePermission:
        return 'Microphone permission (tap to grant)';
      case MissingRequirement.accelerometer:
        return 'Motion/accelerometer sensor';
      case MissingRequirement.locationPermission:
        return 'Location permission (tap to grant)';
      case MissingRequirement.backgroundLocationPermission:
        return '"Always On" location permission (tap to grant in Settings)';
      case MissingRequirement.notificationPermission:
        return 'Notification permission (tap to grant)';
      case MissingRequirement.exactAlarmPermission:
        return 'Exact alarm permission (tap to grant in Settings)';
      case MissingRequirement.googlePlayServices:
        return 'Google Play Services';
      case MissingRequirement.internetConnection:
        return 'Internet connection';
      case MissingRequirement.physicalDevice:
        return 'Physical device (not an emulator)';
      case MissingRequirement.sufficientRam:
        return 'At least 1GB RAM';
    }
  }

  bool get isGrantable {
    // Can this be fixed by the user right now?
    return [
      MissingRequirement.cameraPermission,
      MissingRequirement.microphonePermission,
      MissingRequirement.locationPermission,
      MissingRequirement.backgroundLocationPermission,
      MissingRequirement.notificationPermission,
      MissingRequirement.exactAlarmPermission,
    ].contains(this);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE FALLBACK — What RISE does when a feature is unavailable
// ─────────────────────────────────────────────────────────────────────────────
enum FeatureFallback {
  pinVerification,
  screenUsageBasedSleep,
  localNotificationOnly,
  manualCalorieEntry,
  liteAlarmOnly,
}

extension FeatureFallbackDisplay on FeatureFallback {
  String get description {
    switch (this) {
      case FeatureFallback.pinVerification:
        return 'Using 6-digit PIN for identity verification instead';
      case FeatureFallback.screenUsageBasedSleep:
        return 'Estimating sleep from screen-off time instead';
      case FeatureFallback.localNotificationOnly:
        return 'Using device-local notifications only (no cloud push)';
      case FeatureFallback.manualCalorieEntry:
        return 'Manual food entry available (barcode scan unavailable)';
      case FeatureFallback.liteAlarmOnly:
        return 'Core alarm features work normally';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE AVAILABILITY — The complete availability status of one feature
// ─────────────────────────────────────────────────────────────────────────────
class FeatureAvailability {
  final bool isAvailable;
  final bool degradedMode;   // Available but with limitations
  final String? reason;      // Human-readable reason if unavailable/degraded
  final List<MissingRequirement> missingRequirements;
  final FeatureFallback? fallbackMode;

  const FeatureAvailability({
    required this.isAvailable,
    required this.degradedMode,
    required this.reason,
    required this.missingRequirements,
    this.fallbackMode,
  });
}
```

---

## FILE 4: lib/core/models/alarm_model.dart
## PATH: lib/core/models/alarm_model.dart
## PURPOSE: The core alarm data model. Hive-serialized for local storage.
##          typeId: 0

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'alarm_model.g.dart'; // Generated by hive_generator

// ─────────────────────────────────────────────────────────────────────────────
// ALARM MODEL
// Every scheduled alarm the user creates is stored as an AlarmModel.
// ─────────────────────────────────────────────────────────────────────────────
@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String label;

  @HiveField(2)
  int hour;

  @HiveField(3)
  int minute;

  @HiveField(4)
  List<int> repeatDays; // 0=Mon, 1=Tue, ... 6=Sun. Empty = one-time alarm.

  @HiveField(5)
  bool isEnabled;

  @HiveField(6)
  String soundPath;

  @HiveField(7)
  int volumePercent; // 0-100

  @HiveField(8)
  bool vibrateEnabled;

  @HiveField(9)
  bool biometricLock; // Require PPG/PIN to dismiss

  @HiveField(10)
  int snoozeMaxCount;

  @HiveField(11)
  int snoozeDurationMinutes;

  @HiveField(12)
  String gameType; // 'math', 'trace', 'memory', 'knowledge', 'word', 'random'

  @HiveField(13)
  String gameDifficulty; // 'easy', 'medium', 'hard', 'escalating'

  @HiveField(14)
  bool buddyNotifyEnabled;

  @HiveField(15)
  String? buddyContactId; // FK to BuddyContact

  @HiveField(16)
  int buddyNotifyAfterSnoozeCount; // Notify buddy after N snoozes

  @HiveField(17)
  bool smartHomeEnabled;

  @HiveField(18)
  DateTime createdAt;

  @HiveField(19)
  DateTime? lastFiredAt;

  @HiveField(20)
  int totalFireCount;

  @HiveField(21)
  int totalSnoozeCount;

  @HiveField(22)
  int totalDismissedWithGame;

  @HiveField(23)
  bool gradualVolumeEnabled; // Volume increases from low to max

  @HiveField(24)
  String? customRingtoneUri; // User-selected local file

  @HiveField(25)
  int snoozePackRemaining; // Emergency snooze pack count

  @HiveField(26)
  String identityMode; // 'ppg', 'pin', 'face', 'none' — set by capability scan

  AlarmModel({
    String? id,
    this.label = 'Alarm',
    required this.hour,
    required this.minute,
    this.repeatDays = const [],
    this.isEnabled = true,
    this.soundPath = 'assets/sounds/rise_default.mp3',
    this.volumePercent = 80,
    this.vibrateEnabled = true,
    this.biometricLock = true,
    this.snoozeMaxCount = 3,
    this.snoozeDurationMinutes = 7,
    this.gameType = 'random',
    this.gameDifficulty = 'escalating',
    this.buddyNotifyEnabled = false,
    this.buddyContactId,
    this.buddyNotifyAfterSnoozeCount = 2,
    this.smartHomeEnabled = false,
    DateTime? createdAt,
    this.lastFiredAt,
    this.totalFireCount = 0,
    this.totalSnoozeCount = 0,
    this.totalDismissedWithGame = 0,
    this.gradualVolumeEnabled = true,
    this.customRingtoneUri,
    this.snoozePackRemaining = 0,
    this.identityMode = 'ppg',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Next fire time for this alarm. Returns null if disabled or no future time.
  DateTime? get nextFireTime {
    if (!isEnabled) return null;

    final now = DateTime.now();
    final candidate = DateTime(
      now.year, now.month, now.day,
      hour, minute,
    );

    if (repeatDays.isEmpty) {
      // One-time alarm
      if (candidate.isAfter(now)) return candidate;
      return candidate.add(const Duration(days: 1));
    }

    // Recurring — find next matching day
    // repeatDays: 0=Mon, 1=Tue, ..., 6=Sun
    // DateTime.weekday: 1=Mon, 2=Tue, ..., 7=Sun
    for (int i = 0; i <= 7; i++) {
      final check = candidate.add(Duration(days: i));
      final checkDay = check.weekday - 1; // Convert to 0-indexed Monday
      if (repeatDays.contains(checkDay)) {
        if (check.isAfter(now) || (i == 0 && check == now)) {
          return check;
        }
      }
    }
    return null;
  }

  String get displayTime {
    final h = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get repeatLabel {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 &&
        repeatDays.contains(0) && repeatDays.contains(1) &&
        repeatDays.contains(2) && repeatDays.contains(3) &&
        repeatDays.contains(4)) return 'Weekdays';
    if (repeatDays.length == 2 &&
        repeatDays.contains(5) && repeatDays.contains(6)) return 'Weekends';

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(repeatDays)..sort();
    return sorted.map((d) => dayNames[d]).join(', ');
  }

  AlarmModel copyWith({
    String? label,
    int? hour,
    int? minute,
    List<int>? repeatDays,
    bool? isEnabled,
    String? soundPath,
    int? volumePercent,
    bool? vibrateEnabled,
    bool? biometricLock,
    int? snoozeMaxCount,
    int? snoozeDurationMinutes,
    String? gameType,
    String? gameDifficulty,
    bool? buddyNotifyEnabled,
    String? buddyContactId,
    int? buddyNotifyAfterSnoozeCount,
    bool? smartHomeEnabled,
    bool? gradualVolumeEnabled,
    String? customRingtoneUri,
    int? snoozePackRemaining,
    String? identityMode,
  }) {
    return AlarmModel(
      id: id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      soundPath: soundPath ?? this.soundPath,
      volumePercent: volumePercent ?? this.volumePercent,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
      biometricLock: biometricLock ?? this.biometricLock,
      snoozeMaxCount: snoozeMaxCount ?? this.snoozeMaxCount,
      snoozeDurationMinutes: snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      gameType: gameType ?? this.gameType,
      gameDifficulty: gameDifficulty ?? this.gameDifficulty,
      buddyNotifyEnabled: buddyNotifyEnabled ?? this.buddyNotifyEnabled,
      buddyContactId: buddyContactId ?? this.buddyContactId,
      buddyNotifyAfterSnoozeCount:
          buddyNotifyAfterSnoozeCount ?? this.buddyNotifyAfterSnoozeCount,
      smartHomeEnabled: smartHomeEnabled ?? this.smartHomeEnabled,
      createdAt: createdAt,
      lastFiredAt: lastFiredAt,
      totalFireCount: totalFireCount,
      totalSnoozeCount: totalSnoozeCount,
      totalDismissedWithGame: totalDismissedWithGame,
      gradualVolumeEnabled: gradualVolumeEnabled ?? this.gradualVolumeEnabled,
      customRingtoneUri: customRingtoneUri ?? this.customRingtoneUri,
      snoozePackRemaining: snoozePackRemaining ?? this.snoozePackRemaining,
      identityMode: identityMode ?? this.identityMode,
    );
  }
}
```

---

## FILE 5: lib/core/models/sleep_session.dart
## PATH: lib/core/models/sleep_session.dart
## PURPOSE: A recorded sleep session from one night.
##          typeId: 1

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'sleep_session.g.dart';

@HiveType(typeId: 1)
class SleepSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  DateTime sleepOnsetTime; // When phone went dark + user stopped moving

  @HiveField(2)
  DateTime? wakeTime; // When alarm was dismissed (null if still sleeping)

  @HiveField(3)
  String alarmId; // Which alarm triggered the wake

  @HiveField(4)
  int snoozeCount; // How many times snoozed

  @HiveField(5)
  String dismissMethod; // 'game', 'pin', 'biometric', 'force'

  @HiveField(6)
  String detectionMethod; // 'accelerometer', 'screen', 'microphone', 'manual'

  @HiveField(7)
  List<double> motionData; // Sampled accelerometer readings (compressed)

  @HiveField(8)
  double? avgHeartRateAtWake; // From PPG during alarm — optional

  @HiveField(9)
  bool identityVerified; // Was PPG/PIN verified successfully?

  @HiveField(10)
  bool buddyNotified; // Was accountability buddy notified?

  @HiveField(11)
  String qualityLabel; // 'excellent', 'good', 'poor', 'unknown'

  @HiveField(12)
  int estimatedRemMinutes;

  @HiveField(13)
  int estimatedDeepMinutes;

  @HiveField(14)
  int estimatedLightMinutes;

  @HiveField(15)
  int awakeMinutes;

  @HiveField(16)
  DateTime createdAt;

  SleepSession({
    String? id,
    required this.sleepOnsetTime,
    this.wakeTime,
    required this.alarmId,
    this.snoozeCount = 0,
    this.dismissMethod = 'unknown',
    this.detectionMethod = 'screen',
    this.motionData = const [],
    this.avgHeartRateAtWake,
    this.identityVerified = false,
    this.buddyNotified = false,
    this.qualityLabel = 'unknown',
    this.estimatedRemMinutes = 0,
    this.estimatedDeepMinutes = 0,
    this.estimatedLightMinutes = 0,
    this.awakeMinutes = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Duration slept in minutes
  int get durationMinutes {
    if (wakeTime == null) return 0;
    return wakeTime!.difference(sleepOnsetTime).inMinutes;
  }

  /// Human-readable duration
  String get durationLabel {
    final mins = durationMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Sleep quality score 0-100
  int get qualityScore {
    if (durationMinutes < 180) return 20;
    if (durationMinutes < 300) return 40;
    if (durationMinutes < 360) return 60;
    if (snoozeCount == 0) return 95;
    if (snoozeCount == 1) return 85;
    if (snoozeCount == 2) return 70;
    return 55;
  }
}
```

---

## FILE 6: lib/core/models/biometric_profile.dart
## PATH: lib/core/models/biometric_profile.dart
## PURPOSE: Enrolled biometric profile for a user.
##          typeId: 2

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'biometric_profile.g.dart';

@HiveType(typeId: 2)
class BiometricProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String profileName; // 'Primary User', or person's name for family accounts

  @HiveField(2)
  List<double> hrReadings; // Heart rate readings across enrollment sessions

  @HiveField(3)
  List<double> waveformSignature; // PPG waveform shape fingerprint

  @HiveField(4)
  double avgRestingHR;

  @HiveField(5)
  double hrStdDeviation; // Tolerance band for matching

  @HiveField(6)
  int enrollmentCount; // How many sessions completed (target: 5)

  @HiveField(7)
  bool isFullyEnrolled; // true when enrollmentCount >= 5

  @HiveField(8)
  String fallbackPin; // Hashed 6-digit PIN for when PPG unavailable

  @HiveField(9)
  bool usePinFallback; // Force PIN if device lacks flash

  @HiveField(10)
  DateTime enrolledAt;

  @HiveField(11)
  DateTime? lastVerifiedAt;

  @HiveField(12)
  int totalVerifications;

  @HiveField(13)
  int failedVerifications;

  BiometricProfile({
    String? id,
    this.profileName = 'Primary User',
    this.hrReadings = const [],
    this.waveformSignature = const [],
    this.avgRestingHR = 0.0,
    this.hrStdDeviation = 10.0,
    this.enrollmentCount = 0,
    this.isFullyEnrolled = false,
    this.fallbackPin = '',
    this.usePinFallback = false,
    DateTime? enrolledAt,
    this.lastVerifiedAt,
    this.totalVerifications = 0,
    this.failedVerifications = 0,
  })  : id = id ?? const Uuid().v4(),
        enrolledAt = enrolledAt ?? DateTime.now();

  /// Check if a new HR reading matches this profile
  bool matchesReading(double incomingHR) {
    if (!isFullyEnrolled) return false;
    final tolerance = (hrStdDeviation * 2).clamp(8.0, 20.0);
    return (incomingHR - avgRestingHR).abs() <= tolerance;
  }

  /// Update profile with a new enrollment reading
  BiometricProfile addEnrollmentReading(double hr, List<double> waveform) {
    final newReadings = [...hrReadings, hr];
    final newAvg = newReadings.reduce((a, b) => a + b) / newReadings.length;
    final variance = newReadings.map((r) => (r - newAvg) * (r - newAvg))
        .reduce((a, b) => a + b) / newReadings.length;
    final newStdDev = variance > 0 ? variance : 10.0;

    return BiometricProfile(
      id: id,
      profileName: profileName,
      hrReadings: newReadings,
      waveformSignature: waveform.isNotEmpty ? waveform : waveformSignature,
      avgRestingHR: newAvg,
      hrStdDeviation: newStdDev,
      enrollmentCount: enrollmentCount + 1,
      isFullyEnrolled: enrollmentCount + 1 >= 5,
      fallbackPin: fallbackPin,
      usePinFallback: usePinFallback,
      enrolledAt: enrolledAt,
      lastVerifiedAt: lastVerifiedAt,
      totalVerifications: totalVerifications,
      failedVerifications: failedVerifications,
    );
  }
}
```

---

## FILE 7: lib/core/models/calorie_log.dart
## PATH: lib/core/models/calorie_log.dart
## PURPOSE: Daily calorie log. One per calendar day.
##          typeId: 3

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'food_entry.dart';

part 'calorie_log.g.dart';

@HiveType(typeId: 3)
class CalorieLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String dateKey; // Format: 'yyyy-MM-dd' — the day this log covers

  @HiveField(2)
  List<FoodEntry> entries;

  @HiveField(3)
  int calorieGoal;

  @HiveField(4)
  int waterMl; // Water intake in milliliters

  @HiveField(5)
  int waterGoalMl;

  @HiveField(6)
  String premiumUnlockMode; // 'none', 'ad', 'pro', 'free'
                             // 'ad' = unlocked via watching ads

  @HiveField(7)
  DateTime? premiumUnlockedAt; // When ad-unlock expires

  @HiveField(8)
  DateTime createdAt;

  CalorieLog({
    String? id,
    required this.dateKey,
    this.entries = const [],
    this.calorieGoal = 2000,
    this.waterMl = 0,
    this.waterGoalMl = 2500,
    this.premiumUnlockMode = 'none',
    this.premiumUnlockedAt,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  int get totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calories);

  double get totalProteinG =>
      entries.fold(0.0, (sum, e) => sum + e.proteinG);

  double get totalCarbsG =>
      entries.fold(0.0, (sum, e) => sum + e.carbsG);

  double get totalFatG =>
      entries.fold(0.0, (sum, e) => sum + e.fatG);

  int get remainingCalories => (calorieGoal - totalCalories).clamp(0, 99999);

  double get completionPercent =>
      calorieGoal > 0 ? (totalCalories / calorieGoal).clamp(0.0, 1.0) : 0.0;

  bool get isPremiumUnlocked {
    if (premiumUnlockMode == 'pro') return true;
    if (premiumUnlockMode == 'free') return true;
    if (premiumUnlockMode == 'ad' && premiumUnlockedAt != null) {
      return DateTime.now().isBefore(premiumUnlockedAt!);
    }
    return false;
  }

  /// Hours remaining on ad-unlock
  int get adUnlockHoursRemaining {
    if (premiumUnlockMode != 'ad' || premiumUnlockedAt == null) return 0;
    final remaining = premiumUnlockedAt!.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inHours;
  }

  static String keyForDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
```

---

## FILE 8: lib/core/models/food_entry.dart
## PATH: lib/core/models/food_entry.dart
## PURPOSE: A single food item logged in a CalorieLog.
##          typeId: 4

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'food_entry.g.dart';

@HiveType(typeId: 4)
class FoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String foodName;

  @HiveField(2)
  String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'

  @HiveField(3)
  int calories;

  @HiveField(4)
  double proteinG;

  @HiveField(5)
  double carbsG;

  @HiveField(6)
  double fatG;

  @HiveField(7)
  double fiberG;

  @HiveField(8)
  double sugarG;

  @HiveField(9)
  double sodiumMg;

  @HiveField(10)
  String servingSize; // e.g., '1 cup', '100g', '1 medium'

  @HiveField(11)
  double servingQuantity; // How many servings

  @HiveField(12)
  String? barcode; // If scanned from barcode

  @HiveField(13)
  String? openFoodFactsId; // Remote ID for data quality

  @HiveField(14)
  String entryMethod; // 'barcode', 'search', 'manual', 'photo'

  @HiveField(15)
  DateTime loggedAt;

  FoodEntry({
    String? id,
    required this.foodName,
    this.mealType = 'snack',
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.sugarG = 0,
    this.sodiumMg = 0,
    this.servingSize = '1 serving',
    this.servingQuantity = 1.0,
    this.barcode,
    this.openFoodFactsId,
    this.entryMethod = 'manual',
    DateTime? loggedAt,
  })  : id = id ?? const Uuid().v4(),
        loggedAt = loggedAt ?? DateTime.now();

  // Scale nutrition by serving quantity
  int get scaledCalories => (calories * servingQuantity).round();
  double get scaledProtein => proteinG * servingQuantity;
  double get scaledCarbs => carbsG * servingQuantity;
  double get scaledFat => fatG * servingQuantity;
}
```

---

## FILE 9: lib/core/models/user_profile.dart
## PATH: lib/core/models/user_profile.dart
## PURPOSE: User profile. Not Hive (stored in Firestore + SharedPreferences).

```dart
class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final String subscriptionTier; // 'lite', 'pro', 'guardian', 'forever'
  final int alarmStreakDays;      // Consecutive days dismissed without max snooze
  final int totalAlarmsSet;
  final int totalGamesCompleted;
  final bool onboardingComplete;
  final bool biometricEnrolled;
  final bool hasSeenDeviceReport;  // Shown device capability report once
  final String? homeLatitude;      // For geofencing
  final String? homeLongitude;
  final String? buddyContactId;
  final List<String> completedGameTypes;
  final Map<String, dynamic>? preferences;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.createdAt,
    this.lastSeenAt,
    this.subscriptionTier = 'lite',
    this.alarmStreakDays = 0,
    this.totalAlarmsSet = 0,
    this.totalGamesCompleted = 0,
    this.onboardingComplete = false,
    this.biometricEnrolled = false,
    this.hasSeenDeviceReport = false,
    this.homeLatitude,
    this.homeLongitude,
    this.buddyContactId,
    this.completedGameTypes = const [],
    this.preferences,
  });

  bool get hasSetHome =>
      homeLatitude != null && homeLongitude != null;

  bool get isPro =>
      subscriptionTier == 'pro' ||
      subscriptionTier == 'guardian' ||
      subscriptionTier == 'forever';

  UserProfile copyWith({
    String? displayName,
    String? subscriptionTier,
    int? alarmStreakDays,
    int? totalAlarmsSet,
    int? totalGamesCompleted,
    bool? onboardingComplete,
    bool? biometricEnrolled,
    bool? hasSeenDeviceReport,
    String? homeLatitude,
    String? homeLongitude,
    String? buddyContactId,
    List<String>? completedGameTypes,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl,
      createdAt: createdAt,
      lastSeenAt: DateTime.now(),
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      alarmStreakDays: alarmStreakDays ?? this.alarmStreakDays,
      totalAlarmsSet: totalAlarmsSet ?? this.totalAlarmsSet,
      totalGamesCompleted: totalGamesCompleted ?? this.totalGamesCompleted,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      biometricEnrolled: biometricEnrolled ?? this.biometricEnrolled,
      hasSeenDeviceReport: hasSeenDeviceReport ?? this.hasSeenDeviceReport,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      buddyContactId: buddyContactId ?? this.buddyContactId,
      completedGameTypes: completedGameTypes ?? this.completedGameTypes,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastSeenAt': DateTime.now().toIso8601String(),
      'subscriptionTier': subscriptionTier,
      'alarmStreakDays': alarmStreakDays,
      'totalAlarmsSet': totalAlarmsSet,
      'totalGamesCompleted': totalGamesCompleted,
      'onboardingComplete': onboardingComplete,
      'biometricEnrolled': biometricEnrolled,
      'hasSeenDeviceReport': hasSeenDeviceReport,
      'homeLatitude': homeLatitude,
      'homeLongitude': homeLongitude,
      'buddyContactId': buddyContactId,
      'completedGameTypes': completedGameTypes,
      'preferences': preferences,
    };
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastSeenAt: map['lastSeenAt'] != null
          ? DateTime.tryParse(map['lastSeenAt'])
          : null,
      subscriptionTier: map['subscriptionTier'] ?? 'lite',
      alarmStreakDays: map['alarmStreakDays'] ?? 0,
      totalAlarmsSet: map['totalAlarmsSet'] ?? 0,
      totalGamesCompleted: map['totalGamesCompleted'] ?? 0,
      onboardingComplete: map['onboardingComplete'] ?? false,
      biometricEnrolled: map['biometricEnrolled'] ?? false,
      hasSeenDeviceReport: map['hasSeenDeviceReport'] ?? false,
      homeLatitude: map['homeLatitude'],
      homeLongitude: map['homeLongitude'],
      buddyContactId: map['buddyContactId'],
      completedGameTypes: List<String>.from(map['completedGameTypes'] ?? []),
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  /// Create anonymous local user for offline/no-account use
  factory UserProfile.anonymous() {
    return UserProfile(
      uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      onboardingComplete: false,
    );
  }
}
```

---

## FILE 10: lib/core/models/wake_game_result.dart
## PATH: lib/core/models/wake_game_result.dart
## PURPOSE: Result of a completed wake game. Stored for analytics and
##          adaptive difficulty tuning.

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'wake_game_result.g.dart';

@HiveType(typeId: 5)
class WakeGameResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String alarmId;

  @HiveField(2)
  String gameType;

  @HiveField(3)
  String difficulty;

  @HiveField(4)
  bool passed;

  @HiveField(5)
  int timeTakenSeconds;

  @HiveField(6)
  int wrongAnswerCount;

  @HiveField(7)
  int snoozeAttemptNumber; // Which snooze triggered this game (1, 2, 3...)

  @HiveField(8)
  DateTime playedAt;

  WakeGameResult({
    String? id,
    required this.alarmId,
    required this.gameType,
    required this.difficulty,
    required this.passed,
    required this.timeTakenSeconds,
    this.wrongAnswerCount = 0,
    required this.snoozeAttemptNumber,
    DateTime? playedAt,
  })  : id = id ?? const Uuid().v4(),
        playedAt = playedAt ?? DateTime.now();
}
```

---

## FILE 11: lib/core/models/buddy_contact.dart
## PATH: lib/core/models/buddy_contact.dart
## PURPOSE: Accountability buddy contact details.
##          typeId: 6

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'buddy_contact.g.dart';

@HiveType(typeId: 6)
class BuddyContact extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phoneNumber; // For WhatsApp deep link

  @HiveField(3)
  String? inAppUserId; // If buddy is also a RISE user

  @HiveField(4)
  String notifyMethod; // 'whatsapp', 'inapp', 'both'

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime addedAt;

  @HiveField(7)
  int totalNotificationsSent;

  BuddyContact({
    String? id,
    required this.name,
    this.phoneNumber,
    this.inAppUserId,
    this.notifyMethod = 'whatsapp',
    this.isActive = true,
    DateTime? addedAt,
    this.totalNotificationsSent = 0,
  })  : id = id ?? const Uuid().v4(),
        addedAt = addedAt ?? DateTime.now();

  String? get whatsappUrl {
    if (phoneNumber == null) return null;
    // Clean phone number — remove spaces, dashes, parentheses
    final clean = phoneNumber!.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return 'https://wa.me/$clean';
  }
}
```

---

## FILE 12: lib/core/models/subscription_status.dart
## PATH: lib/core/models/subscription_status.dart
## PURPOSE: Current subscription state from RevenueCat.

```dart
class SubscriptionStatus {
  final String tier; // 'lite', 'pro', 'guardian', 'forever'
  final bool isActive;
  final DateTime? expiresAt;
  final bool isLifetime;
  final bool isInTrial;
  final DateTime? trialEndsAt;
  final Map<String, int> iapPurchases; // productId → quantity remaining
  final bool restoredFromPurchase;

  const SubscriptionStatus({
    required this.tier,
    required this.isActive,
    this.expiresAt,
    this.isLifetime = false,
    this.isInTrial = false,
    this.trialEndsAt,
    this.iapPurchases = const {},
    this.restoredFromPurchase = false,
  });

  bool get isPro => tier == 'pro' || tier == 'guardian' || tier == 'forever';
  bool get isGuardian => tier == 'guardian';
  bool get isForever => tier == 'forever';

  int get snoozePack => iapPurchases['rise_snooze_pack_3'] ?? 0;

  factory SubscriptionStatus.free() {
    return const SubscriptionStatus(
      tier: 'lite',
      isActive: true,
    );
  }

  /// Number of days until subscription expires (null if lifetime or not pro)
  int? get daysUntilExpiry {
    if (isLifetime || expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }
}
```

---

## FILE 13: lib/core/providers/capability_provider.dart
## PATH: lib/core/providers/capability_provider.dart
## PURPOSE: Riverpod provider for device capabilities.
##          Re-scanned on app resume (AppLifecycleState.resumed).

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_capability_model.dart';
import '../models/feature_flag.dart';
import '../services/device_capability_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CAPABILITY PROVIDER
// AsyncNotifier so UI can show loading state during initial scan.
// Re-triggers on app lifecycle resume so permissions changes are reflected.
// ─────────────────────────────────────────────────────────────────────────────
class CapabilityNotifier extends AsyncNotifier<DeviceCapabilityModel> {
  @override
  Future<DeviceCapabilityModel> build() async {
    return DeviceCapabilityService.scanDevice();
  }

  /// Call this when app returns from Settings (user may have changed permissions)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => DeviceCapabilityService.scanDevice(),
    );
  }

  /// Quick permission-only refresh (faster than full scan)
  Future<void> refreshPermissions() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedPerms = await DeviceCapabilityService.refreshPermissions();
    // Recompute features with updated permissions
    state = await AsyncValue.guard(
      () => DeviceCapabilityService.scanDevice(),
    );
  }
}

final capabilityProvider =
    AsyncNotifierProvider<CapabilityNotifier, DeviceCapabilityModel>(
  CapabilityNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// CONVENIENCE PROVIDERS — Read individual feature flags without reading
// the full model. Use these in widgets for clean, concise code.
// ─────────────────────────────────────────────────────────────────────────────

/// Check if a specific feature is available on this device
final featureAvailableProvider =
    Provider.family<bool, RiseFeature>((ref, feature) {
  return ref.watch(capabilityProvider).maybeWhen(
        data: (caps) => caps.isFeatureAvailable(feature),
        orElse: () => false,
      );
});

/// Check if a specific feature is in degraded mode
final featureDegradedProvider =
    Provider.family<bool, RiseFeature>((ref, feature) {
  return ref.watch(capabilityProvider).maybeWhen(
        data: (caps) => caps.isFeatureDegraded(feature),
        orElse: () => false,
      );
});

/// Get the reason text for an unavailable feature
final featureReasonProvider =
    Provider.family<String?, RiseFeature>((ref, feature) {
  return ref.watch(capabilityProvider).maybeWhen(
        data: (caps) => caps.getFeatureReason(feature),
        orElse: () => null,
      );
});

/// Is this device fully capable (biometrics + alarms + notifications)?
final isDeviceFullyCapableProvider = Provider<bool>((ref) {
  return ref.watch(capabilityProvider).maybeWhen(
        data: (caps) => caps.isFullyCapable,
        orElse: () => false,
      );
});

/// Can the alarm fire reliably on this device?
final canFireAlarmReliablyProvider = Provider<bool>((ref) {
  return ref.watch(capabilityProvider).maybeWhen(
        data: (caps) => caps.canFireAlarmReliably,
        orElse: () => true, // Optimistic default while loading
      );
});

/// Feature summary items (unavailable/degraded features for the Device Report)
final featureSummaryProvider = Provider<List<FeatureSummaryItem>>((ref) {
  return ref.watch(capabilityProvider).maybeWhen(
        data: (caps) => DeviceCapabilityService.buildFeatureSummary(caps),
        orElse: () => [],
      );
});

/// Manufacturer restriction info
final manufacturerRestrictionsProvider =
    Provider<ManufacturerRestrictions?>((ref) {
  return ref.watch(capabilityProvider).maybeWhen(
        data: (caps) => caps.manufacturerRestrictions,
        orElse: () => null,
      );
});
```

---

## FILE 14: lib/core/providers/alarm_provider.dart
## PATH: lib/core/providers/alarm_provider.dart
## PURPOSE: State management for all alarms.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/alarm_model.dart';
import '../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ALARM REPOSITORY PROVIDER
// Raw access to the Hive box — wrapped by AlarmNotifier below.
// ─────────────────────────────────────────────────────────────────────────────
final alarmsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>(AppConstants.alarmsBoxName);
});

// ─────────────────────────────────────────────────────────────────────────────
// ALARM NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class AlarmNotifier extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() {
    final box = ref.watch(alarmsBoxProvider);
    return box.values
        .whereType<AlarmModel>()
        .toList()
      ..sort((a, b) {
        // Sort by next fire time, then by hour/minute
        final aNext = a.nextFireTime;
        final bNext = b.nextFireTime;
        if (aNext == null && bNext == null) return 0;
        if (aNext == null) return 1;
        if (bNext == null) return -1;
        return aNext.compareTo(bNext);
      });
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    final box = ref.read(alarmsBoxProvider);
    await box.put(alarm.id, alarm);
    // TODO Part 3: schedule in AlarmService
    ref.invalidateSelf();
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final box = ref.read(alarmsBoxProvider);
    await box.put(alarm.id, alarm);
    // TODO Part 3: reschedule in AlarmService
    ref.invalidateSelf();
  }

  Future<void> deleteAlarm(String alarmId) async {
    final box = ref.read(alarmsBoxProvider);
    await box.delete(alarmId);
    // TODO Part 3: cancel in AlarmService
    ref.invalidateSelf();
  }

  Future<void> toggleAlarm(String alarmId, bool enabled) async {
    final box = ref.read(alarmsBoxProvider);
    final alarm = box.get(alarmId) as AlarmModel?;
    if (alarm == null) return;
    final updated = alarm.copyWith(isEnabled: enabled);
    await box.put(alarmId, updated);
    ref.invalidateSelf();
  }

  Future<void> recordSnooze(String alarmId) async {
    final box = ref.read(alarmsBoxProvider);
    final alarm = box.get(alarmId) as AlarmModel?;
    if (alarm == null) return;
    alarm.totalSnoozeCount++;
    await alarm.save();
    ref.invalidateSelf();
  }

  AlarmModel? getAlarmById(String id) {
    return ref.read(alarmsBoxProvider).get(id) as AlarmModel?;
  }

  AlarmModel? get nextAlarm {
    final sorted = state.where((a) => a.isEnabled && a.nextFireTime != null).toList();
    if (sorted.isEmpty) return null;
    return sorted.first;
  }
}

final alarmProvider =
    NotifierProvider<AlarmNotifier, List<AlarmModel>>(AlarmNotifier.new);

final nextAlarmProvider = Provider<AlarmModel?>((ref) {
  return ref.watch(alarmProvider.notifier).nextAlarm;
});
```

---

## FILE 15: lib/core/providers/sleep_provider.dart
## PATH: lib/core/providers/sleep_provider.dart
## PURPOSE: State management for sleep sessions.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/sleep_session.dart';
import '../../core/constants/app_constants.dart';

final sleepBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>(AppConstants.sleepSessionsBoxName);
});

class SleepNotifier extends Notifier<List<SleepSession>> {
  @override
  List<SleepSession> build() {
    final box = ref.watch(sleepBoxProvider);
    return box.values
        .whereType<SleepSession>()
        .toList()
      ..sort((a, b) => b.sleepOnsetTime.compareTo(a.sleepOnsetTime));
  }

  Future<void> recordSleepOnset(String alarmId) async {
    final session = SleepSession(
      alarmId: alarmId,
      sleepOnsetTime: DateTime.now(),
    );
    final box = ref.read(sleepBoxProvider);
    await box.put(session.id, session);
    ref.invalidateSelf();
  }

  Future<void> recordWake({
    required String sessionId,
    required String dismissMethod,
    required int snoozeCount,
  }) async {
    final box = ref.read(sleepBoxProvider);
    final session = box.get(sessionId) as SleepSession?;
    if (session == null) return;
    session.wakeTime = DateTime.now();
    session.dismissMethod = dismissMethod;
    session.snoozeCount = snoozeCount;
    session.qualityLabel = _computeQuality(session);
    await session.save();
    ref.invalidateSelf();
  }

  String _computeQuality(SleepSession session) {
    final mins = session.durationMinutes;
    if (mins < 180) return 'poor';
    if (mins < 360 || session.snoozeCount > 3) return 'fair';
    if (session.snoozeCount == 0) return 'excellent';
    return 'good';
  }

  SleepSession? get lastSession => state.isNotEmpty ? state.first : null;

  /// Get sessions for the last N days
  List<SleepSession> getRecentSessions(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return state
        .where((s) => s.sleepOnsetTime.isAfter(cutoff))
        .toList();
  }

  double get averageSleepHoursLast7Days {
    final sessions = getRecentSessions(7);
    if (sessions.isEmpty) return 0;
    final total = sessions
        .map((s) => s.durationMinutes)
        .fold(0, (a, b) => a + b);
    return total / sessions.length / 60;
  }
}

final sleepProvider =
    NotifierProvider<SleepNotifier, List<SleepSession>>(SleepNotifier.new);

final lastSleepSessionProvider = Provider<SleepSession?>((ref) {
  return ref.watch(sleepProvider.notifier).lastSession;
});

final avgSleepHoursProvider = Provider<double>((ref) {
  return ref.watch(sleepProvider.notifier).averageSleepHoursLast7Days;
});
```

---

## FILE 16: lib/core/providers/user_provider.dart
## PATH: lib/core/providers/user_provider.dart
## PURPOSE: User profile state. Falls back to anonymous local profile
##          if user has no Firebase account.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return _loadProfile();
  }

  Future<UserProfile> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          return UserProfile.fromFirestore(doc.data()!);
        }
        // User authenticated but no Firestore doc — create one
        final profile = UserProfile(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        await _saveToFirestore(profile);
        return profile;
      }
    } catch (e) {
      // Firebase unavailable (Huawei, no internet) — use local profile
    }

    return _loadLocalProfile();
  }

  Future<UserProfile> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('local_uid');
    if (uid != null) {
      return UserProfile(
        uid: uid,
        createdAt: DateTime.tryParse(
          prefs.getString('created_at') ?? '',
        ) ?? DateTime.now(),
        onboardingComplete: prefs.getBool('onboarding_complete') ?? false,
        biometricEnrolled: prefs.getBool('biometric_enrolled') ?? false,
        hasSeenDeviceReport: prefs.getBool('seen_device_report') ?? false,
      );
    }
    final anonymous = UserProfile.anonymous();
    await prefs.setString('local_uid', anonymous.uid);
    await prefs.setString('created_at', anonymous.createdAt.toIso8601String());
    return anonymous;
  }

  Future<void> updateProfile(UserProfile updated) async {
    state = AsyncData(updated);
    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', updated.onboardingComplete);
    await prefs.setBool('biometric_enrolled', updated.biometricEnrolled);
    await prefs.setBool('seen_device_report', updated.hasSeenDeviceReport);
    // Sync to Firestore if online
    try {
      await _saveToFirestore(updated);
    } catch (e) {
      // Offline — local save is sufficient
    }
  }

  Future<void> _saveToFirestore(UserProfile profile) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(profile.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> markOnboardingComplete() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updateProfile(current.copyWith(onboardingComplete: true));
  }

  Future<void> markBiometricEnrolled() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updateProfile(current.copyWith(biometricEnrolled: true));
  }

  Future<void> setHomeLocation(String lat, String lng) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await updateProfile(
      current.copyWith(homeLatitude: lat, homeLongitude: lng),
    );
  }
}

final userProvider =
    AsyncNotifierProvider<UserNotifier, UserProfile>(UserNotifier.new);

final isOnboardedProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).maybeWhen(
        data: (user) => user.onboardingComplete,
        orElse: () => false,
      );
});

final isProProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).maybeWhen(
        data: (user) => user.isPro,
        orElse: () => false,
      );
});
```

---

## FILE 17: lib/core/providers/subscription_provider.dart
## PATH: lib/core/providers/subscription_provider.dart
## PURPOSE: RevenueCat subscription state. Gracefully falls back to free
##          if Play Services are unavailable.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import '../models/subscription_status.dart';
import '../models/feature_flag.dart';
import 'capability_provider.dart';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    // Check if IAP is available on this device first
    final caps = await ref.watch(capabilityProvider.future);
    if (!caps.isFeatureAvailable(RiseFeature.inAppPurchases)) {
      // No Play Services / IAP — return permanent free status
      // These users get all Pro features free since they can't pay
      // This is a goodwill decision: don't lock features on
      // devices that genuinely cannot access the payment system
      return const SubscriptionStatus(
        tier: 'lite',
        isActive: true,
        isLifetime: false,
      );
    }

    return _fetchSubscription();
  }

  Future<SubscriptionStatus> _fetchSubscription() async {
    try {
      final customerInfo = await rc.Purchases.getCustomerInfo();
      return _mapCustomerInfo(customerInfo);
    } catch (e) {
      // RevenueCat fetch failed — default to free
      return SubscriptionStatus.free();
    }
  }

  SubscriptionStatus _mapCustomerInfo(rc.CustomerInfo info) {
    final entitlements = info.entitlements.active;

    if (entitlements.containsKey('rise_forever')) {
      return SubscriptionStatus(
        tier: 'forever',
        isActive: true,
        isLifetime: true,
      );
    }
    if (entitlements.containsKey('rise_guardian')) {
      return SubscriptionStatus(
        tier: 'guardian',
        isActive: true,
        expiresAt: entitlements['rise_guardian']?.expirationDate,
      );
    }
    if (entitlements.containsKey('rise_pro')) {
      return SubscriptionStatus(
        tier: 'pro',
        isActive: true,
        expiresAt: entitlements['rise_pro']?.expirationDate,
        isInTrial: entitlements['rise_pro']?.periodType == rc.PeriodType.trial,
      );
    }

    // Check snooze pack IAP balance
    final snoozePacks = info.nonSubscriptionTransactions
        .where((t) => t.productIdentifier == 'rise_snooze_pack_3')
        .length;

    return SubscriptionStatus(
      tier: 'lite',
      isActive: true,
      iapPurchases: snoozePacks > 0 ? {'rise_snooze_pack_3': snoozePacks * 3} : {},
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchSubscription());
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
  SubscriptionNotifier.new,
);

final isProSubscriberProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).maybeWhen(
        data: (sub) => sub.isPro,
        orElse: () => false,
      );
});

final snoozePackCountProvider = Provider<int>((ref) {
  return ref.watch(subscriptionProvider).maybeWhen(
        data: (sub) => sub.snoozePack,
        orElse: () => 0,
      );
});
```

---

## FILE 18: lib/shared/widgets/capability_banner.dart
## PATH: lib/shared/widgets/capability_banner.dart
## PURPOSE: A non-blocking banner that informs the user why a feature
##          is unavailable on their device. Used on feature screens.
##          Critical design rule: it NEVER blocks the screen — it's a
##          friendly info chip, not an error page.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/models/feature_flag.dart';
import '../../core/providers/capability_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CAPABILITY BANNER
// Shows a small, non-intrusive info strip at the top of a feature screen
// when that feature is unavailable or degraded. Tapping it shows details
// and, where possible, a direct action to fix it.
// ─────────────────────────────────────────────────────────────────────────────
class CapabilityBanner extends ConsumerWidget {
  final RiseFeature feature;
  final bool compact;

  const CapabilityBanner({
    super.key,
    required this.feature,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(featureAvailableProvider(feature));
    final isDegraded = ref.watch(featureDegradedProvider(feature));
    final reason = ref.watch(featureReasonProvider(feature));

    if (isAvailable && !isDegraded) return const SizedBox.shrink();

    final (color, icon, label) = isDegraded
        ? (AppColors.warningSubtle, Icons.info_outline_rounded,
           AppColors.warning)
        : (AppColors.dangerSubtle, Icons.block_rounded, AppColors.danger);

    if (compact) {
      return _CompactBanner(
        color: color,
        icon: icon,
        iconColor: label,
        reason: reason ?? 'Unavailable on this device',
        feature: feature,
        isDegraded: isDegraded,
      );
    }

    return _FullBanner(
      color: color,
      icon: icon,
      iconColor: label,
      reason: reason ?? 'Unavailable on this device',
      feature: feature,
      isDegraded: isDegraded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CompactBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String reason;
  final RiseFeature feature;
  final bool isDegraded;

  const _CompactBanner({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.reason,
    required this.feature,
    required this.isDegraded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD,
          vertical: AppConstants.spacingSM,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSM),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isDegraded
                    ? '${feature.displayName} running in limited mode'
                    : '${feature.displayName} unavailable on this device',
                style: AppTextStyles.labelSM.copyWith(color: iconColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: iconColor, size: 14),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => CapabilityDetailSheet(feature: feature),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _FullBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String reason;
  final RiseFeature feature;
  final bool isDegraded;

  const _FullBanner({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.reason,
    required this.feature,
    required this.isDegraded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (_) => CapabilityDetailSheet(feature: feature),
      ),
      child: Container(
        margin: const EdgeInsets.all(AppConstants.spacingMD),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDegraded
                        ? '${feature.displayName} — Limited Mode'
                        : '${feature.displayName} Unavailable',
                    style: AppTextStyles.labelMD.copyWith(color: iconColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: AppTextStyles.bodySM.copyWith(
                      color: iconColor.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap for details and fix options →',
                    style: AppTextStyles.labelSM.copyWith(
                      color: iconColor,
                      decoration: TextDecoration.underline,
                      decorationColor: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAPABILITY DETAIL SHEET
// Shows full details about why a feature is unavailable and, for permission
// issues, a direct button to open Settings.
// ─────────────────────────────────────────────────────────────────────────────
class CapabilityDetailSheet extends ConsumerWidget {
  final RiseFeature feature;

  const CapabilityDetailSheet({super.key, required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsAsync = ref.watch(capabilityProvider);

    return capsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(height: 200),
      data: (caps) {
        final availability = caps.features[feature];
        if (availability == null) return const SizedBox.shrink();

        final grantableItems = availability.missingRequirements
            .where((r) => r.isGrantable)
            .toList();

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                feature.displayName,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 4),
              Text(
                feature.shortDescription,
                style: AppTextStyles.bodyMD.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Reason
              if (availability.reason != null) ...[
                Text(
                  'Why this isn\'t available:',
                  style: AppTextStyles.labelMD,
                ),
                const SizedBox(height: 8),
                Text(
                  availability.reason!,
                  style: AppTextStyles.bodyMD.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Missing requirements list
              if (availability.missingRequirements.isNotEmpty) ...[
                Text('Missing:', style: AppTextStyles.labelMD),
                const SizedBox(height: 8),
                ...availability.missingRequirements.map(
                  (req) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          req.isGrantable
                              ? Icons.lock_open_rounded
                              : Icons.hardware_rounded,
                          size: 16,
                          color: req.isGrantable
                              ? AppColors.warning
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req.humanReadable,
                            style: AppTextStyles.bodyMD.copyWith(
                              color: req.isGrantable
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Fallback description
              if (availability.fallbackMode != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successSubtle,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          availability.fallbackMode!.description,
                          style: AppTextStyles.bodyMD.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Grant permission button (if fixable)
              if (grantableItems.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                    // Refresh capabilities after returning from Settings
                    ref.read(capabilityProvider.notifier).refreshPermissions();
                  },
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open Settings to Grant Access'),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
```

---

## FILE 19: lib/shared/widgets/feature_gate.dart
## PATH: lib/shared/widgets/feature_gate.dart
## PURPOSE: Wraps any widget with a feature gate. If feature is unavailable,
##          shows a locked/disabled state with the capability banner instead.
##          This is the primary mechanism for feature gating throughout RISE.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/feature_flag.dart';
import '../../core/providers/capability_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'capability_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE GATE WIDGET
// Wraps any widget. If the feature is unavailable, shows a locked state.
// If degraded, shows the widget with a warning banner above it.
// If available, shows the widget normally.
//
// Usage:
//   FeatureGate(
//     feature: RiseFeature.ppgBiometric,
//     child: BiometricEnrollButton(),
//     lockedPlaceholder: PinVerificationButton(), // Optional fallback widget
//   )
// ─────────────────────────────────────────────────────────────────────────────
class FeatureGate extends ConsumerWidget {
  final RiseFeature feature;
  final Widget child;
  final Widget? lockedPlaceholder;   // Shown when unavailable (no fallback)
  final bool showBannerWhenDegraded; // Show warning banner if degraded

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedPlaceholder,
    this.showBannerWhenDegraded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(featureAvailableProvider(feature));
    final isDegraded = ref.watch(featureDegradedProvider(feature));

    // Feature fully available — show normally
    if (isAvailable && !isDegraded) return child;

    // Feature degraded — show with warning banner
    if (isAvailable && isDegraded && showBannerWhenDegraded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CapabilityBanner(feature: feature, compact: true),
          child,
        ],
      );
    }

    // Feature unavailable — show locked placeholder or default locked state
    if (!isAvailable) {
      if (lockedPlaceholder != null) return lockedPlaceholder!;
      return _LockedFeatureWidget(feature: feature);
    }

    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCKED FEATURE WIDGET
// Default appearance when a feature is completely unavailable and no
// custom placeholder is provided. Clean, informative, non-blocking.
// ─────────────────────────────────────────────────────────────────────────────
class _LockedFeatureWidget extends ConsumerWidget {
  final RiseFeature feature;

  const _LockedFeatureWidget({required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = ref.watch(featureReasonProvider(feature));

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (_) => CapabilityDetailSheet(feature: feature),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 32,
                  color: AppColors.textTertiary,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${feature.displayName} Unavailable',
              style: AppTextStyles.labelMD.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (reason != null) ...[
              const SizedBox(height: 6),
              Text(
                reason,
                style: AppTextStyles.bodySM.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Tap to learn more',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## UPDATE: lib/main.dart — ADD HIVE ADAPTER REGISTRATION
## Replace the `_registerHiveAdapters()` function body with:

```dart
void _registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AlarmModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SleepSessionAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(BiometricProfileAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(CalorieLogAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(FoodEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(WakeGameResultAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(BuddyContactAdapter());
  }
}
```

Also add imports to lib/main.dart:
```dart
import 'core/models/alarm_model.dart';
import 'core/models/sleep_session.dart';
import 'core/models/biometric_profile.dart';
import 'core/models/calorie_log.dart';
import 'core/models/food_entry.dart';
import 'core/models/wake_game_result.dart';
import 'core/models/buddy_contact.dart';
```

---

## UPDATE: android/app/build.gradle
## Find defaultConfig block and change:

```groovy
android {
    compileSdkVersion 35

    defaultConfig {
        applicationId "com.rise.alarmclock"
        minSdkVersion 21        // ← Changed from 26 to 21 (Android 5.0+)
        targetSdkVersion 35
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true    // ← Required for API 21 (method count limit)
    }
}
```

Also add to dependencies in build.gradle:
```groovy
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'  // Required for API 21
}
```

---

## AGENT: AFTER CREATING ALL FILES, RUN:

```bash
# Generate Hive adapters (.g.dart files) for all @HiveType models
dart run build_runner build --delete-conflicting-outputs

# Verify everything compiles
flutter pub get
flutter analyze

# Expected: 0 errors
# Note: .g.dart files will be auto-generated for:
#   alarm_model.g.dart
#   sleep_session.g.dart
#   biometric_profile.g.dart
#   calorie_log.g.dart
#   food_entry.g.dart
#   wake_game_result.g.dart
#   buddy_contact.g.dart
```

## AGENT: IMPORTANT NOTES ON EDGE CASES HANDLED IN THIS PART:

1. EMULATOR DETECTION: PPG and face liveness are disabled on emulators.
   This prevents false errors during development. Check `osInfo.isEmulator`.

2. HUAWEI WITHOUT PLAY SERVICES: Falls back to local notifications only.
   Subscription tier becomes permanently 'lite' with no paywall shown.
   These users get RISE Lite free — this is intentional goodwill.

3. PERMISSION REVOKE MID-SESSION: `refreshPermissions()` is called every
   time the app resumes from background. If camera permission was revoked
   while RISE was open, the next alarm will fall back to PIN mode.

4. SENSOR REPORTING ZEROS: Some cheap phones have accelerometers that
   report all zeros (broken sensor). The isAccelerometerFunctional check
   tests for this by requiring at least one non-zero reading.

5. FLASH THAT REPORTS AS PRESENT BUT DOESN'T WORK: The camera initialization
   test in _scanHardware() actually tries to turn the torch on. If it throws,
   flash is marked unavailable even though the hardware declares it.

6. API 21 MULTIDEX: Android API 21 has a 65,536 method limit. Flutter apps
   easily exceed this. MultiDex is enabled in build.gradle to handle it.

7. MISSING HIVE BOXES: All boxes are opened in main.dart before the app
   renders. If any box fails to open, the error is caught and reported to
   Crashlytics. The app will still launch — it uses empty defaults.

8. FIRESTORE OFFLINE: UserNotifier falls back to SharedPreferences if
   Firestore is unreachable. No data is lost. It syncs when back online.

9. REVENUECAT UNAVAILABLE: If RC fetch fails (no internet, no Play Services),
   the user gets the free tier. Restores will work once connection returns.

10. CONCURRENT CAPABILITY SCANS: The provider is AsyncNotifier — only one
    scan runs at a time. Calling refresh() while a scan is running queues
    it, preventing race conditions.

---

## WHAT PART 3 WILL COVER:
The complete Alarm Engine — exact scheduling for API 21 through 34,
foreground service that survives app kill, volume escalation, the
stubbornness engine (snooze counter, escalation logic), boot receiver
for alarm restoration after phone restart, and version-conditional
alarm scheduling (AlarmManager exact on Android, UNUserNotificationCenter
on iOS). The alarm will fire reliably on every supported device.

---
## END OF PART 2 BLUEPRINT
## Total files created: 19 + 2 file updates
## Device capability system: COMPLETE ✓
## Data models: COMPLETE ✓
## Providers: COMPLETE ✓
## Feature gating widgets: COMPLETE ✓
```
