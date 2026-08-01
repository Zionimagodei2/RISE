class OfflineSyncService {
  final List<String> _queue = [];
  List<String> get pending => List.unmodifiable(_queue);
  Future<void> initialize() async => _queue.clear();
  void enqueue(String operationId) => _queue.add(operationId);
  Future<List<String>> flush() async { final flushed = List<String>.from(_queue); _queue.clear(); return flushed; }
}
