import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../registration/registration_screen.dart';
import '../attendance/attendance_screen.dart';
import '../curriculum/curriculum_screen.dart';
import '../fees/fees_screen.dart';
import 'profile_screen.dart';
import '../../widgets/page_transitions.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _profileImage;
  List<dynamic> _announcements = [];
  Map<String, dynamic>? _feeSummary;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfileImage(), _loadAnnouncements(), _loadFeeSummary()]);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _profileImage = prefs.getString('profile_image'));
  }

  Future<void> _loadAnnouncements() async {
    try {
      final data = await ApiService.get('/announcements');
      if (data is List) setState(() => _announcements = data);
    } catch (_) {
      // No announcements endpoint yet, use empty
    }
  }

  Future<void> _loadFeeSummary() async {
    try {
      final user = ref.read(authProvider).user;
      final sid = user?['studentId'] ?? user?['student_id'] ?? '';
      if (sid.isNotEmpty) {
        final data = await ApiService.get('/fees/$sid/summary');
        setState(() => _feeSummary = data['summary']);
      }
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() => _loadingData = true);
    await _loadAll();
    // Force refresh auth state
    ref.read(authProvider.notifier).refreshProfile();
    setState(() => _loadingData = false);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?['name'] ?? 'Student';
    final lang = ref.watch(languageProvider).locale;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SAMsTheme.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003566), Color(0xFF0077B6), Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/umpsa_logo.png', width: 90, height: 90, fit: BoxFit.contain),
                            const SizedBox(height: 8),
                            const Text('\u0627\u0648\u0646\u064a\u06cf\u0631\u0633\u064a\u062a\u064a \u0645\u0644\u064a\u0633\u064a\u0627 \u06a4\u0647\u06a0 \u0627\u0644\u0633\u0644\u0637\u0627\u0646 \u0639\u0628\u062f \u0627\u0644\u0644\u0647', style: TextStyle(color: Colors.white, fontSize: 9), textAlign: TextAlign.center),
                            const Text('UNIVERSITI MALAYSIA PAHANG', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            const Text('AL-SULTAN ABDULLAH', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Container(width: 2.5, height: 120, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: const Color(0xFFD4A843), borderRadius: BorderRadius.circular(2))),
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () => _showProfileMenu(context, ref),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.2))),
                                child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 10),
                              const Text('SAMs', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              const Text('UMPSA', style: TextStyle(color: Color(0xFF48CAE4), fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── GREETING ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text('$_greeting, ${name.split(' ').first} 👋', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
              ),

              // ─── STUDENT INFO CARD (ADAB style) ───
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF00B4D8), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                        image: _profileImage != null ? DecorationImage(image: FileImage(File(_profileImage!)), fit: BoxFit.cover) : null,
                      ),
                      child: _profileImage == null ? Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF003566), fontSize: 26, fontWeight: FontWeight.w800))) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name.toUpperCase(), style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text((user?['program'] ?? 'Software Engineering').toUpperCase(), style: TextStyle(color: Colors.grey[700], fontSize: 11, height: 1.4)),
                      if (user?['faculty'] != null) Text(user!['faculty'].toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600)),
                    ])),
                  ],
                ),
              ),

              // ─── FEATURED CARDS (horizontal scroll) ───
              Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 10), child: Text(t('featured', lang), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FeaturedCard(
                      gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                      icon: Icons.payments_rounded,
                      title: 'Tuition Fees',
                      subtitle: 'Check balance & pay',
                      onTap: () => Navigator.push(context, SlidePageRoute(page: const FeesScreen())),
                    ),
                    _FeaturedCard(
                      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                      icon: Icons.fact_check_rounded,
                      title: 'Attendance',
                      subtitle: 'QR check-in',
                      onTap: () => Navigator.push(context, SlidePageRoute(page: const AttendanceScreen())),
                    ),
                    _FeaturedCard(
                      gradient: const [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
                      icon: Icons.emoji_events_rounded,
                      title: 'Activities',
                      subtitle: 'Join events & clubs',
                      onTap: () => Navigator.push(context, SlidePageRoute(page: const CurriculumScreen())),
                    ),
                    _FeaturedCard(
                      gradient: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                      icon: Icons.app_registration_rounded,
                      title: 'Registration',
                      subtitle: 'Add/drop courses',
                      onTap: () => Navigator.push(context, SlidePageRoute(page: const RegistrationScreen())),
                    ),
                  ],
                ),
              ),

              // ─── MODULES GRID ───
              Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12), child: Text(t('modules', lang), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16,
                  children: [
                    _GridItem(icon: Icons.app_registration_rounded, label: 'Registration', color: SAMsTheme.primary, onTap: () => Navigator.push(context, SlidePageRoute(page: const RegistrationScreen()))),
                    _GridItem(icon: Icons.fact_check_rounded, label: 'Attendance', color: SAMsTheme.success, onTap: () => Navigator.push(context, SlidePageRoute(page: const AttendanceScreen()))),
                    _GridItem(icon: Icons.emoji_events_rounded, label: 'Activities', color: SAMsTheme.accent, onTap: () => Navigator.push(context, SlidePageRoute(page: const CurriculumScreen()))),
                    _GridItem(icon: Icons.payments_rounded, label: 'Tuition Fees', color: SAMsTheme.error, onTap: () => Navigator.push(context, SlidePageRoute(page: const FeesScreen()))),
                  ],
                ),
              ),

              // ─── QUICK LINKS ───
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Text(t('quick_links', lang), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16,
                  children: [
                    _CircleItem(icon: Icons.fastfood_rounded, label: 'e-Kupon Kaseh', color: const Color(0xFFF59E0B), bgColor: const Color(0xFFFEF3C7), onTap: () {}),
                    _CircleItem(icon: Icons.emergency_rounded, label: 'Emergency', color: const Color(0xFFEF4444), bgColor: const Color(0xFFFEE2E2), onTap: () {}),
                    _CircleItem(icon: Icons.laptop_rounded, label: 'EDasar', color: const Color(0xFF3B82F6), bgColor: const Color(0xFFDBEAFE), onTap: () {}),
                    _CircleItem(icon: Icons.school_rounded, label: 'Alumni', color: const Color(0xFF6366F1), bgColor: const Color(0xFFE0E7FF), onTap: () {}),
                    _CircleItem(icon: Icons.directions_bus_rounded, label: 'Bus Schedules', color: const Color(0xFFEF4444), bgColor: const Color(0xFFFEE2E2), onTap: () {}),
                    _CircleItem(icon: Icons.quiz_rounded, label: 'FAQ', color: const Color(0xFF10B981), bgColor: const Color(0xFFD1FAE5), onTap: () {}),
                    _CircleItem(icon: Icons.wb_sunny_rounded, label: 'Weather', color: const Color(0xFFF59E0B), bgColor: const Color(0xFFFEF3C7), onTap: () {}),
                    _CircleItem(icon: Icons.location_on_rounded, label: 'UMPSA Map', color: const Color(0xFF0EA5E9), bgColor: const Color(0xFFE0F2FE), onTap: () {}),
                    _CircleItem(icon: Icons.calendar_month_rounded, label: 'Calendar', color: const Color(0xFFEC4899), bgColor: const Color(0xFFFCE7F3), onTap: () {}),
                    _CircleItem(icon: Icons.restaurant_rounded, label: 'Cafetaria', color: const Color(0xFF6366F1), bgColor: const Color(0xFFE0E7FF), onTap: () {}),
                    _CircleItem(icon: Icons.newspaper_rounded, label: 'News', color: const Color(0xFF3B82F6), bgColor: const Color(0xFFDBEAFE), onTap: () {}),
                    _CircleItem(icon: Icons.mosque_rounded, label: 'Prayer Time', color: const Color(0xFF10B981), bgColor: const Color(0xFFD1FAE5), onTap: () {}),
                  ],
                ),
              ),

              // ─── FEE SUMMARY BANNER ───
              GestureDetector(
                onTap: () => Navigator.push(context, SlidePageRoute(page: const FeesScreen())),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1A3A5F), Color(0xFF0D2847)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('TUITION FEES', style: TextStyle(color: Color(0xFF48CAE4), fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('RM ${((_feeSummary?['balance'] ?? 0) as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(_feeSummary != null && (_feeSummary!['balance'] as num) <= 0 ? '✅ Fully Paid' : 'Outstanding Balance', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      ])),
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: SAMsTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.payments_rounded, color: Color(0xFF48CAE4), size: 30),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── ANNOUNCEMENTS ───
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.campaign_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(t('announcements', lang), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('View all', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                  ]),
                  const SizedBox(height: 12),
                  if (_announcements.isEmpty) ...
                    [_announcementItem('No new announcements', '')]
                  else
                    ..._announcements.take(3).map((a) => _announcementItem(a['title'] ?? '', a['time'] ?? '')),
                ]),
              ),

              // ─── FACILITIES CHIPS ───
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 10), child: Text(t('facilities', lang), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['Residency', 'Sport Complex', 'Library', 'Health Centre', 'Lab', 'Dewan', 'Mosque'].map((f) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Text(f, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }

  static Widget _announcementItem(String text, String time) => Builder(
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12, height: 1.3)),
            const SizedBox(height: 2),
            Text(time, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
          ])),
        ]),
      );
    },
  );

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final isDark = ref.read(themeProvider).isDark;
        final lang = ref.read(languageProvider).locale;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () async { Navigator.pop(ctx); await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); _loadProfileImage(); },
            ),
            ListTile(
              leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
              onTap: () { Navigator.pop(ctx); ref.read(themeProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(lang == 'en' ? 'Bahasa Melayu' : 'English'),
              onTap: () { Navigator.pop(ctx); ref.read(languageProvider.notifier).toggle(); },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: SAMsTheme.error),
              title: const Text('Logout', style: TextStyle(color: SAMsTheme.error)),
              onTap: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); },
            ),
          ]),
        );
      },
    );
  }
}

// ─── FEATURED CARD with scale animation ───
class _FeaturedCard extends StatefulWidget {
  final List<Color> gradient;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _FeaturedCard({required this.gradient, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) { setState(() => _scale = 1.0); HapticFeedback.lightImpact(); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: widget.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: widget.gradient[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, color: Colors.white, size: 22),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(widget.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ]),
        ]),
      ),
      ),
    );
  }
}

// ─── GRID ITEM ───
class _GridItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GridItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_GridItem> createState() => _GridItemState();
}

class _GridItemState extends State<_GridItem> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) { setState(() => _scale = 1.0); HapticFeedback.selectionClick(); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(widget.icon, color: widget.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(widget.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 11, fontWeight: FontWeight.w500, height: 1.2)),
        ]),
      ),
    );
  }
}

// ─── CIRCLE ITEM ───
class _CircleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bgColor;
  final VoidCallback onTap;
  const _CircleItem({required this.icon, required this.label, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 10, fontWeight: FontWeight.w500, height: 1.2)),
      ]),
    );
  }
}
