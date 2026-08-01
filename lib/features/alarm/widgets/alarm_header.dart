import 'package:flutter/material.dart';
class AlarmHeader extends StatelessWidget { const AlarmHeader({super.key, this.title = 'Wake sequence active'}); final String title; @override Widget build(BuildContext context) => Card(child: ListTile(leading: const Icon(Icons.alarm_on), title: Text(title), subtitle: const Text('Speaker, haptics, and escalation safeguards are armed.'))); }
