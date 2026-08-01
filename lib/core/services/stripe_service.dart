class StripeService {
  bool initialized = false;
  StripeService();
  Future<void> initialize() async { initialized = true; }
  String clientReference({required String userId, required String tierId}) => 'rise_${userId}_$tierId';
}
