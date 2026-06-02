import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsWebView extends StatefulWidget {
  final String url;

  const NewsWebView({super.key, required this.url});

  @override
  State<NewsWebView> createState() => _NewsWebViewState();
}

class _NewsWebViewState extends State<NewsWebView> {
  late final WebViewController _controller;

  bool isLoading = true;
  bool hasMainFrameError = false;

  @override
  void initState() {
    super.initState();

    final uri = Uri.tryParse(widget.url);

    if (uri == null) {
      hasMainFrameError = true;
      isLoading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              isLoading = true;
              hasMainFrameError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (error) {
            final isMainFrame = error.isForMainFrame ?? false;

            if (!isMainFrame) return;

            if (!mounted) return;
            setState(() {
              isLoading = false;
              hasMainFrameError = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Sayfa açılamadı: ${error.description}",
                ),
              ),
            );
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Habere Geri Dön"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (!hasMainFrameError) WebViewWidget(controller: _controller),
          if (hasMainFrameError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Haber sayfası açılamadı.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Bağlantıyı kontrol edip tekrar deneyin.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          hasMainFrameError = false;
                        });
                        _controller.loadRequest(Uri.parse(widget.url));
                      },
                      child: const Text("Tekrar Dene"),
                    ),
                  ],
                ),
              ),
            ),
          if (isLoading && !hasMainFrameError)
            const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
        ],
      ),
    );
  }
}