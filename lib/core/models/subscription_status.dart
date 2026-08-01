enum SubscriptionPlan { starter, core, pro, guardian, lifetime }
class SubscriptionStatus { const SubscriptionStatus({required this.plan, required this.active}); final SubscriptionPlan plan; final bool active; bool get hasInsights => active && plan != SubscriptionPlan.starter; }
