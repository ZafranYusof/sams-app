import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/shimmer_loading.dart';

class StudentHomeTab extends ConsumerStatefulWidget {
  const StudentHomeTab({super.key});

  @override
  ConsumerState<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends ConsumerState<StudentHomeTab> {
  List<dynamic> _fees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fees = await ApiService.get('/fees/my');
      setState(() { _fees = fees; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double get _totalDue => _fees.fold(0.0, (s, f) => s + ((f['totalAmount'] ?? 0) as num).toDouble());
  double get _totalPaid => _fees.fold(0.0, (s, f) => s + ((f['paidAmount'] ?? 0) as num).toDouble());
  double get _balance => _totalDue - _totalPaid;
  double get _pct => _totalDue > 0 ? (_totalPaid / _totalDue).clamp(0.0, 1.0) : 0.0;

  int get _week {
    final start = DateTime(2026, 2, 9);
    return (DateTime.now().difference(start).inDays ~/ 7 + 1).clamp(1, 16);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final studentId = user?['studentId'] ?? 'CB23109';

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Tuition Fees')), body: const ShimmerCards());

    final daysLeft = DateTime(2026, 6, 30).difference(DateTime.now()).inDays.clamp(0, 999);
    final blocked = _week >= 5 && _balance > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuition Fees'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: blocked ? SAMsTheme.error.withOpacity(0.15) : SAMsTheme.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: blocked ? SAMsTheme.error.withOpacity(0.3) : SAMsTheme.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: blocked ? SAMsTheme.error : SAMsTheme.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(blocked ? 'Blocked' : 'Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: blocked ? SAMsTheme.error : SAMsTheme.success)),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: SAMsTheme.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text('Hello, $studentId 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Sem 2, 2025/2026 · Week $_week', style: const TextStyle(fontSize: 12, color: SAMsTheme.textMuted)),
            const SizedBox(height: 16),

            // Warning
            if (_week < 5 && _balance > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: SAMsTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: SAMsTheme.accent.withOpacity(0.3))),
                child: const Text('⚠️  Pay before Week 5 to maintain academic access', style: TextStyle(color: SAMsTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
              ),

            // Summary cards
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Total Due', value: _fmtRm(_totalDue), emoji: '💰', color: SAMsTheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: _SummaryCard(label: 'Paid', value: _fmtRm(_totalPaid), emoji: '✅', color: SAMsTheme.success)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Balance', value: _fmtRm(_balance), emoji: '⏳', color: SAMsTheme.accent)),
                const SizedBox(width: 10),
                Expanded(child: _SummaryCard(label: 'Days Left', value: '$daysLeft', emoji: '📆', color: const Color(0xFFA855F7))),
              ],
            ),
            const SizedBox(height: 16),

            // Progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${_fmtRm(_totalPaid)} paid', style: const TextStyle(fontSize: 12, color: SAMsTheme.textSecondary)),
                    Text('${(_pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: SAMsTheme.primary, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _pct, minHeight: 8, backgroundColor: SAMsTheme.background, valueColor: AlwaysStoppedAnimation<Color>(_pct >= 1 ? SAMsTheme.success : SAMsTheme.primary))),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('RM 0', style: TextStyle(fontSize: 11, color: SAMsTheme.textMuted)),
                    Text(_fmtRm(_totalDue), style: const TextStyle(fontSize: 11, color: SAMsTheme.textMuted)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fee breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fee Breakdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 12),
                  ..._fees.expand((fee) {
                    final items = (fee['items'] as List?) ?? [];
                    return items.map((item) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SAMsTheme.border))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['description'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          Text('RM ${((item['amount'] ?? 0) as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtRm(double n) => 'RM ${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

class _SummaryCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SAMsTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SAMsTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }
}
