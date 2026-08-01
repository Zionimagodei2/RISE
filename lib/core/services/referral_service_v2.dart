import '../models/referral_record.dart';

class ReferralServiceV2 {
  bool initialized = false;
  ReferralServiceV2();
  Future<void> initialize() async { initialized = true; }
  ReferralRecord awardInvite(ReferralRecord record) => ReferralRecord(code: record.code, successfulInvites: record.successfulInvites + 1);
}
