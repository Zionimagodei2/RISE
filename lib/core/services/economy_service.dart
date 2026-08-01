import '../models/reward_ledger.dart';

class EconomyService {
  int _points = 0;
  int get points => _points;
  Future<void> initialize() async => _points = 0;
  RewardLedger award(int points, {String reason = 'wake proof'}) { _points += points; return RewardLedger(points: _points, reason: reason); }
}
