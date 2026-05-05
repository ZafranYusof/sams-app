import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: SAMsApp()));
}

class SAMsApp extends ConsumerWidget {
  const SAMsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'SAMs',
      debugShowCheckedModeBanner: false,
      theme: SAMsTheme.darkTheme,
      home: authState.isAuthenticated ? const MainShell() : const LoginScreen(),
    );
  }
}
