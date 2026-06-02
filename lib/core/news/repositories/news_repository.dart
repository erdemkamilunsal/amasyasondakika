import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsPage {
  final List<NewsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const NewsPage({
    required this.items,
    required this.lastDoc,
  });
}

class NewsRepository {
  NewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _baseQuery({
    String? categorySlug,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('news')
        .orderBy('pubDate', descending: true);

    // HomePage kategori göndermezse tüm haberler gelir.
    // Kategori sayfası gönderirse sadece o kategori gelir.
    if (categorySlug != null && categorySlug.trim().isNotEmpty) {
      query = query.where(
        'categorySlug',
        isEqualTo: categorySlug.trim(),
      );
    }

    return query;
  }

  Future<NewsPage> fetchFirstPage({
    int limit = 20,
    String? categorySlug,
  }) async {
    try {
      final snap = await _baseQuery(
        categorySlug: categorySlug,
      ).limit(limit).get();

      final docs = snap.docs;

      final items = docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();

      return NewsPage(
        items: items,
        lastDoc: docs.isNotEmpty ? docs.last : null,
      );
    } on FirebaseException catch (e) {
      throw Exception(
        'Firestore fetchFirstPage error: ${e.code} ${e.message}',
      );
    }
  }

  Future<NewsPage> fetchNextPage({
    required DocumentSnapshot<Map<String, dynamic>> lastDoc,
    int limit = 20,
    String? categorySlug,
  }) async {
    try {
      final snap = await _baseQuery(
        categorySlug: categorySlug,
      )
          .startAfterDocument(lastDoc)
          .limit(limit)
          .get();

      final docs = snap.docs;

      final items = docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();

      return NewsPage(
        items: items,
        lastDoc: docs.isNotEmpty ? docs.last : null,
      );
    } on FirebaseException catch (e) {
      throw Exception(
        'Firestore fetchNextPage error: ${e.code} ${e.message}',
      );
    }
  }
}