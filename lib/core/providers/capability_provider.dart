import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_capability_model.dart';
import '../services/device_capability_service.dart';
final capabilityProvider = FutureProvider<DeviceCapabilityModel>((ref) => DeviceCapabilityService().inspect());
