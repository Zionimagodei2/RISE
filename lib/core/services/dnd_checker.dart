class DndStatus {
  const DndStatus({required this.enabled, required this.canBypass, this.advisory});
  final bool enabled;
  final bool canBypass;
  final String? advisory;
}

class DndChecker {
  bool initialized = false;
  DndChecker();
  Future<void> initialize() async { initialized = true; }

  DndStatus evaluate({required bool enabled, required bool alarmBypassAllowed}) {
    if (!enabled) return const DndStatus(enabled: false, canBypass: true);
    return DndStatus(
      enabled: true,
      canBypass: alarmBypassAllowed,
      advisory: alarmBypassAllowed ? 'DND is on, but RISE can bypass for alarms.' : 'DND is on. Enable alarm bypass for RISE.',
    );
  }
}
