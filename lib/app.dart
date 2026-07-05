import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/profile_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

class CalorieTrackerApp extends ConsumerWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kalori Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _RootGate(),
      routes: {
        '/home': (_) => const MainShell(),
      },
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
      data: (profile) {
        if (profile == null) return const OnboardingScreen();
        return const MainShell();
      },
    );
  }
}
