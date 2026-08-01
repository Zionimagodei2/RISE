import 'package:flutter/material.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String selectedTier = 'Starter';

  @override
  Widget build(BuildContext context) {
    final tiers = const [
      ('Starter', 'Free forever wake games, biometric lock, goals, habits, proof wall'),
      ('Core', 'Full sleep history, weekly AI review, sleep-nutrition insight'),
      ('Pro', 'Daily AI briefing, chronotype optimizer, smart home integrations'),
      ('Guardian', 'Child profiles, parent dashboard, guardian notifications'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('RISE Plans')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final tier in tiers)
            Card(
              child: RadioListTile<String>(
                value: tier.$1,
                groupValue: selectedTier,
                onChanged: (value) => setState(() => selectedTier = value ?? selectedTier),
                title: Text(tier.$1),
                subtitle: Text(tier.$2),
              ),
            ),
          FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$selectedTier selected'))), child: const Text('Continue')),
        ],
      ),
    );
  }
}
