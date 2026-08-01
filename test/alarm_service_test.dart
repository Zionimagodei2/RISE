import 'package:flutter_test/flutter_test.dart';
import 'package:rise/core/services/alarm_service.dart';
import 'package:rise/core/services/audio_route_manager.dart';

void main() {
  test('wired audio is capped and mirrored to speaker', () {
    final decision = AudioRouteManager().decide(route: AudioRoute.wired, usesHearingAids: false);
    expect(decision.speakerForced, isTrue);
    expect(decision.earSafeCapPercent, 40);
  });

  test('alarm service moves to firing', () async {
    await AlarmService.instance.initialize();
    await AlarmService.instance.fire(route: AudioRoute.bluetooth);
    expect(AlarmService.instance.currentState, AlarmState.firing);
    expect(AlarmService.instance.lastAudioDecision?.speakerForced, isTrue);
  });
}
