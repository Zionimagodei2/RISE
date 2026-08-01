import '../models/onboarding_state.dart';

class OnboardingService {
  OnboardingState _state = const OnboardingState();
  OnboardingState get state => _state;
  Future<void> initialize() async => _state = const OnboardingState();
  void advance() => _state = _state.next();
  void complete() => _state = OnboardingState(step: _state.step, completed: true);
}
