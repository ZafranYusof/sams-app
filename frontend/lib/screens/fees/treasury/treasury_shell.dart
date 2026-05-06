import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'treasury_dashboard_tab.dart';
import 'treasury_students_tab.dart';

class TreasuryShell extends StatefulWidget {
  const TreasuryShell({super.key});

  @override
  State<TreasuryShell> createState() => _TreasuryShellState();
}

class _TreasuryShellState extends State<TreasuryShell> {
  int _currentIndex = 0;

  final _screens = const [
    TreasuryDashboardTab(),
    TreasuryStudentsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: SAMsTheme.primary,
          unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Students'),
          ],
        ),
      ),
    );
  }
}
