import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:amasyasondakika/widgets/app_header.dart';
import 'package:amasyasondakika/pages/news_webview.dart';
import 'package:amasyasondakika/core/news/repositories/news_repository.dart';
import 'package:amasyasondakika/core/news/models/news_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.onMenuTap,
  });

  final VoidCallback? onMenuTap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = NewsRepository();
  final _scroll = ScrollController();
  final _heroController = PageController(viewportFraction: 0.88);

  final List<NewsModel> _items = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  Timer? _autoSlideTimer;

  int _heroIndex = 0;
  int _breakingIndex = 0;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  static const String _placeholderAsset = 'assets/sondakika.jpg';

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFF5F6FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF151515);
  static const Color _mutedTextColor = Color(0xFF777777);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _loadFirst();
    _startAutoSlide();

    _scroll.addListener(() {
      if (!_hasMore || _loadingMore || _loading) return;

      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 500) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _scroll.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) {
        if (!mounted) return;
        if (_items.isEmpty) return;

        final heroCount = _items.length > 6 ? 6 : _items.length;
        final breakingCount = _items.length > 10 ? 10 : _items.length;

        setState(() {
          if (breakingCount > 1) {
            _breakingIndex++;
            if (_breakingIndex >= breakingCount) {
              _breakingIndex = 0;
            }
          }

          if (heroCount > 1) {
            _heroIndex++;
            if (_heroIndex >= heroCount) {
              _heroIndex = 0;
            }
          }
        });

        if (_heroController.hasClients && heroCount > 1) {
          _heroController.animateToPage(
            _heroIndex,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _lastDoc = null;
      _hasMore = true;
      _heroIndex = 0;
      _breakingIndex = 0;
    });

    try {
      const limit = 30;

      final page = await _repo.fetchFirstPage(limit: limit);

      if (!mounted) return;

      setState(() {
        _items.addAll(page.items);
        _lastDoc = page.lastDoc;
        _loading = false;
        _hasMore = page.items.length == limit;
      });
    } catch (e, stackTrace) {
      debugPrint('LOAD FIRST ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
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
      const limit = 30;

      final page = await _repo.fetchNextPage(
        lastDoc: _lastDoc!,
        limit: limit,
      );

      if (!mounted) return;

      setState(() {
        _items.addAll(page.items);
        _lastDoc = page.lastDoc;
        _loadingMore = false;

        if (page.items.length < limit) {
          _hasMore = false;
        }
      });
    } catch (e, stackTrace) {
      debugPrint('LOAD MORE ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() => _loadingMore = false);
    }
  }

  void _openNews(NewsModel news) {
    if (news.link.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsWebView(url: news.link),
      ),
    );
  }

  Widget _newsImage(
      String? url, {
        double height = 180,
        double width = double.infinity,
        BorderRadius? borderRadius,
      }) {
    final imageUrl = (url ?? '').trim();

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: width,
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 900,
          placeholder: (_, __) => Container(
            color: const Color(0xFFE9EAEC),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Image.asset(
            _placeholderAsset,
            fit: BoxFit.cover,
          ),
        )
            : Image.asset(
          _placeholderAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: CircularProgressIndicator(color: _primaryColor),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _primaryColor,
                size: 46,
              ),
              const SizedBox(height: 14),
              const Text(
                'Haberler yüklenemedi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error ?? 'Bilinmeyen hata',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _mutedTextColor,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadFirst,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Text(
          'Henüz haber yok',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppHeader(
      onMenuTap: widget.onMenuTap,
      onSearchTap: () {},
    );
  }

  Widget _buildBreakingBar() {
    if (_items.isEmpty) return const SliverToBoxAdapter();

    final safeIndex = _breakingIndex.clamp(0, _items.length - 1);
    final item = _items[safeIndex];

    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => _openNews(item),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Container(
            key: ValueKey(item.id),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: _textColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'MANŞET',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSlider(List<NewsModel> news) {
    if (news.isEmpty) return const SliverToBoxAdapter();

    final itemCount = news.length > 6 ? 6 : news.length;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 355,
        child: PageView.builder(
          controller: _heroController,
          itemCount: itemCount,
          onPageChanged: (index) {
            _heroIndex = index;
          },
          itemBuilder: (context, index) {
            final item = news[index];

            return GestureDetector(
              onTap: () => _openNews(item),
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 16 : 8,
                  right: index == itemCount - 1 ? 16 : 8,
                  bottom: 22,
                ),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _newsImage(
                        item.imageUrl,
                        height: 355,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x05000000),
                              Color(0x33000000),
                              Color(0xDD000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ÖNE ÇIKAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _timeAgo(item.pubDate),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _mutedTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStoryCard(NewsModel news) {
    return GestureDetector(
      onTap: () => _openNews(news),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _newsImage(
              news.imageUrl,
              height: 205,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                news.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  color: _textColor,
                  letterSpacing: -0.25,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: _mutedTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timeAgo(news.pubDate),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _mutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactNewsCard(NewsModel news) {
    return GestureDetector(
      onTap: () => _openNews(news),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.8,
                      height: 1.28,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _timeAgo(news.pubDate),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _mutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _newsImage(
              news.imageUrl,
              width: 118,
              height: 92,
              borderRadius: BorderRadius.circular(18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard({
    double height = 118,
    String label = 'Reklam Alanı',
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x22E53935),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: _primaryColor,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLeadSection(List<NewsModel> news) {
    final widgets = <Widget>[];

    for (int i = 0; i < news.length; i++) {
      widgets.add(_buildTopStoryCard(news[i]));

      if ((i + 1) % 3 == 0) {
        widgets.add(_buildAdCard(height: 145));
      }
    }

    return widgets;
  }

  List<Widget> _buildFeedSection(List<NewsModel> news) {
    final widgets = <Widget>[];

    for (int i = 0; i < news.length; i++) {
      widgets.add(_buildCompactNewsCard(news[i]));

      if ((i + 1) % 5 == 0) {
        widgets.add(_buildAdCard(height: 112));
      }
    }

    return widgets;
  }

  Widget _buildLoadingMore() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_items.isEmpty) return _buildEmptyState();

    final heroNews = _items.take(6).toList();
    final leadNews = _items.skip(6).take(6).toList();
    final feedNews = _items.skip(12).toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadFirst,
        color: _primaryColor,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(),
            _buildBreakingBar(),
            _buildHeroSlider(heroNews),
            if (leadNews.isNotEmpty) _sectionTitle('Gündem'),
            SliverList(
              delegate: SliverChildListDelegate(
                _buildLeadSection(leadNews),
              ),
            ),
            if (feedNews.isNotEmpty) _sectionTitle('Tüm Haberler'),
            SliverList(
              delegate: SliverChildListDelegate(
                _buildFeedSection(feedNews),
              ),
            ),
            if (_loadingMore) _buildLoadingMore(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 28),
            ),
          ],
        ),
      ),
    );
  }
}