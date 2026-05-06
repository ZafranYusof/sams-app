import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class StudentAlertsTab extends StatelessWidget {
  const StudentAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {'icon': '✅', 'title': 'FPX Payment Confirmed', 'body': 'Your FPX payment of RM 4,650.00 has been confirmed. Reference: UMPSA-CB23109-20260409-8412', 'date': '09 Apr 2026', 'read': false},
      {'icon': '🎉', 'title': 'Full Payment Complete', 'body': 'Your tuition fees for Sem 2, 2025/2026 are fully settled. Academic access is secured.', 'date': '09 Apr 2026', 'read': false},
      {'icon': '⚠️', 'title': 'Payment Reminder', 'body': 'This is a reminder from the Treasury office. Your outstanding balance is RM 4650.00. Please settle before Week 5 (11 Apr 2026) to avoid academic access restriction.', 'date': '09 Apr 2026', 'read': false},
      {'icon': '✅', 'title': 'FPX Payment Confirmed', 'body': 'Your FPX payment of RM 200.00 has been confirmed. Reference: UMPSA-CB23109-20260409-3135', 'date': '09 Apr 2026', 'read': false},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${alerts.where((a) => a['read'] == false).length} unread', style: const TextStyle(color: SAMsTheme.textSecondary, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: SAMsTheme.border)),
                  child: const Text('Mark All Read', style: TextStyle(color: SAMsTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = alerts[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['icon'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(a['body'] as String, style: const TextStyle(fontSize: 12, color: SAMsTheme.textSecondary, height: 1.4)),
                        const SizedBox(height: 6),
                        Text(a['date'] as String, style: const TextStyle(fontSize: 11, color: SAMsTheme.textMuted)),
                      ])),
                      if (a['read'] == false)
                        Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: SAMsTheme.primary, shape: BoxShape.circle)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
