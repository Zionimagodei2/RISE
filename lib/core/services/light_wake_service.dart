import '../models/lighting_setup.dart';

class LightingWakeDecision {
  const LightingWakeDecision({
    required this.requiresManualLightsOn,
    required this.shouldTriggerSmartLights,
    required this.isRoomBrightEnough,
    required this.message,
  });

  final bool requiresManualLightsOn;
  final bool shouldTriggerSmartLights;
  final bool isRoomBrightEnough;
  final String message;
}

class LightWakeService {
  bool initialized = false;
  LightSensorReading? _lastReading;
  LightSensorReading? get lastReading => _lastReading;

  Future<void> initialize() async { initialized = true; }

  LightSensorReading recordLux(double lux, {DateTime? capturedAt}) {
    _lastReading = LightSensorReading(lux: lux, capturedAt: capturedAt ?? DateTime.now());
    return _lastReading!;
  }

  LightingWakeDecision evaluate({required LightingSetup setup, LightSensorReading? reading}) {
    final currentReading = reading ?? _lastReading;
    final isBright = currentReading?.isBrightEnoughForWake(setup.minimumWakeLux) ?? false;

    if (setup.canControlAutomatically) {
      return LightingWakeDecision(
        requiresManualLightsOn: false,
        shouldTriggerSmartLights: !isBright,
        isRoomBrightEnough: isBright,
        message: isBright ? 'Room is bright enough for wake reinforcement.' : 'Turning on smart lights to reinforce wakefulness.',
      );
    }

    if (!setup.canVerifyRoomIsBright) {
      return const LightingWakeDecision(
        requiresManualLightsOn: true,
        shouldTriggerSmartLights: false,
        isRoomBrightEnough: false,
        message: 'Turn on your room lights to continue; this device cannot verify brightness automatically.',
      );
    }

    return LightingWakeDecision(
      requiresManualLightsOn: !isBright,
      shouldTriggerSmartLights: false,
      isRoomBrightEnough: isBright,
      message: isBright ? 'Lights detected. Continue wake flow.' : 'Turn on lights. RISE will use the light sensor to verify the room is bright.',
    );
  }
}
