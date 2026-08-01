class BackgroundServiceManager {
  bool _running = false;
  bool get isRunning => _running;
  Future<void> initialize() async => _running = false;
  Future<void> start() async => _running = true;
  Future<void> stop() async => _running = false;
}
