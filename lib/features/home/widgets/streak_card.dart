import 'package:flutter/material.dart';
class StreakCard extends StatelessWidget { const StreakCard({required this.days, super.key}); final int days; @override Widget build(BuildContext context) => Card(child: ListTile(leading: const Icon(Icons.local_fire_department), title: Text('$days day streak'), subtitle: const Text('Consecutive completed wake proofs'))); }
