import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../config/api_config.dart';

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

  Future<void> _continuePay(Map<String, dynamic> p) async {
    final txnId = p['transactionId'] ?? '';
    final method = p['method'] ?? 'fpx';
    String paymentUrl;

    if (method == 'card' && txnId.startsWith('cs_')) {
      // Stripe session - might be expired, try anyway
      paymentUrl = 'https://checkout.stripe.com/c/pay/$txnId';
    } else {
      // Toyyibpay bill code
      final baseUrl = 'https://dev.toyyibpay.com';
      paymentUrl = '$baseUrl/$txnId';
    }

    final success = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => _ContinuePayWebView(url: paymentUrl, title: 'Continue Payment'),
    ));

    // Refresh after returning
    await _load();
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
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
                          color: active ? SAMsTheme.primary.withOpacity(0.15) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? SAMsTheme.primary.withOpacity(0.5) : Theme.of(context).dividerColor),
                        ),
                        child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? SAMsTheme.primary : Theme.of(context).textTheme.bodyMedium?.color)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: _filtered.isEmpty
                    ? Center(child: Text('No transactions found.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)))
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
                            return GestureDetector(
                              onTap: status == 'pending' ? () => _continuePay(p) : null,
                              child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: status == 'pending' ? SAMsTheme.accent.withOpacity(0.4) : Theme.of(context).dividerColor)),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: col.withOpacity(0.12), shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(isSuccess ? '✅' : (status == 'failed' ? '❌' : '⏳'), style: const TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p['transactionId'] ?? 'Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 2),
                                  Text(p['paidAt'] != null && p['paidAt'].toString().length >= 10 ? p['paidAt'].toString().substring(0, 10) : (p['paidAt']?.toString() ?? ''), style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                                  Text.rich(TextSpan(text: '${p['bank'] ?? 'FPX'}  ·  ', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color), children: [
                                    TextSpan(text: status[0].toUpperCase() + status.substring(1), style: TextStyle(color: col, fontWeight: FontWeight.w700)),
                                  ])),
                                  Text('#${p['transactionId'] ?? ''}', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color, fontFamily: 'monospace')),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('RM ${((p['amount'] ?? 0) as num).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: col)),
                                  if (status == 'pending') const Padding(padding: EdgeInsets.only(top: 4), child: Text('Tap to pay →', style: TextStyle(fontSize: 10, color: SAMsTheme.accent))),
                                ]),
                              ]),
                            ));
                          },
                        ),
                      ),
              ),
            ]),
    );
  }
}

// ─── CONTINUE PAYMENT WEBVIEW ───
class _ContinuePayWebView extends StatefulWidget {
  final String url;
  final String title;
  const _ContinuePayWebView({required this.url, required this.title});

  @override
  State<_ContinuePayWebView> createState() => _ContinuePayWebViewState();
}

class _ContinuePayWebViewState extends State<_ContinuePayWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          if (request.url.contains('samsapp://') || request.url.contains('/payment/success') || request.url.contains('/payment/failed')) {
            final success = request.url.contains('success') || request.url.contains('status_id=1');
            Navigator.pop(context, success);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator(color: SAMsTheme.primary)),
      ]),
    );
  }
}
