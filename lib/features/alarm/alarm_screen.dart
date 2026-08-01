import 'package:flutter/material.dart';
import '../../core/services/alarm_service.dart';
import 'widgets/biometric_gate.dart';
import 'widgets/snooze_panel.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  bool biometricPassed = false;

  Future<void> _dismiss() async {
    if (!biometricPassed) return;
    await AlarmService.instance.dismiss();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wake sequence')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('RISE is firing', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          BiometricGate(passed: biometricPassed, onPassed: () => setState(() => biometricPassed = true)),
          const SizedBox(height: 16),
          SnoozePanel(onSnooze: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snooze requested')))),
          const Spacer(),
          FilledButton(onPressed: biometricPassed ? _dismiss : null, child: const Text('Dismiss alarm')),
        ]),
      ),
    );
  }
}
