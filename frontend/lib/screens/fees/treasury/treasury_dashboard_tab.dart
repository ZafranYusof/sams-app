import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class TreasuryDashboardTab extends StatefulWidget {
  const TreasuryDashboardTab({super.key});

  @override
  State<TreasuryDashboardTab> createState() => _TreasuryDashboardTabState();
}

class _TreasuryDashboardTabState extends State<TreasuryDashboardTab> {
  List<dynamic> _fees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fees = await ApiService.get('/fees');
      setState(() { _fees = fees; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int get _totalStudents => _fees.map((f) => f['student']?['_id']).toSet().length;
  double get _totalDue => _fees.fold(0.0, (s, f) => s + ((f['totalAmount'] ?? 0) as num).toDouble());
  double get _totalPaid => _fees.fold(0.0, (s, f) => s + ((f['paidAmount'] ?? 0) as num).toDouble());
  double get _outstanding => _totalDue - _totalPaid;
  double get _collectionRate => _totalDue > 0 ? (_totalPaid / _totalDue * 100) : 0;
  int get _fullyPaid => _fees.where((f) => f['status'] == 'paid').length;
  int get _partialPaid => _fees.where((f) => f['status'] == 'partial').length;
  int get _unpaid => _fees.where((f) => f['status'] == 'unpaid' || f['status'] == 'overdue').length;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: SAMsTheme.primary));

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Portal'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          // Stats row
          Row(children: [
            Expanded(child: _statCard('👥 Total Students', '$_totalStudents', SAMsTheme.primary)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('💹 Collection Rate', '${_collectionRate.toStringAsFixed(1)}%', SAMsTheme.success)),
          ]),
          const SizedBox(height: 10),
          // Gross outstanding
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚠️ Gross Outstanding', style: TextStyle(color: SAMsTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              Text('RM ${_outstanding.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 20),

          // Fee Status Distribution
          const Text('Fee Status Distribution', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
            child: Column(children: [
              _distRow('🟢', 'Fully Paid', '$_fullyPaid students', SAMsTheme.success),
              const SizedBox(height: 12),
              _distRow('🟡', 'Partial Paid', '$_partialPaid students', SAMsTheme.accent),
              const SizedBox(height: 12),
              _distRow('🔴', 'Unpaid', '$_unpaid students', SAMsTheme.error),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: SAMsTheme.textSecondary)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
    ]),
  );

  Widget _distRow(String dot, String label, String value, Color color) => Row(children: [
    Text(dot, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 10),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
    Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
  ]);
}
