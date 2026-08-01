import 'dart:io';

import '../models/device_capability_model.dart';

class DeviceCapabilityService {
  Future<DeviceCapabilityModel> inspect() async {
    return DeviceCapabilityModel(
      platform: Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'unsupported',
      supportsExactAlarm: Platform.isAndroid,
      supportsCriticalAlerts: Platform.isIOS,
      hasCamera: true,
      hasAccelerometer: true,
      hasMicrophone: true,
      hasGooglePlayServices: Platform.isAndroid,
      manufacturer: Platform.isAndroid ? 'android' : 'apple',
    );
  }
}
