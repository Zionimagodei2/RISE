import '../../core/models/sleep_challenge.dart';
class SleepChallengeService { const SleepChallengeService(); List<SleepChallenge> activeChallenges() => const [SleepChallenge(id: 'consistent-5', title: 'Wake on time five days in a row', targetDays: 5), SleepChallenge(id: 'sleep-window', title: 'Keep a consistent sleep window', targetDays: 7)]; }
