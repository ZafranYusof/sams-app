import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import '../lecturer/lecturer_dashboard.dart';
import '../registrar/registrar_dashboard.dart';
import '../pusat_adab/pusat_adab_dashboard.dart';
import '../student/student_home_dashboard.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final role = user?['role'] ?? 'student';

    switch (role) {
      case 'lecturer':
        return const LecturerDashboard();
      case 'faculty':
        return const RegistrarDashboard();
      case 'staff':
        return const PusatAdabDashboard();
      case 'admin':
        return const DashboardScreen(); // treasury uses existing dashboard
      case 'student':
      default:
        return const StudentHomeDashboard();
    }
  }
}
