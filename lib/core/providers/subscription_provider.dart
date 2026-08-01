import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_status.dart';
final subscriptionProvider = StateProvider<SubscriptionStatus>((ref) => const SubscriptionStatus(plan: SubscriptionPlan.starter, active: true));
