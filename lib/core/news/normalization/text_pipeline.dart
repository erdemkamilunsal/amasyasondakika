// core/news/normalization/text_pipeline.dart

class TextPipeline {
  static String normalize(String? input) {
    if (input == null) return '';

    var text = input;

    // 1) HTML entities
    text = _decodeHtmlEntities(text);

    // 2) HTML tags
    text = _stripHtmlTags(text);

    // 3) Whitespace normalize
    text = _normalizeWhitespace(text);

    return text.trim();
  }

  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  static String _stripHtmlTags(String text) {
    final tagRegExp = RegExp(r'<[^>]*>', multiLine: true);
    return text.replaceAll(tagRegExp, '');
  }

  static String _normalizeWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u00A0', ' ');
  }
}
