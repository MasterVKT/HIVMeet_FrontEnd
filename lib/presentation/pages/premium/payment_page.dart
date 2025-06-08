// lib/presentation/pages/premium/payment_page.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/data/services/payment_service.dart';
import 'package:go_router/go_router.dart';

class PaymentPage extends StatefulWidget {
  final String paymentUrl;
  final String reference;

  const PaymentPage({
    Key? key,
    required this.paymentUrl,
    required this.reference,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('payment/success')) {
              context.pop(true);
              return NavigationDecision.prevent;
            } else if (request.url.contains('payment/cancel')) {
              context.pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}