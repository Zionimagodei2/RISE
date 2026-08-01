import 'package:flutter/material.dart';
import 'steps/biometric_intro_step.dart';
import 'steps/faith_step.dart';
import 'steps/first_alarm_step.dart';
import 'steps/mode_select_step.dart';
import 'steps/permissions_step.dart';
import 'steps/profile_step.dart';
import 'steps/welcome_step.dart';

class OnboardingShell extends StatefulWidget { const OnboardingShell({super.key}); @override State<OnboardingShell> createState() => _OnboardingShellState(); }
class _OnboardingShellState extends State<OnboardingShell> { int step = 0; final steps = const [WelcomeStep(), ModeSelectStep(), PermissionsStep(), ProfileStep(), FaithStep(), BiometricIntroStep(), FirstAlarmStep()]; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('RISE Onboarding')), body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [LinearProgressIndicator(value: (step + 1) / steps.length), const SizedBox(height: 24), steps[step], const Spacer(), FilledButton(onPressed: () => setState(() => step = step == steps.length - 1 ? 0 : step + 1), child: Text(step == steps.length - 1 ? 'Restart walkthrough' : 'Next'))]))); }
