import 'package:flutter/material.dart';
class SleepScoreCard extends StatelessWidget { const SleepScoreCard({required this.score, super.key}); final int score; @override Widget build(BuildContext context) => Card(child: ListTile(leading: const Icon(Icons.nightlight), title: Text('Sleep score $score'), subtitle: const Text('Based on consistency, duration, and wake success'))); }
