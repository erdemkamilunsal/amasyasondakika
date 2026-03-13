// core/news/normalization/image_pipeline.dart

class ImageCandidate {
  final String url;
  final String source;

  ImageCandidate(this.url, this.source);
}

class ImagePipelineResult {
  final String? url;
  final String type;   // real | none
  final String source; // enclosure | media | html | none

  const ImagePipelineResult({
    required this.url,
    required this.type,
    required this.source,
  });

  factory ImagePipelineResult.none() {
    return const ImagePipelineResult(
      url: null,
      type: 'none',
      source: 'none',
    );
  }
}

class ImagePipeline {
  static ImagePipelineResult resolve(List<ImageCandidate> candidates) {
    for (final candidate in candidates) {
      final cleanUrl = _sanitizeUrl(candidate.url);
      if (_isValidImageUrl(cleanUrl)) {
        return ImagePipelineResult(
          url: cleanUrl,
          type: 'real',
          source: candidate.source,
        );
      }
    }

    return ImagePipelineResult.none();
  }

  static String _sanitizeUrl(String url) {
    var u = url.trim().replaceAll('"', '');

    if (u.startsWith('http://')) {
      u = u.replaceFirst('http://', 'https://');
    }

    return u;
  }

  static bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) return false;

    return _hasImageExtension(uri.path);
  }

  static bool _hasImageExtension(String path) {
    const extensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return extensions.any(path.toLowerCase().endsWith);
  }
}
