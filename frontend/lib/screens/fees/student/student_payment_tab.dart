import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class StudentPaymentTab extends StatefulWidget {
  const StudentPaymentTab({super.key});

  @override
  State<StudentPaymentTab> createState() => _StudentPaymentTabState();
}

class _StudentPaymentTabState extends State<StudentPaymentTab> {
  List<dynamic> _fees = [];
  bool _loading = true;
  int _selFeeIndex = 0;
  String _selMethod = 'fpx';
  String _selBank = 'Maybank';
  bool _paying = false;
  Map<String, dynamic>? _receipt;

  final _banks = ['Maybank', 'CIMB', 'RHB', 'Bank Islam', 'AmBank', 'Hong Leong', 'Public Bank'];

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

  double get _balance {
    double total = 0;
    for (var f in _fees) {
      total += ((f['totalAmount'] ?? 0) - (f['paidAmount'] ?? 0)).toDouble();
    }
    return total;
  }

  double get _amount {
    if (_fees.isEmpty) return 0;
    if (_selFeeIndex == 0) return _balance;
    final fee = _fees[_selFeeIndex - 1];
    return ((fee['totalAmount'] ?? 0) - (fee['paidAmount'] ?? 0)).toDouble();
  }

  Future<void> _pay() async {
    if (_amount <= 0) return;
    setState(() => _paying = true);
    try {
      final fee = _selFeeIndex == 0 ? _fees.first : _fees[_selFeeIndex - 1];
      final result = await ApiService.post('/fees/pay', {'feeId': fee['_id'], 'amount': _amount, 'bank': _selBank});
      setState(() {
        _receipt = {'status': 'paid', 'amount': _amount, 'txn_id': result['payment']?['transactionId'] ?? '', 'bank': _selBank};
        _paying = false;
      });
    } catch (e) {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: SAMsTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: SAMsTheme.primary));
    if (_receipt != null) return _buildReceipt();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Deadline
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: SAMsTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.error.withOpacity(0.3))),
            child: const Column(children: [
              Text('⏰ Payment Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SAMsTheme.accent)),
              SizedBox(height: 4),
              Text('30 June 2026', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: SAMsTheme.error)),
            ]),
          ),

          // Select fee
          _card('Select Fee to Pay', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _feeOption('Full Outstanding Balance', _balance, 0),
            ...List.generate(_fees.length, (i) {
              final f = _fees[i];
              final bal = ((f['totalAmount'] ?? 0) - (f['paidAmount'] ?? 0)).toDouble();
              return _feeOption('Semester ${f['semester']}', bal, i + 1);
            }),
          ])),
          const SizedBox(height: 12),

          // Method
          _card('Payment Method', Row(children: [
            _methodBtn('fpx', '🏦', 'FPX'),
            const SizedBox(width: 8),
            _methodBtn('card', '💳', 'Card'),
          ])),
          if (_selMethod == 'fpx') ...[
            const SizedBox(height: 12),
            _card('Select Bank', DropdownButtonFormField<String>(
              value: _selBank,
              dropdownColor: SAMsTheme.surfaceLight,
              items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selBank = v!),
            )),
          ],
          const SizedBox(height: 16),

          // Summary + Pay
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SAMsTheme.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.primary.withOpacity(0.3))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total', style: TextStyle(fontSize: 15, color: Colors.white)),
                Text('RM ${_amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: SAMsTheme.primary, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              const Text('🔒 Secured by SSL Encryption', style: TextStyle(fontSize: 11, color: SAMsTheme.textMuted)),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 56, width: double.infinity, child: ElevatedButton(
            onPressed: (_paying || _amount <= 0) ? null : _pay,
            style: ElevatedButton.styleFrom(backgroundColor: SAMsTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _paying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_amount <= 0 ? '✅  Fully Paid' : '💳  Pay Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SAMsTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 12),
      child,
    ]),
  );

  Widget _feeOption(String label, double bal, int index) {
    final active = _selFeeIndex == index;
    return GestureDetector(
      onTap: bal > 0 ? () => setState(() => _selFeeIndex = index) : null,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
        Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: active ? SAMsTheme.primary : SAMsTheme.textMuted, width: 2)),
          child: active ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: SAMsTheme.primary, shape: BoxShape.circle))) : null),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: active ? SAMsTheme.primary : SAMsTheme.textSecondary))),
        Text('RM ${bal.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? SAMsTheme.primary : SAMsTheme.textSecondary)),
      ])),
    );
  }

  Widget _methodBtn(String key, String icon, String label) {
    final active = _selMethod == key;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selMethod = key),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: active ? SAMsTheme.primary.withOpacity(0.1) : SAMsTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? SAMsTheme.primary : SAMsTheme.border, width: 1.5)),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : SAMsTheme.textSecondary)),
        ]),
      ),
    ));
  }

  Widget _buildReceipt() {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: SAMsTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: SAMsTheme.border)),
        child: Column(children: [
          const Text('✅', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 24),
          _receiptRow('Receipt No.', _receipt!['txn_id']),
          _receiptRow('Amount', 'RM ${(_receipt!['amount'] as double).toStringAsFixed(2)}'),
          _receiptRow('Bank', _receipt!['bank']),
          _receiptRow('Date', DateTime.now().toString().substring(0, 16)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: () { setState(() => _receipt = null); _load(); },
            child: const Text('Done'),
          )),
        ]),
      )),
    );
  }

  Widget _receiptRow(String l, String v) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SAMsTheme.border))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 13, color: SAMsTheme.textSecondary)),
      Flexible(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.right)),
    ]),
  );
}
