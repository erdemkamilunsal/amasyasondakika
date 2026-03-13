import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:amasyasondakika/pages/news_webview.dart';
import 'package:amasyasondakika/core/news/repositories/news_repository.dart';
import 'package:amasyasondakika/core/news/models/news_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = NewsRepository();
  final _scroll = ScrollController();

  final List<NewsModel> _items = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  static const double _imageHeight = 180;
  static const String _placeholderAsset = 'assets/sondakika.jpg';

  @override
  void initState() {
    super.initState();
    // Bunu idealde startup'a taşırsın ama şimdilik kalsın
    initializeDateFormatting('tr_TR', null);

    _loadFirst();

    _scroll.addListener(() {
      if (!_hasMore || _loadingMore || _loading) return;
      const threshold = 300.0;
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - threshold) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return "${diff.inSeconds} saniye önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  /// - URL varsa: gerçek foto (placeholder: gri + spinner)
  /// - URL yoksa: sondakika.jpg
  /// - URL bozuksa: sondakika.jpg
  Widget _newsImage(String? url) {
    final u = (url ?? '').trim();
    final hasUrl = u.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(14),
        topRight: Radius.circular(14),
      ),
      child: SizedBox(
        height: _imageHeight,
        width: double.infinity,
        child: hasUrl
            ? CachedNetworkImage(
          imageUrl: u,
          fit: BoxFit.cover,
          placeholder: (context, _) => Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, _, __) => Image.asset(
            _placeholderAsset,
            fit: BoxFit.cover,
          ),
          fadeInDuration: const Duration(milliseconds: 150),
        )
            : Image.asset(
          _placeholderAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
      _items.clear();
      _lastDoc = null;
    });

    try {
      const limit = 20;
      final page = await _repo.fetchFirstPage(limit: limit);
      if (!mounted) return;

      setState(() {
        _items.addAll(page.items);
        _lastDoc = page.lastDoc;
        _loading = false;
        // daha doğru: limit kadar geldiyse muhtemelen daha var
        _hasMore = page.items.length == limit;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Haberler yüklenemedi. Lütfen tekrar deneyin.";
      });
    }
  }

  Future<void> _loadMore() async {
    if (_lastDoc == null) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loadingMore = true);

    try {
      const limit = 20;
      final page = await _repo.fetchNextPage(lastDoc: _lastDoc!, limit: limit);
      if (!mounted) return;

      setState(() {
        _items.addAll(page.items);
        _lastDoc = page.lastDoc;
        _loadingMore = false;
        if (page.items.isEmpty) _hasMore = false;
        // limitten az geldiyse bitti say
        if (page.items.length < limit) _hasMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadFirst,
                child: const Text("Tekrar Dene"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: _items.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text("Henüz haber yok.")),
          SizedBox(height: 8),
          Center(child: Text("Yenilemek için aşağı çekin.")),
        ],
      )
          : ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final news = _items[index];
          final formattedDate =
              "${DateFormat('d MMM yyyy', 'tr_TR').format(news.pubDate)} • ${_timeAgo(news.pubDate)}";
          final source =
              Uri.tryParse(news.sourceUrl)?.host.replaceAll("www.", "") ??
                  "";

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewsWebView(url: news.link),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _newsImage(news.imageUrl),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}