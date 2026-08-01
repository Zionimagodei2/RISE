import 'package:flutter/material.dart';
class FeatureGate extends StatelessWidget { const FeatureGate({required this.enabled, required this.child, required this.fallbackMessage, super.key}); final bool enabled; final Widget child; final String fallbackMessage; @override Widget build(BuildContext context) => enabled ? child : Center(child: Text(fallbackMessage)); }
