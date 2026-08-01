class DrivingContext {
  const DrivingContext({required this.isDriving, this.reason = 'not driving'});
  final bool isDriving;
  final String reason;
}

class DrivingDetector {
  bool initialized = false;
  DrivingDetector();
  Future<void> initialize() async { initialized = true; }

  DrivingContext detect({required double speedMetersPerSecond, String? bluetoothDeviceName}) {
    final name = (bluetoothDeviceName ?? '').toLowerCase();
    final carBluetooth = ['car', 'auto', 'honda', 'toyota', 'bmw', 'ford', 'vehicle'].any(name.contains);
    if (speedMetersPerSecond >= 8 || carBluetooth) return const DrivingContext(isDriving: true, reason: 'vehicle context detected');
    return const DrivingContext(isDriving: false);
  }
}
