import '../models/subscription_status.dart';

class PaymentService {
  bool initialized = false;
  SubscriptionStatus _status = const SubscriptionStatus(plan: SubscriptionPlan.starter, active: true);
  SubscriptionStatus get status => _status;
  Future<void> initialize() async { initialized = true; }
  Future<SubscriptionStatus> activate(SubscriptionPlan plan) async => _status = SubscriptionStatus(plan: plan, active: true);
}
