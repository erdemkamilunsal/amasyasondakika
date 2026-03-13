// core/news/normalization/normalize_news.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_model.dart';
import 'text_pipeline.dart';
import 'image_pipeline.dart';

class NormalizeNews {
  static NewsModel fromMap(
      Map<String, dynamic> raw, {
        required String sourceUrl,
      }) {
    // --- TEXT ---
    final title = TextPipeline.normalize(raw['title']);
    final description = TextPipeline.normalize(
      raw['description'] ?? raw['content'] ?? raw['contentSnippet'],
    );

    // --- LINK ---
    final link = raw['link']?.toString() ?? '';

    // --- IMAGE CANDIDATES ---
    final List<ImageCandidate> imageCandidates = [];

    // yeni şema
    if (raw['imageUrl'] is String) {
      imageCandidates.add(ImageCandidate(raw['imageUrl'], 'direct'));
    }

    // legacy
    if (raw['image'] is String) {
      imageCandidates.add(ImageCandidate(raw['image'], 'direct'));
    }

    if (raw['enclosure'] is String) {
      imageCandidates.add(ImageCandidate(raw['enclosure'], 'enclosure'));
    }

    if (raw['mediaImage'] is String) {
      imageCandidates.add(ImageCandidate(raw['mediaImage'], 'media'));
    }

    if (raw['htmlImage'] is String) {
      imageCandidates.add(ImageCandidate(raw['htmlImage'], 'html'));
    }

    final imageResult = ImagePipeline.resolve(imageCandidates);

    // --- DATE ---
    final pubDate = _parseDate(raw['pubDate']);

    // optional timestamps
    final createdAt = raw.containsKey('createdAt') ? _parseDateOrNull(raw['createdAt']) : null;
    final updatedAt = raw.containsKey('updatedAt') ? _parseDateOrNull(raw['updatedAt']) : null;

    return NewsModel(
      id: _stableId(link),
      title: title,
      description: description,
      link: link,
      sourceUrl: sourceUrl,
      pubDate: pubDate,
      imageUrl: imageResult.url,
      imageType: imageResult.type,     // "real"/"none"
      imageSource: imageResult.source, // "enclosure"/"media"/...
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();

    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) return DateTime.tryParse(value);

    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Stabil id: base64Url(link)
  static String _stableId(String link) {
    if (link.isEmpty) return DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(link);
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
