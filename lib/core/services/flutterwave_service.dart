class FlutterwaveService {
  bool initialized = false;
  FlutterwaveService();
  Future<void> initialize() async { initialized = true; }
  Uri checkoutUri({required String reference, required double amount, required String currency}) => Uri.https('checkout.flutterwave.com', '/pay/$reference', {'amount': amount.toStringAsFixed(2), 'currency': currency});
}
