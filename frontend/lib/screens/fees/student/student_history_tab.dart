import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class StudentHistoryTab extends StatefulWidget {
  const StudentHistoryTab({super.key});

  @override
  State<StudentHistoryTab> createState() => _StudentHistoryTabState();
}

class _StudentHistoryTabState extends State<StudentHistoryTab> {
  List<dynamic> _payments = [];
  bool _loading = true;
  String _query = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final payments = await ApiService.get('/fees/payments/history');
      setState(() { _payments = payments; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered => _payments.where((p) {
    final q = _query.toLowerCase();
    final matchQ = q.isEmpty || (p['transactionId'] ?? '').toLowerCase().contains(q) || (p['bank'] ?? '').toLowerCase().contains(q);
    final matchF = _filter == 'all' || p['status'] == _filter;
    return matchQ && matchF;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SAMsTheme.primary))
          : Column(children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: '🔍 Search transactions...'),
                ),
              ),
              // Filter chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['all', 'success', 'failed', 'pending'].map((f) {
                    final active = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? SAMsTheme.primary.withOpacity(0.15) : SAMsTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? SAMsTheme.primary.withOpacity(0.5) : SAMsTheme.border),
                        ),
                        child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : SAMsTheme.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('No transactions found.', style: TextStyle(color: SAMsTheme.textMuted)))
                    : RefreshIndicator(
                        color: SAMsTheme.primary,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            final status = p['status'] ?? 'pending';
                            final isSuccess = status == 'success';
                            final col = isSuccess ? SAMsTheme.success : (status == 'failed' ? SAMsTheme.error : SAMsTheme.accent);
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: col.withOpacity(0.12), shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(isSuccess ? '✅' : (status == 'failed' ? '❌' : '⏳'), style: const TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p['transactionId'] ?? 'Payment', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text(p['paidAt']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: SAMsTheme.textMuted)),
                                  Text.rich(TextSpan(text: '${p['bank'] ?? 'FPX'}  ·  ', style: const TextStyle(fontSize: 11, color: SAMsTheme.textMuted), children: [
                                    TextSpan(text: status[0].toUpperCase() + status.substring(1), style: TextStyle(color: col, fontWeight: FontWeight.w700)),
                                  ])),
                                  Text('#${p['transactionId'] ?? ''}', style: const TextStyle(fontSize: 10, color: SAMsTheme.textMuted, fontFamily: 'monospace')),
                                ])),
                                Text('RM ${((p['amount'] ?? 0) as num).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: col)),
                              ]),
                            );
                          },
                        ),
                      ),
              ),
            ]),
    );
  }
}
