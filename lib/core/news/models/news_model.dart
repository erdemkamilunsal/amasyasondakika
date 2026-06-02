import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String description;
  final String link;
  final String sourceUrl;

  /// null => görsel yok
  final String? imageUrl;

  /// "real" | "none"
  final String imageType;

  /// "enclosure" | "media" | "html" | "direct" | "none"
  final String imageSource;

  final String category;
  final String categorySlug;

  final DateTime pubDate;

  /// Firestore serverTimestamp ise ilk anda null gelebilir
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NewsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.sourceUrl,
    required this.imageUrl,
    required this.pubDate,
    this.category = "Genel",
    this.categorySlug = "genel",
    this.imageType = "none",
    this.imageSource = "none",
    this.createdAt,
    this.updatedAt,
  });

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static DateTime _parseDate(dynamic raw, {DateTime? fallback}) {
    fallback ??= DateTime.now();

    if (raw == null) return fallback;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;

    if (raw is String) {
      return DateTime.tryParse(raw) ?? fallback;
    }

    if (raw is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } catch (_) {
        return fallback;
      }
    }

    return fallback;
  }

  static DateTime? _parseDateOrNull(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;

    if (raw is String) {
      return DateTime.tryParse(raw);
    }

    if (raw is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static String? _sanitizeImageUrl(dynamic raw) {
    if (raw == null) return null;
    if (raw is! String) return null;

    var u = raw.replaceAll('"', '').trim();
    if (u.isEmpty) return null;

    if (u.startsWith('//')) u = 'https:$u';

    if (u.startsWith('http://')) {
      u = u.replaceFirst('http://', 'https://');
    }

    if (!u.startsWith('http')) return null;

    return u;
  }

  factory NewsModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    final image =
        _sanitizeImageUrl(data['imageUrl']) ??
            _sanitizeImageUrl(data['image']);

    final sourceUrl = _readString(
      data['sourceUrl'] ?? data['source'],
    );

    final link = _readString(
      data['link'],
    );

    final title = _readString(
      data['title'],
    );

    final description = _readString(
      data['description'],
    );

    final category = _readString(
      data['category'],
      fallback: 'Genel',
    );

    final categorySlug = _readString(
      data['categorySlug'],
      fallback: 'genel',
    );

    final imageType = _readString(
      data['imageType'],
      fallback: image == null ? 'none' : 'real',
    );

    final imageSource = _readString(
      data['imageSource'],
      fallback: image == null ? 'none' : 'direct',
    );

    return NewsModel(
      id: doc.id,
      title: title,
      description: description,
      link: link,
      sourceUrl: sourceUrl,
      imageUrl: image,
      category: category.isEmpty ? 'Genel' : category,
      categorySlug: categorySlug.isEmpty ? 'genel' : categorySlug,
      pubDate: _parseDate(data['pubDate']),
      imageType: imageType.isEmpty
          ? (image == null ? 'none' : 'real')
          : imageType,
      imageSource: imageSource.isEmpty
          ? (image == null ? 'none' : 'direct')
          : imageSource,
      createdAt: _parseDateOrNull(data['createdAt']),
      updatedAt: _parseDateOrNull(data['updatedAt']),
    );
  }
}