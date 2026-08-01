enum AudioRoute { speaker, wired, bluetooth, hearingAid, cast, unknown }

class AudioRouteDecision {
  const AudioRouteDecision(this.route, this.message, {required this.speakerForced, required this.earSafeCapPercent});
  final AudioRoute route;
  final String message;
  final bool speakerForced;
  final int earSafeCapPercent;
}

class AudioRouteManager {
  AudioRouteDecision decide({required AudioRoute route, required bool usesHearingAids}) {
    if (usesHearingAids && route == AudioRoute.hearingAid) {
      return const AudioRouteDecision(AudioRoute.hearingAid, 'Hearing aids enabled — maximizing vibration and smart-light wake channels.', speakerForced: false, earSafeCapPercent: 100);
    }
    if (route == AudioRoute.wired) {
      return const AudioRouteDecision(AudioRoute.wired, 'Earphones detected — alarm playing on speaker too', speakerForced: true, earSafeCapPercent: 40);
    }
    if (route == AudioRoute.bluetooth || route == AudioRoute.cast) {
      return AudioRouteDecision(route, 'Wireless audio detected — alarm playing on phone speaker too', speakerForced: true, earSafeCapPercent: 100);
    }
    return const AudioRouteDecision(AudioRoute.speaker, 'Alarm playing on speaker', speakerForced: true, earSafeCapPercent: 100);
  }
}
