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
    this.imageType = "none",
    this.imageSource = "none",
    this.createdAt,
    this.updatedAt,
  });

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
    if (u.startsWith('http://')) u = u.replaceFirst('http://', 'https://');

    if (!u.startsWith('http')) return null;
    return u;
  }

  factory NewsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Yeni şema: imageUrl / sourceUrl
    // Legacy uyum: image / source
    final image = _sanitizeImageUrl(data['imageUrl']) ?? _sanitizeImageUrl(data['image']);

    final sourceUrl = (data['sourceUrl'] ?? data['source'] ?? '') is String
        ? (data['sourceUrl'] ?? data['source'] ?? '') as String
        : '';

    final link = (data['link'] ?? '') is String ? data['link'] as String : '';
    final title = (data['title'] ?? '') is String ? data['title'] as String : '';
    final description =
    (data['description'] ?? '') is String ? data['description'] as String : '';

    final pubDate = _parseDate(data['pubDate']);

    final imageType = (data['imageType'] is String)
        ? data['imageType'] as String
        : (image == null ? 'none' : 'real');

    final imageSource = (data['imageSource'] is String)
        ? data['imageSource'] as String
        : (image == null ? 'none' : 'direct');

    final createdAt = _parseDateOrNull(data['createdAt']);
    final updatedAt = _parseDateOrNull(data['updatedAt']);

    return NewsModel(
      id: doc.id,
      title: title,
      description: description,
      link: link,
      sourceUrl: sourceUrl,
      imageUrl: image,
      pubDate: pubDate,
      imageType: imageType,
      imageSource: imageSource,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
