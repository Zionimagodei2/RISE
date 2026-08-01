import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/alarm_service.dart';
final alarmServiceProvider = Provider<AlarmService>((ref) => AlarmService.instance);
