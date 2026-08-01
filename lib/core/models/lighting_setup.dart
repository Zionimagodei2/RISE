enum LightingControlMode { smartLight, manualVerification, unavailable }

class LightingSetup {
  const LightingSetup({
    required this.mode,
    this.smartLightName,
    this.lightSensorAvailable = true,
    this.minimumWakeLux = 120,
  });

  final LightingControlMode mode;
  final String? smartLightName;
  final bool lightSensorAvailable;
  final double minimumWakeLux;

  bool get canVerifyRoomIsBright => lightSensorAvailable && mode != LightingControlMode.unavailable;
  bool get canControlAutomatically => mode == LightingControlMode.smartLight && smartLightName != null;
}

class LightSensorReading {
  const LightSensorReading({required this.lux, required this.capturedAt});
  final double lux;
  final DateTime capturedAt;

  bool isBrightEnoughForWake(double minimumLux) => lux >= minimumLux;
}
