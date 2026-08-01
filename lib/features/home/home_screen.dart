import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/models/alarm_model.dart';
import '../../core/services/alarm_service.dart';
import '../alarm/alarm_screen.dart';
import '../alarm/alarm_setup_screen.dart';
import '../onboarding/onboarding_shell.dart';
import '../paywall/paywall_screen.dart';
import '../settings/settings_screen.dart';
import '../social/leaderboard_screen.dart';
import '../social/referral_screen.dart';
import '../social/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime alarmTime = DateTime.now().add(const Duration(hours: 8));
  String status = 'Ready';

  Future<void> _schedule() async {
    await AlarmService.instance.schedule(AlarmModel(id: 'primary', time: alarmTime));
    setState(() => status = 'Alarm armed for ${TimeOfDay.fromDateTime(alarmTime).format(context)}');
  }

  Future<void> _testFire() async {
    await AlarmService.instance.fire();
    setState(() => status = 'Wake sequence firing');
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AlarmScreen()));
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final destinations = <({String title, String subtitle, IconData icon, Widget screen})>[
      (title: 'Onboarding', subtitle: 'Permissions, profile, first alarm', icon: Icons.flag, screen: const OnboardingShell()),
      (title: 'Alarm setup', subtitle: 'Configure resilient alarm behavior', icon: Icons.alarm_add, screen: const AlarmSetupScreen()),
      (title: 'Settings', subtitle: 'Accessibility, audio, safety, biometrics', icon: Icons.settings, screen: const SettingsScreen()),
      (title: 'Paywall', subtitle: 'Starter, Core, Pro, Guardian', icon: Icons.workspace_premium, screen: const PaywallScreen()),
      (title: 'Leaderboard', subtitle: 'Challenges and social proof', icon: Icons.leaderboard, screen: const LeaderboardScreen()),
      (title: 'Wallet', subtitle: 'Rewards and proof ledger', icon: Icons.account_balance_wallet, screen: const WalletScreen()),
      (title: 'Referrals', subtitle: 'Invite accountability buddies', icon: Icons.person_add, screen: const ReferralScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(AppStrings.tagline, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(status, style: Theme.of(context).textTheme.headlineSmall))),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _schedule, icon: const Icon(Icons.alarm), label: const Text('Set resilient alarm')),
          OutlinedButton.icon(onPressed: _testFire, icon: const Icon(Icons.play_arrow), label: const Text('Test wake sequence')),
          const SizedBox(height: 24),
          Text('Feature flows', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final destination in destinations)
            Card(
              child: ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.title),
                subtitle: Text(destination.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(destination.screen),
              ),
            ),
          const SizedBox(height: 24),
          const Text(AppStrings.keepNearby, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
