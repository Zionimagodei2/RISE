enum AlarmState { idle, scheduled, firing, snoozed, dismissed, failedToFire }

class AlarmModel {
  const AlarmModel({required this.id, required this.time, this.enabled = true, this.label = 'Morning rise', this.volumePercent = 40});
  final String id;
  final DateTime time;
  final bool enabled;
  final String label;
  final int volumePercent;

  AlarmModel copyWith({DateTime? time, bool? enabled, String? label, int? volumePercent}) => AlarmModel(
        id: id,
        time: time ?? this.time,
        enabled: enabled ?? this.enabled,
        label: label ?? this.label,
        volumePercent: volumePercent ?? this.volumePercent,
      );
}
