import 'package:flutter_test/flutter_test.dart';
import 'package:rise/core/models/lighting_setup.dart';
import 'package:rise/core/services/light_wake_service.dart';

void main() {
  test('smart lights are triggered when room is dark', () {
    final decision = LightWakeService().evaluate(
      setup: const LightingSetup(mode: LightingControlMode.smartLight, smartLightName: 'Bedroom'),
      reading: LightSensorReading(lux: 10, capturedAt: DateTime(2026)),
    );
    expect(decision.shouldTriggerSmartLights, isTrue);
    expect(decision.requiresManualLightsOn, isFalse);
  });

  test('manual lighting requires user to turn lights on until lux threshold is met', () {
    final service = LightWakeService();
    final darkDecision = service.evaluate(
      setup: const LightingSetup(mode: LightingControlMode.manualVerification),
      reading: LightSensorReading(lux: 20, capturedAt: DateTime(2026)),
    );
    final brightDecision = service.evaluate(
      setup: const LightingSetup(mode: LightingControlMode.manualVerification),
      reading: LightSensorReading(lux: 180, capturedAt: DateTime(2026)),
    );
    expect(darkDecision.requiresManualLightsOn, isTrue);
    expect(brightDecision.isRoomBrightEnough, isTrue);
  });
}
