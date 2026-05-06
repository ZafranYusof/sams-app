import 'package:flutter/material.dart';
import '../config/theme.dart';

class UpdateChecker {
  static const String currentVersion = '1.0.0';
  static const String latestVersion = '1.0.0'; // In production, fetch from API

  static bool get hasUpdate => currentVersion != latestVersion;

  static void checkAndShow(BuildContext context) {
    if (!hasUpdate) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: SAMsTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.system_update, color: SAMsTheme.primary),
          SizedBox(width: 10),
          Text('Update Available', style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Text(
          'A new version ($latestVersion) is available. Please update for the best experience.',
          style: const TextStyle(color: SAMsTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: SAMsTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
