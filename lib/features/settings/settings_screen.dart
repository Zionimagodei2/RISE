import 'package:flutter/material.dart';
import 'sections/accessibility_settings.dart';
import 'sections/audio_settings.dart';
import 'sections/biometric_settings.dart';
import 'sections/notification_settings.dart';
import 'sections/lighting_settings.dart';
import 'sections/safety_settings.dart';
import 'sections/sleep_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RISE Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AccessibilitySettings(),
          AudioSettings(),
          SafetySettings(),
          NotificationSettings(),
          LightingSettings(),
          BiometricSettings(),
          SleepSettings(),
        ],
      ),
    );
  }
}
