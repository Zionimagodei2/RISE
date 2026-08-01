import '../models/referral_record.dart';

class ReferralService {
  bool initialized = false;
  ReferralService();
  Future<void> initialize() async { initialized = true; }
  ReferralRecord createForUser(String userId) => ReferralRecord(code: 'RISE-${userId.hashCode.abs()}');
}
