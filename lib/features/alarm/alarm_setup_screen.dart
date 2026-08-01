import 'package:flutter/material.dart';

class AlarmSetupScreen extends StatefulWidget {
  const AlarmSetupScreen({super.key});

  @override
  State<AlarmSetupScreen> createState() => _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends State<AlarmSetupScreen> {
  TimeOfDay alarmTime = const TimeOfDay(hour: 6, minute: 30);
  bool speakerOverride = true;
  bool buddyEscalation = true;
  bool wakeLighting = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set resilient alarm')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(leading: const Icon(Icons.schedule), title: Text(alarmTime.format(context)), subtitle: const Text('Tap to choose wake time'), onTap: () async { final picked = await showTimePicker(context: context, initialTime: alarmTime); if (picked != null) setState(() => alarmTime = picked); }),
        SwitchListTile(title: const Text('Force speaker for wireless audio'), subtitle: const Text('Protects against Bluetooth and cast routing failures.'), value: speakerOverride, onChanged: (value) => setState(() => speakerOverride = value)),
        SwitchListTile(title: const Text('Buddy escalation'), subtitle: const Text('Escalates if the alarm is not handled.'), value: buddyEscalation, onChanged: (value) => setState(() => buddyEscalation = value)),
        SwitchListTile(title: const Text('Wake lighting'), subtitle: const Text('Turns on smart lights or requires manual light verification before dismiss.'), value: wakeLighting, onChanged: (value) => setState(() => wakeLighting = value)),
        FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alarm configured for ${alarmTime.format(context)}'))), child: const Text('Save alarm')),
      ]),
    );
  }
}
