import 'package:cloud_firestore/cloud_firestore.dart';

class ShortsVideoModel {
  const ShortsVideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.sourceName,
    required this.sourceUsername,
    required this.sourcePlatform,
    required this.sourceUrl,
    required this.channelName,
    required this.provider,
    required this.videoId,
    required this.playbackUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final String title;
  final String description;

  final String sourceName;
  final String sourceUsername;
  final String sourcePlatform;
  final String sourceUrl;
  final String channelName;

  final String provider;
  final String videoId;
  final String playbackUrl;
  final String thumbnailUrl;

  final int duration;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status;

  factory ShortsVideoModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return ShortsVideoModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      sourceName: (data['sourceName'] ?? '').toString(),
      sourceUsername: (data['sourceUsername'] ?? '').toString(),
      sourcePlatform: (data['sourcePlatform'] ?? '').toString(),
      sourceUrl: (data['sourceUrl'] ?? '').toString(),
      channelName: (data['channelName'] ?? '').toString(),
      provider: (data['provider'] ?? '').toString(),
      videoId: (data['videoId'] ?? '').toString(),
      playbackUrl: (data['playbackUrl'] ?? '').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? '').toString(),
      duration: (data['duration'] is int)
          ? data['duration'] as int
          : int.tryParse((data['duration'] ?? '0').toString()) ?? 0,
      createdAt: parseDate(data['createdAt']),
      expiresAt: parseDate(data['expiresAt']),
      status: (data['status'] ?? 'draft').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'sourceName': sourceName,
      'sourceUsername': sourceUsername,
      'sourcePlatform': sourcePlatform,
      'sourceUrl': sourceUrl,
      'channelName': channelName,
      'provider': provider,
      'videoId': videoId,
      'playbackUrl': playbackUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }
}