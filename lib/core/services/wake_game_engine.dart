import '../models/wake_game_result.dart';

class WakeGameEngine {
  bool initialized = false;
  WakeGameEngine();
  Future<void> initialize() async { initialized = true; }

  WakeGameResult score({required String gameId, required bool passed}) {
    return WakeGameResult(gameId: gameId, passed: passed, completedAt: DateTime.now());
  }
}
