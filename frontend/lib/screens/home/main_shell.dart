import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../fees/treasury/treasury_shell.dart';
import 'dashboard_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final role = user?['role'] ?? 'student';

    if (role == 'admin') return const TreasuryShell();
    return const DashboardScreen();
  }
}
