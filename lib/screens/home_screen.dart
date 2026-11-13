import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/auth_config.dart';
import '../services/auth_service.dart';
import '../services/intranet_api.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignedOut;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.onSignedOut,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final IntranetApi _api = IntranetApi(widget.authService);
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessionId = await _api.createMobileSession();
      final baseUri = Uri.parse(AuthConfig.apiBaseUrl);

      await _cookieManager.setCookie(
        WebViewCookie(
          name: 'intranet_session',
          value: sessionId,
          domain: baseUri.host,
          path: '/',
        ),
      );

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF070D19))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted && _loading) {
                setState(() => _loading = false);
              }
            },
            onNavigationRequest: (request) async {
              final uri = Uri.tryParse(request.url);
              if (uri == null) {
                return NavigationDecision.prevent;
              }
              final host = uri.host.toLowerCase();
              final isInternal =
                  host == 'marabuntarl.com' || host.endsWith('.marabuntarl.com');
              if (!isInternal) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(baseUri);

      if (!mounted) return;
      setState(() => _controller = controller);
    } on UnauthorizedException {
      await widget.authService.logout();
      if (!mounted) return;
      widget.onSignedOut();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo abrir la intranet: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final controller = _controller;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070D19),
        body: SafeArea(
          child: _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFFCA5A5)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initWebView,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    if (_controller != null)
                      WebViewWidget(controller: _controller!),
                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
