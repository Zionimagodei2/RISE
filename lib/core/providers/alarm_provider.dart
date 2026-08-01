import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
final alarmStateProvider = StateProvider<AlarmState>((ref) => AlarmState.idle);
