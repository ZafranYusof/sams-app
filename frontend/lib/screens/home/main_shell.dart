import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'dashboard_screen.dart';
import '../registration/registration_screen.dart';
import '../attendance/attendance_screen.dart';
import '../curriculum/curriculum_screen.dart';
import '../fees/fees_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    RegistrationScreen(),
    AttendanceScreen(),
    CurriculumScreen(),
    FeesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: SAMsTheme.surface,
          border: Border(top: BorderSide(color: SAMsTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.app_registration_outlined), activeIcon: Icon(Icons.app_registration), label: 'Register'),
            BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), activeIcon: Icon(Icons.fact_check), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Activities'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: 'Fees'),
          ],
        ),
      ),
    );
  }
}
