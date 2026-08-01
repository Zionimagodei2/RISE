import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/light_wake_service.dart';

final lightWakeServiceProvider = Provider<LightWakeService>((ref) => LightWakeService());
