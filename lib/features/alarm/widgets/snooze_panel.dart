import 'package:flutter/material.dart';
class SnoozePanel extends StatelessWidget { const SnoozePanel({required this.onSnooze, super.key}); final VoidCallback onSnooze; @override Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onSnooze, icon: const Icon(Icons.snooze), label: const Text('Snooze with escalation rules')); }
