import 'dart:async';

import '../models/alarm_model.dart';
import 'audio_route_manager.dart';

class AlarmService {
  AlarmService._();
  static final instance = AlarmService._();

  final _state = StreamController<AlarmState>.broadcast();
  AlarmState currentState = AlarmState.idle;
  Timer? _postFireEscalation;
  AudioRouteDecision? lastAudioDecision;

  Stream<AlarmState> get states => _state.stream;

  Future<void> initialize() async {
    currentState = AlarmState.idle;
    _state.add(currentState);
  }

  Future<void> schedule(AlarmModel alarm) async {
    currentState = AlarmState.scheduled;
    _state.add(currentState);
  }

  Future<void> fire({AudioRoute route = AudioRoute.unknown, bool usesHearingAids = false}) async {
    lastAudioDecision = AudioRouteManager().decide(route: route, usesHearingAids: usesHearingAids);
    currentState = AlarmState.firing;
    _state.add(currentState);
    _postFireEscalation?.cancel();
    _postFireEscalation = Timer(const Duration(minutes: 3), escalateForUnattendedAlarm);
  }

  void escalateForUnattendedAlarm() {
    // EC-2.4: if untouched for more than three minutes, jump to full-volume escalation and buddy chain.
  }

  Future<void> dismiss() async {
    _postFireEscalation?.cancel();
    currentState = AlarmState.dismissed;
    _state.add(currentState);
  }
}
