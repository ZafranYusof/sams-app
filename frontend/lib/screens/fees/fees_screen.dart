import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _fees = [];
  List<dynamic> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fees = await ApiService.get('/fees/my');
      final payments = await ApiService.get('/fees/payments/history');
      setState(() {
        _fees = fees;
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showPaymentSheet(Map<String, dynamic> fee) {
    final amountController = TextEditingController();
    String selectedBank = 'Maybank';
    final banks = ['Maybank', 'CIMB', 'RHB', 'Bank Islam', 'AmBank', 'Hong Leong'];

    showModalBottomSheet(
      context: context,
      backgroundColor: SAMsTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pay via FPX', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Outstanding: RM ${((fee['totalAmount'] ?? 0) - (fee['paidAmount'] ?? 0)).toStringAsFixed(2)}', style: const TextStyle(color: SAMsTheme.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount (RM)', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBank,
                dropdownColor: SAMsTheme.surfaceLight,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.account_balance)),
                items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setSheetState(() => selectedBank = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) return;
                    try {
                      await ApiService.post('/fees/pay', {'feeId': fee['_id'], 'amount': amount, 'bank': selectedBank});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Payment successful!'), backgroundColor: SAMsTheme.success),
                      );
                      _loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: SAMsTheme.error),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: SAMsTheme.accent),
                  child: const Text('Confirm Payment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuition Fees'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SAMsTheme.accent,
          labelColor: SAMsTheme.accent,
          unselectedLabelColor: SAMsTheme.textMuted,
          tabs: const [Tab(text: 'Fees'), Tab(text: 'Payments')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SAMsTheme.accent))
          : TabBarView(
              controller: _tabController,
              children: [_buildFees(), _buildPayments()],
            ),
    );
  }

  Widget _buildFees() {
    if (_fees.isEmpty) {
      return const Center(child: Text('No fees found', style: TextStyle(color: SAMsTheme.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fees.length,
      itemBuilder: (context, index) {
        final fee = _fees[index];
        final total = (fee['totalAmount'] ?? 0).toDouble();
        final paid = (fee['paidAmount'] ?? 0).toDouble();
        final progress = total > 0 ? paid / total : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Semester ${fee['semester']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _feeStatusColor(fee['status']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text((fee['status'] ?? '').toUpperCase(), style: TextStyle(color: _feeStatusColor(fee['status']), fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(fee['academicYear'] ?? '', style: const TextStyle(color: SAMsTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: SAMsTheme.background,
                      valueColor: AlwaysStoppedAnimation<Color>(progress >= 1 ? SAMsTheme.success : SAMsTheme.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RM ${paid.toStringAsFixed(2)} / RM ${total.toStringAsFixed(2)}', style: const TextStyle(color: SAMsTheme.textSecondary, fontSize: 13)),
                      if (fee['status'] != 'paid')
                        GestureDetector(
                          onTap: () => _showPaymentSheet(fee),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: SAMsTheme.accent, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Pay Now', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _buildPayments() {
    if (_payments.isEmpty) {
      return const Center(child: Text('No payment history', style: TextStyle(color: SAMsTheme.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: SAMsTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long, color: SAMsTheme.success, size: 20),
              ),
              title: Text('RM ${(payment['amount'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('${payment['bank'] ?? 'FPX'} | ${payment['transactionId'] ?? ''}', style: const TextStyle(color: SAMsTheme.textMuted, fontSize: 11)),
              trailing: const Icon(Icons.check_circle, color: SAMsTheme.success, size: 20),
            ),
          ),
        );
      },
    );
  }

  Color _feeStatusColor(String? status) {
    switch (status) {
      case 'paid': return SAMsTheme.success;
      case 'partial': return SAMsTheme.warning;
      case 'overdue': return SAMsTheme.error;
      default: return SAMsTheme.textMuted;
    }
  }
}
