import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sleep_session.dart';
final sleepSessionsProvider = StateProvider<List<SleepSession>>((ref) => const []);
