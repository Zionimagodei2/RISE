class BatteryAdvisory {
  const BatteryAdvisory({required this.levelPercent, required this.message, required this.urgent});
  final int levelPercent;
  final String message;
  final bool urgent;
}

class BatteryMonitor {
  bool initialized = false;
  BatteryMonitor();
  Future<void> initialize() async { initialized = true; }

  BatteryAdvisory? advisoryFor({required int batteryPercent, required Duration untilAlarm}) {
    if (batteryPercent <= 5 && untilAlarm <= const Duration(hours: 4)) {
      return BatteryAdvisory(levelPercent: batteryPercent, message: 'Battery critically low. Plug in now so RISE can fire.', urgent: true);
    }
    if (batteryPercent <= 10) {
      return BatteryAdvisory(levelPercent: batteryPercent, message: 'Battery critical. Alarm may not fire.', urgent: true);
    }
    if (batteryPercent <= 20) {
      return BatteryAdvisory(levelPercent: batteryPercent, message: 'Battery at 20%. Plug in RISE to guarantee your alarm fires tonight.', urgent: false);
    }
    return null;
  }
}
