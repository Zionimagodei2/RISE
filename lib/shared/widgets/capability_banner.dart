import 'package:flutter/material.dart';
class CapabilityBanner extends StatelessWidget { const CapabilityBanner({required this.message, super.key}); final String message; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(message))); }
