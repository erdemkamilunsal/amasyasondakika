import 'package:flutter/material.dart';

import 'package:amasyasondakika/core/shorts/models/shorts_video_model.dart';
import 'package:amasyasondakika/core/shorts/repositories/shorts_repository.dart';
import 'package:amasyasondakika/pages/shorts/admin_shorts_upload_page.dart';
import 'package:amasyasondakika/pages/shorts/widgets/shorts_video_player.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({
    super.key,
    required this.isPageActive,
  });

  final bool isPageActive;

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  final PageController _pageController = PageController();
  final ShortsRepository _repository = ShortsRepository();

  Stream<List<ShortsVideoModel>>? _shortsStream;

  int _currentIndex = 0;

  double _dragStartY = 0;
  double _dragDistance = 0;
  bool _isRefreshing = false;

  static const double _refreshThreshold = 120;

  @override
  void initState() {
    super.initState();
    _shortsStream = _repository.watchPublishedShorts();
  }

  void _goToUploadPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminShortsUploadPage(),
      ),
    );
  }

  Future<void> _refreshLatestVideo() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 750));

    if (!mounted) return;

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    setState(() {
      _currentIndex = 0;
      _isRefreshing = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _videoUrlOf(ShortsVideoModel item) {
    return item.playbackUrl.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<ShortsVideoModel>>(
        stream: _shortsStream ?? _repository.watchPublishedShorts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const _ShortsLoadingState();
          }

          if (snapshot.hasError) {
            return const _ShortsMessageState(
              icon: Icons.error_outline_rounded,
              message: 'Videolar yüklenemedi',
            );
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return const _ShortsMessageState(
              icon: Icons.play_circle_outline_rounded,
              message: 'Henüz video yok',
            );
          }

          return Stack(
            children: [
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  if (_currentIndex != 0) return;

                  _dragStartY = event.position.dy;
                  _dragDistance = 0;
                },
                onPointerMove: (event) {
                  if (_currentIndex != 0 || _isRefreshing) return;

                  final distance = event.position.dy - _dragStartY;

                  if (distance > 0) {
                    _dragDistance = distance;
                  }
                },
                onPointerUp: (_) {
                  if (_currentIndex == 0 &&
                      _dragDistance > _refreshThreshold &&
                      !_isRefreshing) {
                    _refreshLatestVideo();
                  }

                  _dragStartY = 0;
                  _dragDistance = 0;
                },
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = videos[index];
                    final videoUrl = _videoUrlOf(item);

                    return _ShortsItem(
                      title: item.title,
                      source: item.sourceUsername.isNotEmpty
                          ? item.sourceUsername
                          : item.sourceName,
                      channel: item.channelName,
                      videoUrl: videoUrl,
                      isActive: widget.isPageActive && index == _currentIndex,
                    );
                  },
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                top: _isRefreshing
                    ? MediaQuery.of(context).padding.top + 18
                    : MediaQuery.of(context).padding.top - 60,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _isRefreshing ? 1 : 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Yeni videolar kontrol ediliyor',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToUploadPage,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text(
          'Video Ekle',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ShortsItem extends StatelessWidget {
  const _ShortsItem({
    required this.title,
    required this.source,
    required this.channel,
    required this.videoUrl,
    required this.isActive,
  });

  final String title;
  final String source;
  final String channel;
  final String videoUrl;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final safeSource = source.trim().isEmpty ? 'Kaynak belirtilmedi' : source;
    final safeChannel = channel.trim().isEmpty ? 'Video Gündem' : channel;

    return Stack(
      children: [
        Positioned.fill(
          child: videoUrl.trim().isEmpty
              ? const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Text(
                'Video bağlantısı yok',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
              : ShortsVideoPlayer(
            videoUrl: videoUrl,
            isActive: isActive,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 14,
          left: 16,
          right: 16,
          child: const Text(
            'Video Gündem',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 120,
          child: const Column(
            children: [
              _SideButton(
                icon: Icons.favorite_border_rounded,
                label: 'Beğen',
              ),
              SizedBox(height: 22),
              _SideButton(
                icon: Icons.share_rounded,
                label: 'Paylaş',
              ),
              SizedBox(height: 22),
              _SideButton(
                icon: Icons.flag_outlined,
                label: 'Bildir',
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 88,
          bottom: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safeSource,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.label_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    safeChannel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortsLoadingState extends StatelessWidget {
  const _ShortsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }
}

class _ShortsMessageState extends StatelessWidget {
  const _ShortsMessageState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white54,
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}