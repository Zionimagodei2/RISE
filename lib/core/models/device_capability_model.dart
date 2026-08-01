class DeviceCapabilityModel {
  const DeviceCapabilityModel({
    required this.platform,
    required this.supportsExactAlarm,
    required this.supportsCriticalAlerts,
    required this.hasCamera,
    required this.hasAccelerometer,
    required this.hasMicrophone,
    required this.hasGooglePlayServices,
    this.manufacturer = 'unknown',
  });
  final String platform;
  final bool supportsExactAlarm;
  final bool supportsCriticalAlerts;
  final bool hasCamera;
  final bool hasAccelerometer;
  final bool hasMicrophone;
  final bool hasGooglePlayServices;
  final String manufacturer;

  bool get canRunCoreAlarm => supportsExactAlarm || supportsCriticalAlerts;
  bool get canRunBiometricWake => hasCamera;
  bool get canRunSleepDetection => hasAccelerometer || hasMicrophone;
}
