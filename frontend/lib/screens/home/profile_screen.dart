import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _imagePath = prefs.getString('profile_image'));
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Change Profile Picture', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.camera_alt, color: SAMsTheme.primary, size: 20)),
            title: Text('Take Photo', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () { Navigator.pop(context); _getImage(ImageSource.camera); },
          ),
          ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: SAMsTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.photo_library, color: SAMsTheme.accent, size: 20)),
            title: Text('Choose from Gallery', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () { Navigator.pop(context); _getImage(ImageSource.gallery); },
          ),
          if (_imagePath != null)
            ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: SAMsTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete, color: SAMsTheme.error, size: 20)),
              title: const Text('Remove Photo', style: TextStyle(color: SAMsTheme.error)),
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('profile_image');
                setState(() => _imagePath = null);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', picked.path);
      setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Student';
    final email = user?['email'] ?? '';
    final studentId = user?['studentId'] ?? '';
    final faculty = user?['faculty'] ?? 'FKOM';
    final program = user?['program'] ?? 'Software Engineering';
    final role = user?['role'] ?? 'student';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar with camera button
          Center(child: Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _imagePath == null ? const LinearGradient(colors: [SAMsTheme.primary, SAMsTheme.primaryLight]) : null,
                  boxShadow: [BoxShadow(color: SAMsTheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  image: _imagePath != null ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover) : null,
                ),
                child: _imagePath == null ? Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700))) : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: SAMsTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: SAMsTheme.background, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          )),
          const SizedBox(height: 16),
          Center(child: Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w700))),
          const SizedBox(height: 4),
          Center(child: Text(email, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13))),
          const SizedBox(height: 6),
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(role.toUpperCase(), style: const TextStyle(color: SAMsTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 32),

          // Info cards
          Text('Personal Info', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _infoCard(Icons.badge_outlined, 'Student ID', studentId),
          _infoCard(Icons.business_outlined, 'Faculty', faculty),
          _infoCard(Icons.menu_book_outlined, 'Program', program),
          _infoCard(Icons.calendar_today_outlined, 'Semester', '2 (2025/2026)'),
          _infoCard(Icons.email_outlined, 'Email', email),

          const SizedBox(height: 32),
          Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _settingsItem(Icons.notifications_outlined, 'Notifications', () {}),
          _settingsItem(Icons.lock_outlined, 'Change Password', () {}),
          _settingsItem(Icons.language_outlined, 'Language', () {}),
          _settingsItem(Icons.info_outline, 'About SAMs', () {}),

          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: SAMsTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: SAMsTheme.primary, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
      ])),
    ]),
  );

  Widget _settingsItem(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
        Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
      ]),
    ),
  );
}
