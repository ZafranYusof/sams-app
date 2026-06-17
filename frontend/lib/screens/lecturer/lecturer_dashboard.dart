import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../../../widgets/pressable_card.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _headerAnim;
  late Animation<double> _sessionsAnim;
  late Animation<double> _actionsAnim;
  late Animation<double> _recentAnim;
  late Animation<double> _statsAnim;

  final ApiService _apiService = ApiService();

  bool _loading = true;
  bool _refreshing = false;
  String _userName = 'Dr. Ahmad';
  List<Map<String, dynamic>> _todaySessions = [];
  List<Map<String, dynamic>> _recentAttendance = [];
  int _totalSessionsWeek = 0;
  double _avgAttendanceRate = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _headerAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
      ),
    );

    _sessionsAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _actionsAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _recentAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _statsAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final sessionsResponse = await _apiService.get('/sessions');
      final List sessions = sessionsResponse['data'] ?? [];
      final today = DateTime.now();
      final todaySessions = sessions.where((s) {
        final date = DateTime.tryParse(s['date'] ?? '');
        return date != null &&
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      }).toList();

      List<Map<String, dynamic>> recentList = [];
      int totalWeek = 0;
      double avgRate = 0.0;

      try {
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        totalWeek = sessions.where((s) {
          final d = DateTime.tryParse(s['date'] ?? '');
          return d != null && d.isAfter(weekStart.subtract(const Duration(days: 1)));
        }).length;

        // Fetch recent attendance from last 5 sessions
        final recentSessions = sessions.take(5).toList();
        for (var s in recentSessions) {
          try {
            final att = await _apiService.get('/attendance/session/${s['id']}');
            final records = att['data'] ?? [];
            int present = 0, absent = 0, late = 0;
            for (var r in records) {
              final status = (r['status'] ?? '').toString().toLowerCase();
              if (status == 'present') present++;
              else if (status == 'late') late++;
              else absent++;
            }
            recentList.add({
              'course': s['courseName'] ?? s['course_code'] ?? 'N/A',
              'date': s['date'] ?? '',
              'present': present,
              'absent': absent,
              'late': late,
            });
          } catch (_) {}
        }

        if (recentList.isNotEmpty) {
          int totalP = 0, totalAll = 0;
          for (var r in recentList) {
            totalP += (r['present'] as int) + (r['late'] as int);
            totalAll += (r['present'] as int) + (r['absent'] as int) + (r['late'] as int);
          }
          avgRate = totalAll > 0 ? (totalP / totalAll * 100) : 0.0;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _todaySessions = todaySessions.cast<Map<String, dynamic>>();
          _recentAttendance = recentList;
          _totalSessionsWeek = totalWeek;
          _avgAttendanceRate = avgRate;
          _loading = false;
        });
        _animController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _todaySessions = [];
          _recentAttendance = [];
        });
        _animController.forward(from: 0);
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    HapticFeedback.mediumImpact();
    _animController.reset();
    await _loadData();
    setState(() => _refreshing = false);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Color _getSessionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return SAMsTheme.primary;
      case 'tutorial':
        return const Color(0xFF2196F3);
      case 'lab':
        return const Color(0xFF4CAF50);
      case 'seminar':
        return const Color(0xFFFF9800);
      default:
        return SAMsTheme.primary;
    }
  }

  IconData _getSessionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return Iconsax.teacher;
      case 'tutorial':
        return Iconsax.document_text;
      case 'lab':
        return Iconsax.monitor;
      case 'seminar':
        return Iconsax.people;
      default:
        return Iconsax.book;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SAMsTheme.background,
      body: SafeArea(
        child: Skeletonizer(
          enabled: _loading,
          child: PremiumRefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildTodaySessions()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildRecentAttendance()),
                SliverToBoxAdapter(child: _buildStatistics()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _headerAnim.value)),
          child: Opacity(
            opacity: _headerAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()},',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: SAMsTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userName,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              color: SAMsTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SAMsTheme.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
                          icon: const Icon(
                            Iconsax.notification,
                            color: SAMsTheme.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: SAMsTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySessions() {
    return AnimatedBuilder(
      animation: _sessionsAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _sessionsAnim.value)),
          child: Opacity(
            opacity: _sessionsAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Sessions",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: SAMsTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_todaySessions.isNotEmpty)
                        Text(
                          '${_todaySessions.length} class${_todaySessions.length > 1 ? 'es' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: SAMsTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_todaySessions.isEmpty && !_loading)
                    _buildEmptySessions()
                  else
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _loading ? 3 : _todaySessions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          if (_loading) return _buildSessionCardSkeleton();
                          final session = _todaySessions[index];
                          return _buildSessionCard(session);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySessions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.calendar_tick,
            size: 40,
            color: SAMsTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No sessions today',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: SAMsTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your free day!',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: SAMsTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCardSkeleton() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: SAMsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 160,
            height: 16,
            decoration: BoxDecoration(
              color: SAMsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: SAMsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: SAMsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final sessionType = (session['sessionType'] ?? session['type'] ?? 'lecture').toString();
    final accentColor = _getSessionTypeColor(sessionType);
    final icon = _getSessionTypeIcon(sessionType);
    final courseName = (session['courseName'] ?? session['course_name'] ?? 'Unknown Course').toString();
    final startTime = (session['startTime'] ?? session['start_time'] ?? '--:--').toString();
    final endTime = (session['endTime'] ?? session['end_time'] ?? '--:--').toString();
    final venue = (session['venue'] ?? session['room'] ?? 'TBA').toString();
    final status = (session['status'] ?? 'upcoming').toString();

    return PressableCard(
      onPressed: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SAMsTheme.surface,
          borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        sessionType[0].toUpperCase() + sessionType.substring(1),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'ongoing'
                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                        : SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: status.toLowerCase() == 'ongoing'
                          ? const Color(0xFF4CAF50)
                          : SAMsTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              courseName,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: SAMsTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.clock, size: 14, color: SAMsTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$startTime - $endTime',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SAMsTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Iconsax.location, size: 14, color: SAMsTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  venue,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SAMsTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Iconsax.scan_barcode, 'label': 'Generate Code', 'color': const Color(0xFF5C33CF)},
      {'icon': Iconsax.chart_21, 'label': 'View Attendance', 'color': const Color(0xFF2196F3)},
      {'icon': Iconsax.calendar, 'label': 'My Sessions', 'color': const Color(0xFF4CAF50)},
      {'icon': Iconsax.document_chart, 'label': 'Attendance Report', 'color': const Color(0xFFFF9800)},
    ];

    return AnimatedBuilder(
      animation: _actionsAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _actionsAnim.value)),
          child: Opacity(
            opacity: _actionsAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: SAMsTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return PressableCard(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Navigate based on action
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SAMsTheme.surface,
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 14,
                              cornerSmoothing: 0.6,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (action['color'] as Color).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  action['icon'] as IconData,
                                  color: action['color'] as Color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  action['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: SAMsTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentAttendance() {
    return AnimatedBuilder(
      animation: _recentAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _recentAnim.value)),
          child: Opacity(
            opacity: _recentAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Attendance',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: SAMsTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'See all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: SAMsTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_recentAttendance.isEmpty && !_loading)
                    _buildEmptyRecentAttendance()
                  else
                    ...List.generate(
                      _loading ? 3 : _recentAttendance.length,
                      (index) {
                        if (_loading) return _buildRecentAttendanceSkeleton();
                        return _buildRecentAttendanceItem(_recentAttendance[index]);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyRecentAttendance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.chart_21,
            size: 36,
            color: SAMsTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'No attendance records yet',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SAMsTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendanceSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SAMsTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 13,
                  decoration: BoxDecoration(
                    color: SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 11,
                  decoration: BoxDecoration(
                    color: SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendanceItem(Map<String, dynamic> record) {
    final course = record['course']?.toString() ?? 'N/A';
    final date = record['date']?.toString() ?? '';
    final present = record['present'] as int? ?? 0;
    final absent = record['absent'] as int? ?? 0;
    final late = record['late'] as int? ?? 0;
    final total = present + absent + late;

    String formattedDate = date;
    try {
      final d = DateTime.parse(date);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      formattedDate = '${d.day} ${months[d.month - 1]}';
    } catch (_) {}

    return PressableCard(
      onPressed: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SAMsTheme.surface,
          borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SAMsTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.document_text,
                color: SAMsTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: SAMsTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: SAMsTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildCountBadge('$present', const Color(0xFF4CAF50)),
                const SizedBox(width: 6),
                _buildCountBadge('$absent', const Color(0xFFF44336)),
                const SizedBox(width: 6),
                _buildCountBadge('$late', const Color(0xFFFF9800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return AnimatedBuilder(
      animation: _statsAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _statsAnim.value)),
          child: Opacity(
            opacity: _statsAnim.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: SAMsTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Iconsax.calendar_tick,
                          label: 'Total Sessions',
                          value: '$_totalSessionsWeek',
                          color: SAMsTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Iconsax.chart_21,
                          label: 'Avg Attendance',
                          value: '${_avgAttendanceRate.toStringAsFixed(1)}%',
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              color: SAMsTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: SAMsTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
