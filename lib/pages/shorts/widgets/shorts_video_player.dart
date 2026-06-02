import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ShortsVideoPlayer extends StatefulWidget {
  const ShortsVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
  });

  final String videoUrl;
  final bool isActive;

  @override
  State<ShortsVideoPlayer> createState() => _ShortsVideoPlayerState();
}

class _ShortsVideoPlayerState extends State<ShortsVideoPlayer> {
  late final VideoPlayerController _controller;

  bool _ready = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl.trim()),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;

        setState(() {
          _ready = true;
        });

        if (widget.isActive) {
          _controller.play();
        }
      }).catchError((_) {
        if (!mounted) return;

        setState(() {
          _hasError = true;
        });
      });
  }

  @override
  void didUpdateWidget(covariant ShortsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_ready) return;

    if (widget.isActive) {
      _controller.play();
    } else {
      _controller.pause();
      _controller.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_ready) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else if (widget.isActive) {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Video oynatılamadı',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (!_ready) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}