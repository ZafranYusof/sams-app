import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/glass_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Student';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, $name', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Welcome to SAMs', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showProfileMenu(context, ref),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [SAMsTheme.primary, SAMsTheme.primaryLight]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Stats Grid
              Row(
                children: [
                  Expanded(child: StatCard(icon: Icons.menu_book, label: 'Courses', value: '5', color: SAMsTheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(icon: Icons.fact_check, label: 'Attendance', value: '87%', color: SAMsTheme.success)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: StatCard(icon: Icons.emoji_events, label: 'Activities', value: '3', color: SAMsTheme.accent)),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(icon: Icons.payments, label: 'Fees Due', value: 'RM 2,450', color: SAMsTheme.error)),
                ],
              ),
              const SizedBox(height: 28),
              // Quick Actions
              Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              GlassCard(
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.qr_code_scanner, color: SAMsTheme.primary, size: 20),
                  ),
                  title: const Text('Scan Attendance QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Check in to your class', style: TextStyle(color: SAMsTheme.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: SAMsTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: SAMsTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.payment, color: SAMsTheme.accent, size: 20),
                  ),
                  title: const Text('Pay Tuition Fees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Outstanding: RM 2,450', style: TextStyle(color: SAMsTheme.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: SAMsTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: SAMsTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_circle_outline, color: SAMsTheme.success, size: 20),
                  ),
                  title: const Text('Register Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Add/drop courses', style: TextStyle(color: SAMsTheme.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: SAMsTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SAMsTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline, color: SAMsTheme.textSecondary),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: SAMsTheme.error),
              title: const Text('Logout', style: TextStyle(color: SAMsTheme.error)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
