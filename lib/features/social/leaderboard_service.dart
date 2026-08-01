class LeaderboardEntry { const LeaderboardEntry({required this.name, required this.streakDays}); final String name; final int streakDays; }
class LeaderboardService { const LeaderboardService(); List<LeaderboardEntry> topEntries() => const [LeaderboardEntry(name: 'You', streakDays: 7), LeaderboardEntry(name: 'Ari', streakDays: 5), LeaderboardEntry(name: 'Sam', streakDays: 4)]; }
