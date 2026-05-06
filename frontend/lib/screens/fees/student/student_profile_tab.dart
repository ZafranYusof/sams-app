import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';

class StudentProfileTab extends ConsumerWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [SAMsTheme.primary, SAMsTheme.primaryLight]), shape: BoxShape.circle),
            child: Center(child: Text((user?['name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700))),
          )),
          const SizedBox(height: 16),
          Center(child: Text(user?['name'] ?? 'Student', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
          Center(child: Text(user?['studentId'] ?? '', style: const TextStyle(color: SAMsTheme.textMuted, fontSize: 13))),
          Center(child: Text(user?['email'] ?? '', style: const TextStyle(color: SAMsTheme.textSecondary, fontSize: 12))),
          const SizedBox(height: 32),
          _profileItem(Icons.school_outlined, 'Faculty', user?['faculty'] ?? 'FKOM'),
          _profileItem(Icons.menu_book_outlined, 'Program', user?['program'] ?? 'Software Engineering'),
          _profileItem(Icons.calendar_today_outlined, 'Semester', '2'),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
            onPressed: () { ref.read(authProvider.notifier).logout(); Navigator.pop(context); },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: SAMsTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: SAMsTheme.border)),
    child: Row(children: [
      Icon(icon, color: SAMsTheme.primary, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: SAMsTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );
}
