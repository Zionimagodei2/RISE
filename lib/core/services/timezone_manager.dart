class TimezoneManager {
  bool initialized = false;
  TimezoneManager();
  Future<void> initialize() async { initialized = true; }

  DateTime preserveWallClockTime({required DateTime oldLocalAlarm, required Duration timezoneDelta}) {
    return oldLocalAlarm.add(timezoneDelta);
  }

  bool crossesDstBoundary(DateTime before, DateTime after) => before.timeZoneOffset != after.timeZoneOffset;
}
