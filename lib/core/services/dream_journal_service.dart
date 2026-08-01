import '../models/dream_entry.dart';

class DreamJournalService {
  final List<DreamEntry> _entries = [];
  List<DreamEntry> get entries => List.unmodifiable(_entries);
  Future<void> initialize() async => _entries.clear();
  void add(DreamEntry entry) => _entries.add(entry);
}
