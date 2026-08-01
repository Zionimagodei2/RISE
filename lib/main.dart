import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/alarm_service.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService.instance.initialize();
  runApp(const ProviderScope(child: RiseApp()));
}

class RiseApp extends StatelessWidget {
  const RiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RISE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB000), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
