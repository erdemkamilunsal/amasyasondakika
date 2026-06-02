import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:amasyasondakika/core/shorts/models/shorts_video_model.dart';

class ShortsRepository {
  ShortsRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('shorts_videos');

  Stream<List<ShortsVideoModel>> watchPublishedShorts({
    int limit = 20,
  }) {
    final now = Timestamp.now();

    return _collection
        .where('status', isEqualTo: 'published')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(ShortsVideoModel.fromDoc)
          .where((item) => item.playbackUrl.trim().isNotEmpty)
          .toList();

      // EN YENİ YÜKLENEN EN ÜSTTE
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return items;
    });
  }
}