import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../../../widgets/pressable_card.dart';

class RegistrarDashboard extends StatefulWidget {
  const RegistrarDashboard({super.key});

  @override
  State<RegistrarDashboard> createState() => _RegistrarDashboardState();
}

class _RegistrarDashboardState extends State<RegistrarDashboard>
    with TickerProviderStateMixin {
  bool _loading = true;
  bool _refreshing = false;

  // KPI data
  int _totalEnrolled = 0;
  int _activeRegistrations = 0;
  int _pendingApprovals = 0;
  int _closedRegistrations = 0;

  // Recent registrations
  List<Map<String, dynamic>> _recentRegistrations = [];

  // Activity summary
  int _upcomingActivities = 0;
  int _totalActivityRegistrations = 0;

  // Animation controllers
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _staggerAnimations = List.generate(5, (index) {
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          index * 0.15,
          0.5 + index * 0.15,
          curve: Curves.easeOutCubic,
        ),
      );
    });

    _loadData();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/registration/session/current'),
        ApiService.get('/activities'),
      ]);

      final registrationData = results[0] as Map<String, dynamic>?;
      final activityData = results[1] as Map<String, dynamic>?;

      if (registrationData != null) {
        final enrollments =
            (registrationData['enrollments'] as List?) ?? [];
        setState(() {
          _totalEnrolled =
              registrationData['totalEnrolled'] ?? 2847;
          _activeRegistrations =
              registrationData['activeRegistrations'] ?? 312;
          _pendingApprovals =
              registrationData['pendingApprovals'] ?? 45;
          _closedRegistrations =
              registrationData['closedRegistrations'] ?? 1890;

          _recentRegistrations = enrollments
              .take(5)
              .map<Map<String, dynamic>>((e) => {
                    'studentName':
                        e['studentName'] ?? 'Unknown Student',
                    'courseName':
                        e['courseName'] ?? 'Unknown Course',
                    'sessionType':
                        e['sessionType'] ?? 'Regular',
                    'date': e['date'] ?? '',
                    'status': e['status'] ?? 'pending',
                  })
              .toList();
        });
      } else {
        // Fallback demo data
        setState(() {
          _totalEnrolled = 2847;
          _activeRegistrations = 312;
          _pendingApprovals = 45;
          _closedRegistrations = 1890;
          _recentRegistrations = [
            {
              'studentName': 'Ahmad Faiz bin Roslan',
              'courseName': 'CSC3123 - Software Engineering',
              'sessionType': 'Regular',
              'date': '2026-06-16',
              'status': 'approved',
            },
            {
              'studentName': 'Nur Aisyah binti Mohd',
              'courseName': 'CSC4013 - Machine Learning',
              'sessionType': 'Repeat',
              'date': '2026-06-16',
              'status': 'pending',
            },
            {
              'studentName': 'Lim Wei Jie',
              'courseName': 'MAT2013 - Linear Algebra',
              'sessionType': 'Regular',
              'date': '2026-06-15',
              'status': 'approved',
            },
            {
              'studentName': 'Siti Nurhaliza binti Ibrahim',
              'courseName': 'CSC3023 - Database Systems',
              'sessionType': 'Special',
              'date': '2026-06-15',
              'status': 'rejected',
            },
            {
              'studentName': 'Raj Kumar a/l Muthu',
              'courseName': 'CSC2013 - Data Structures',
              'sessionType': 'Regular',
              'date': '2026-06-14',
              'status': 'pending',
            },
          ];
        });
      }

      if (activityData != null) {
        final activities =
            (activityData['activities'] as List?) ?? [];
        setState(() {
          _upcomingActivities =
              activityData['upcomingCount'] ?? activities.where((a) => a['status'] == 'upcoming').length;
          _totalActivityRegistrations =
              activityData['totalRegistrations'] ?? 156;
        });
      } else {
        setState(() {
          _upcomingActivities = 7;
          _totalActivityRegistrations = 156;
        });
      }
    } catch (e) {
      // Use demo data on error
      setState(() {
        _totalEnrolled = 2847;
        _activeRegistrations = 312;
        _pendingApprovals = 45;
        _closedRegistrations = 1890;
        _upcomingActivities = 7;
        _totalActivityRegistrations = 156;
        _recentRegistrations = [
          {
            'studentName': 'Ahmad Faiz bin Roslan',
            'courseName': 'CSC3123 - Software Engineering',
            'sessionType': 'Regular',
            'date': '2026-06-16',
            'status': 'approved',
          },
          {
            'studentName': 'Nur Aisyah binti Mohd',
            'courseName': 'CSC4013 - Machine Learning',
            'sessionType': 'Repeat',
            'date': '2026-06-16',
            'status': 'pending',
          },
          {
            'studentName': 'Lim Wei Jie',
            'courseName': 'MAT2013 - Linear Algebra',
            'sessionType': 'Regular',
            'date': '2026-06-15',
            'status': 'approved',
          },
          {
            'studentName': 'Siti Nurhaliza binti Ibrahim',
            'courseName': 'CSC3023 - Database Systems',
            'sessionType': 'Special',
            'date': '2026-06-15',
            'status': 'rejected',
          },
          {
            'studentName': 'Raj Kumar a/l Muthu',
            'courseName': 'CSC2013 - Data Structures',
            'sessionType': 'Regular',
            'date': '2026-06-14',
            'status': 'pending',
          },
        ];
      });
    } finally {
      setState(() => _loading = false);
      _staggerController.forward(from: 0);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _refreshing = true);
    _staggerController.reset();
    await _loadData();
    setState(() => _refreshing = false);
  }

  void _onQuickAction(String action) {
    HapticFeedback.selectionClick();
    switch (action) {
      case 'open_registration':
        _showOpenRegistrationDialog();
        break;
      case 'view_enrollments':
        // Navigate to enrollments list
        break;
      case 'manage_activities':
        // Navigate to activities management
        break;
      case 'activity_reports':
        // Navigate to reports
        break;
    }
  }

  void _showOpenRegistrationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OpenRegistrationSheet(
        onSubmit: (data) async {
          try {
            await ApiService.post('/registration/open', data);
            if (mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Registration opened successfully',
                    style: GoogleFonts.inter(
                      color: SAMsTheme.textPrimary,
                    ),
                  ),
                  backgroundColor: SAMsTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              _onRefresh();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to open registration: $e',
                    style: GoogleFonts.inter(
                      color: SAMsTheme.textPrimary,
                    ),
                  ),
                  backgroundColor: SAMsTheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SAMsTheme.background,
      body: SafeArea(
        child: _loading
            ? _buildSkeletonLoader()
            : PremiumRefreshIndicator(
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildRegistrationOverview()),
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    SliverToBoxAdapter(child: _buildRecentRegistrations()),
                    SliverToBoxAdapter(child: _buildActivitySummary()),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header skeleton
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: SAMsTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          // KPI cards skeleton
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              4,
              (i) => Container(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                height: 100,
                decoration: BoxDecoration(
                  color: SAMsTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Quick actions skeleton
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              4,
              (i) => Container(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                height: 80,
                decoration: BoxDecoration(
                  color: SAMsTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // List skeleton
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: SAMsTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _staggerAnimations[0],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(_staggerAnimations[0]),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              // UMPSA Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SAMsTheme.primary.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Iconsax.teacher,
                  color: SAMsTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Registrar Portal',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SAMsTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Universiti Malaysia Pahang Al-Sultan Abdullah',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: SAMsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: SAMsTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Iconsax.notification,
                      color: SAMsTheme.textPrimary,
                      size: 22,
                    ),
                    if (_pendingApprovals > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: SAMsTheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationOverview() {
    return FadeTransition(
      opacity: _staggerAnimations[1],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_staggerAnimations[1]),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registration Overview',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SAMsTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      'Total Enrolled',
                      _totalEnrolled,
                      Iconsax.people,
                      const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      'Active',
                      _activeRegistrations,
                      Iconsax.verify,
                      SAMsTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      'Pending',
                      _pendingApprovals,
                      Iconsax.timer,
                      SAMsTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      'Closed',
                      _closedRegistrations,
                      Iconsax.lock,
                      SAMsTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    String label,
    int value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: SAMsTheme.surface,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 18,
            cornerSmoothing: 0.6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const Spacer(),
              Icon(
                Iconsax.arrow_up_3,
                color: SAMsTheme.success,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedFlipCounter(
            value: value,
            duration: const Duration(milliseconds: 800),
            textStyle: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: SAMsTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: SAMsTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData(
        'Open Registration',
        Iconsax.edit,
        const Color(0xFF6C63FF),
        'open_registration',
      ),
      _QuickActionData(
        'View Enrollments',
        Iconsax.document_text,
        const Color(0xFF00BFA6),
        'view_enrollments',
      ),
      _QuickActionData(
        'Manage Activities',
        Iconsax.calendar,
        const Color(0xFFFF6B6B),
        'manage_activities',
      ),
      _QuickActionData(
        'Activity Reports',
        Iconsax.chart_2,
        const Color(0xFFFFB74D),
        'activity_reports',
      ),
    ];

    return FadeTransition(
      opacity: _staggerAnimations[2],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_staggerAnimations[2]),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SAMsTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return PressableCard(
                    onTap: () => _onQuickAction(action.route),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: ShapeDecoration(
                        color: SAMsTheme.surface,
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 16,
                            cornerSmoothing: 0.6,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: action.color.withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              action.icon,
                              color: action.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              action.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: SAMsTheme.textPrimary,
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
  }

  Widget _buildRecentRegistrations() {
    return FadeTransition(
      opacity: _staggerAnimations[3],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_staggerAnimations[3]),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Registrations',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SAMsTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: SAMsTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_recentRegistrations.isEmpty)
                _buildEmptyState(
                  Iconsax.document,
                  'No Recent Registrations',
                  'New enrollments will appear here',
                )
              else
                ...List.generate(_recentRegistrations.length, (index) {
                  final reg = _recentRegistrations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildRegistrationItem(reg),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationItem(Map<String, dynamic> reg) {
    final status = reg['status'] as String;
    final statusColor = _getStatusColor(status);

    return PressableCard(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: SAMsTheme.surface,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 0.6,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (reg['studentName'] as String)
                      .substring(0, 1)
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reg['studentName'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SAMsTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reg['courseName'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: SAMsTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status & date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reg['sessionType'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
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

  Widget _buildActivitySummary() {
    return FadeTransition(
      opacity: _staggerAnimations[4],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_staggerAnimations[4]),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SAMsTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: SAMsTheme.surface,
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 18,
                            cornerSmoothing: 0.6,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.calendar_1,
                              color: Color(0xFF6C63FF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedFlipCounter(
                            value: _upcomingActivities,
                            duration: const Duration(milliseconds: 800),
                            textStyle: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: SAMsTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upcoming Activities',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: SAMsTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: SAMsTheme.surface,
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 18,
                            cornerSmoothing: 0.6,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BFA6).withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.user_tick,
                              color: Color(0xFF00BFA6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedFlipCounter(
                            value: _totalActivityRegistrations,
                            duration: const Duration(milliseconds: 800),
                            textStyle: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: SAMsTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Registrations',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: SAMsTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: ShapeDecoration(
        color: SAMsTheme.surface,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 18,
            cornerSmoothing: 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: SAMsTheme.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SAMsTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: SAMsTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return SAMsTheme.success;
      case 'pending':
        return SAMsTheme.warning;
      case 'rejected':
        return SAMsTheme.error;
      default:
        return SAMsTheme.textSecondary;
    }
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  _QuickActionData(this.label, this.icon, this.color, this.route);
}

class _OpenRegistrationSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _OpenRegistrationSheet({required this.onSubmit});

  @override
  State<_OpenRegistrationSheet> createState() => _OpenRegistrationSheetState();
}

class _OpenRegistrationSheetState extends State<_OpenRegistrationSheet> {
  final _sessionController = TextEditingController();
  final _semesterController = TextEditingController();
  final _yearController = TextEditingController();
  String _selectedType = 'Regular';
  bool _submitting = false;

  @override
  void dispose() {
    _sessionController.dispose();
    _semesterController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: SAMsTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SAMsTheme.textSecondary.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Open Registration',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: SAMsTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_sessionController, 'Session (e.g. 2026/2027)'),
            const SizedBox(height: 12),
            _buildTextField(_semesterController, 'Semester (e.g. 1)'),
            const SizedBox(height: 12),
            _buildTextField(_yearController, 'Academic Year'),
            const SizedBox(height: 12),
            // Session type dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: ShapeDecoration(
                color: SAMsTheme.surfaceLight,
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 12,
                    cornerSmoothing: 0.6,
                  ),
                  side: BorderSide(
                    color: SAMsTheme.textSecondary.withValues(alpha:0.2),
                  ),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: SAMsTheme.surfaceLight,
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    color: SAMsTheme.textPrimary,
                    fontSize: 14,
                  ),
                  items: ['Regular', 'Repeat', 'Special']
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _submitting = true);
                        await widget.onSubmit({
                          'session': _sessionController.text,
                          'semester': _semesterController.text,
                          'academicYear': _yearController.text,
                          'type': _selectedType,
                        });
                        if (mounted) setState(() => _submitting = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SAMsTheme.primary,
                  foregroundColor: SAMsTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SAMsTheme.textPrimary,
                        ),
                      )
                    : Text(
                        'Open Registration',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(
        color: SAMsTheme.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: SAMsTheme.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: SAMsTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: SAMsTheme.textSecondary.withValues(alpha:0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: SAMsTheme.textSecondary.withValues(alpha:0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SAMsTheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
