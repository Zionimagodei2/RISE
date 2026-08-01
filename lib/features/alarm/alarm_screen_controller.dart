import '../../core/models/alarm_model.dart';
import '../../core/services/alarm_service.dart';

class AlarmScreenController {
  AlarmState get state => AlarmService.instance.currentState;
  bool canDismiss({required bool wakeProofPassed}) => state == AlarmState.firing && wakeProofPassed;
  Future<void> dismissAfterProof() => AlarmService.instance.dismiss();
}
