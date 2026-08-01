import '../models/wake_confirmation.dart';

class WakeConfirmationService {
  final Map<String, WakeConfirmation> _confirmations = {};
  Future<void> initialize() async => _confirmations.clear();
  void confirm(WakeConfirmation confirmation) => _confirmations[confirmation.alarmId] = confirmation;
  bool isConfirmed(String alarmId) => _confirmations.containsKey(alarmId);
}
