import '../models/alarm_model.dart';

class AlarmScheduler {
  final Map<String, AlarmModel> _scheduled = {};

  Future<void> initialize() async => _scheduled.clear();

  Future<void> schedule(AlarmModel alarm) async {
    if (!alarm.enabled) return;
    _scheduled[alarm.id] = alarm;
  }

  Future<void> cancel(String alarmId) async => _scheduled.remove(alarmId);

  AlarmModel? nextAlarm(DateTime now) {
    final upcoming = _scheduled.values.where((alarm) => alarm.time.isAfter(now)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
