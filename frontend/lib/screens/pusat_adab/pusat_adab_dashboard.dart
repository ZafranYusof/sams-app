import 'dart:async';
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

class PusatAdabDashboard extends StatefulWidget {
  const PusatAdabDashboard({super.key});

  @override
  State<PusatAdabDashboard> createState() => _PusatAdabDashboardState();
}

class _PusatAdabDashboardState extends State<PusatAdabDashboard>
    with TickerProviderStateMixin {
  bool _loading = true;
  bool _refreshing = false;

  List<Map<String, dynamic>> _pendingClaims = [];
  List<Map<String, dynamic>> _recentDecisions = [];
  List<Map<String, dynamic>> _activities = [];

  int _pendingCount = 0;
  int _approvedTodayCount = 0;
  int _rejectedCount = 0;

  late AnimationController _staggerController;
  final List<Animation<double>> _staggerAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    for (int i = 0; i < 5; i++) {
      _staggerAnimations.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            i * 0.15,
            0.4 + i * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    }
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
        ApiService.get('/activities/claims/pending'),
        ApiService.get('/activities'),
      ]);

      final pendingData = results[0];
      final activitiesData = results[1];

      if (pendingData is List) {
        final allClaims =
            pendingData.map((e) => Map<String, dynamic>.from(e)).toList();

        _pendingClaims =
            allClaims.where((c) => c['status'] == 'pending').toList();

        _recentDecisions = allClaims
            .where((c) => c['status'] == 'approved' || c['status'] == 'rejected')
            .toList()
          ..sort((a, b) {
            final aDate = DateTime.tryParse(a['reviewedAt'] ?? '') ??
                DateTime.tryParse(a['submittedAt'] ?? '') ??
                DateTime(0);
            final bDate = DateTime.tryParse(b['reviewedAt'] ?? '') ??
                DateTime.tryParse(b['submittedAt'] ?? '') ??
                DateTime(0);
            return bDate.compareTo(aDate);
          });
        if (_recentDecisions.length > 5) {
          _recentDecisions = _recentDecisions.sublist(0, 5);
        }

        _pendingCount = _pendingClaims.length;

        final today = DateTime.now();
        _approvedTodayCount = allClaims.where((c) {
          if (c['status'] != 'approved') return false;
          final reviewed = DateTime.tryParse(c['reviewedAt'] ?? '');
          if (reviewed == null) return false;
          return reviewed.year == today.year &&
              reviewed.month == today.month &&
              reviewed.day == today.day;
        }).length;

        _rejectedCount =
            allClaims.where((c) => c['status'] == 'rejected').length;
      }

      if (activitiesData is List) {
        _activities =
            activitiesData.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _loading = false);
      _staggerController.forward(from: 0);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    HapticFeedback.lightImpact();
    await _loadData();
    setState(() => _refreshing = false);
  }

  Future<void> _reviewClaim(String claimId, String action) async {
    HapticFeedback.mediumImpact();
    try {
      final response = await ApiService.put(
        '/activities/claim/$claimId/review', {'status': action},
      );
      if (response != null) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'approved'
                    ? 'Claim approved successfully'
                    : 'Claim rejected',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor:
                  action == 'approved' ? const Color(0xFF22C55E) : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error reviewing claim: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${action == 'approved' ? 'approve' : 'reject'} claim',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF22C55E);
      case 'rejected':
        return Colors.red;
      default:
        return SAMsTheme.textSecondary;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SAMsTheme.background,
      body: SafeArea(
        child: PremiumRefreshIndicator(
          onRefresh: _onRefresh,
          child: Skeletonizer(
            enabled: _loading,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildKpiCards()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildPendingClaimsSection()),
                SliverToBoxAdapter(child: _buildRecentDecisionsSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _staggerAnimations[0],
      builder: (context, child) {
        return Opacity(
          opacity: _staggerAnimations[0].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _staggerAnimations[0].value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SAMsTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.book_1_copy,
                    color: SAMsTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Adab Portal',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SAMsTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Credit Claim Management',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: SAMsTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SAMsTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.notification_bing_copy,
                    color: SAMsTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards() {
    final kpis = [
      _KpiData(
        label: 'Pending Claims',
        value: _pendingCount.toString(),
        icon: Iconsax.clock_copy,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFF59E0B).withOpacity(0.12),
      ),
      _KpiData(
        label: 'Approved Today',
        value: _approvedTodayCount.toString(),
        icon: Iconsax.tick_circle_copy,
        color: const Color(0xFF22C55E),
        bgColor: const Color(0xFF22C55E).withOpacity(0.12),
      ),
      _KpiData(
        label: 'Rejected',
        value: _rejectedCount.toString(),
        icon: Iconsax.close_circle_copy,
        color: Colors.red,
        bgColor: Colors.red.withOpacity(0.12),
      ),
    ];

    return AnimatedBuilder(
      animation: _staggerAnimations[1],
      builder: (context, child) {
        return Opacity(
          opacity: _staggerAnimations[1].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _staggerAnimations[1].value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: kpis.map((kpi) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: kpi == kpis.first ? 0 : 6,
                  right: kpi == kpis.last ? 0 : 6,
                ),
                child: PressableCard(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: SAMsTheme.surface,
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 16,
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
                            color: kpi.bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(kpi.icon, color: kpi.color, size: 18),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          kpi.value,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: SAMsTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kpi.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: SAMsTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData(
        label: 'Review Claims',
        icon: Iconsax.document_copy,
        color: SAMsTheme.primary,
        onTap: () {
          HapticFeedback.lightImpact();
          // Navigate to review claims
        },
      ),
      _QuickActionData(
        label: 'View Activities',
        icon: Iconsax.activity_copy,
        color: const Color(0xFF06B6D4),
        onTap: () {
          HapticFeedback.lightImpact();
          // Navigate to activities
        },
      ),
      _QuickActionData(
        label: 'Claim Reports',
        icon: Iconsax.chart_2_copy,
        color: const Color(0xFFF97316),
        onTap: () {
          HapticFeedback.lightImpact();
          // Navigate to reports
        },
      ),
    ];

    return AnimatedBuilder(
      animation: _staggerAnimations[2],
      builder: (context, child) {
        return Opacity(
          opacity: _staggerAnimations[2].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _staggerAnimations[2].value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            const SizedBox(height: 12),
            Row(
              children: actions.map((action) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: action == actions.first ? 0 : 6,
                      right: action == actions.last ? 0 : 6,
                    ),
                    child: PressableCard(
                      onTap: action.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color: SAMsTheme.surface,
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 14,
                              cornerSmoothing: 0.6,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: action.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                action.icon,
                                color: action.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              action.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: SAMsTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingClaimsSection() {
    return AnimatedBuilder(
      animation: _staggerAnimations[3],
      builder: (context, child) {
        return Opacity(
          opacity: _staggerAnimations[3].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _staggerAnimations[3].value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Claims',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SAMsTheme.textPrimary,
                  ),
                ),
                if (_pendingClaims.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pendingClaims.length} pending',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pendingClaims.isEmpty && !_loading)
              _buildEmptyState(
                icon: Iconsax.document_text_copy,
                message: 'No pending claims to review',
              )
            else
              ...List.generate(
                _loading ? 3 : _pendingClaims.length,
                (index) => _buildPendingClaimCard(
                  _loading
                      ? {
                          'studentName': 'Loading...',
                          'activityName': 'Loading...',
                          'submittedAt': '2025-01-01',
                          'supportingDoc': '',
                          '_id': 'skeleton_$index',
                        }
                      : _pendingClaims[index],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingClaimCard(Map<String, dynamic> claim) {
    final studentName = claim['studentName'] ?? 'Unknown Student';
    final activityName = claim['activityName'] ?? 'Unknown Activity';
    final submittedAt = claim['submittedAt'] ?? '';
    final supportingDoc = claim['supportingDoc'] ?? '';
    final claimId = claim['_id'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableCard(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: SAMsTheme.surface,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 16,
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SAMsTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.user_copy,
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
                          studentName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SAMsTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activityName,
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
                  _buildStatusBadge('pending'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Iconsax.calendar_copy,
                    size: 14,
                    color: SAMsTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Submitted: ${_formatDate(submittedAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: SAMsTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (supportingDoc.toString().isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final uri = Uri.parse(supportingDoc);
                        // url_launcher not available
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Document: $supportingDoc')),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.document_download_copy,
                            size: 14,
                            color: SAMsTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Document',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: SAMsTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _reviewClaim(claimId, 'approved'),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.tick_circle_copy,
                              size: 16,
                              color: Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Approve',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _reviewClaim(claimId, 'rejected'),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.close_circle_copy,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Reject',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildRecentDecisionsSection() {
    return AnimatedBuilder(
      animation: _staggerAnimations[4],
      builder: (context, child) {
        return Opacity(
          opacity: _staggerAnimations[4].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _staggerAnimations[4].value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Decisions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SAMsTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_recentDecisions.isEmpty && !_loading)
              _buildEmptyState(
                icon: Iconsax.clipboard_tick_copy,
                message: 'No recent decisions',
              )
            else
              ...List.generate(
                _loading ? 3 : _recentDecisions.length,
                (index) => _buildRecentDecisionCard(
                  _loading
                      ? {
                          'studentName': 'Loading...',
                          'activityName': 'Loading...',
                          'status': 'approved',
                          'reviewedAt': '2025-01-01',
                          '_id': 'skeleton_$index',
                        }
                      : _recentDecisions[index],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDecisionCard(Map<String, dynamic> claim) {
    final studentName = claim['studentName'] ?? 'Unknown Student';
    final activityName = claim['activityName'] ?? 'Unknown Activity';
    final status = claim['status'] ?? 'pending';
    final reviewedAt = claim['reviewedAt'] ?? claim['submittedAt'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressableCard(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(
            color: SAMsTheme.surface,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 14,
                cornerSmoothing: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  status == 'approved'
                      ? Iconsax.tick_circle_copy
                      : Iconsax.close_circle_copy,
                  color: _statusColor(status),
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SAMsTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activityName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: SAMsTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(status),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(reviewedAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: SAMsTheme.textSecondary,
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

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: ShapeDecoration(
        color: SAMsTheme.surface,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: SAMsTheme.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: SAMsTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
