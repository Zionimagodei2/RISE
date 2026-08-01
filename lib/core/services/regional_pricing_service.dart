import '../models/regional_pricing.dart';

class RegionalPricingService {
  bool initialized = false;
  RegionalPricingService();
  Future<void> initialize() async { initialized = true; }

  RegionalPricing priceFor(String regionCode) {
    final upper = regionCode.toUpperCase();
    if (upper == 'NG') return const RegionalPricing(regionCode: 'NG', currencyCode: 'NGN', monthlyPrice: 2500);
    if (upper == 'IN') return const RegionalPricing(regionCode: 'IN', currencyCode: 'INR', monthlyPrice: 299);
    return RegionalPricing(regionCode: upper, currencyCode: 'USD', monthlyPrice: 4.99);
  }
}
