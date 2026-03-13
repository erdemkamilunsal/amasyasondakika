import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsPage {
  final List<NewsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const NewsPage({required this.items, required this.lastDoc});
}

class NewsRepository {
  NewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Ana sıralama alanı.
  /// Firestore query: Bu alanın tüm dokümanlarda olması gerekir.
  /// Eğer eski veride yoksa, backend’de her kayda yazdır (önerim) veya koleksiyonu temizle.
  static const String _primaryOrderField = 'pubDate';

  Query<Map<String, dynamic>> _baseQuery() {
    // Deterministik pagination için ikinci order:
    // pubDate aynı olduğunda docId ile stabil sıralama.
    return _firestore
        .collection('news')
        .orderBy(_primaryOrderField, descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  Future<NewsPage> fetchFirstPage({int limit = 20}) async {
    try {
      final snap = await _baseQuery().limit(limit).get();

      final docs = snap.docs;
      final items = docs.map((d) => NewsModel.fromFirestore(d)).toList();

      return NewsPage(items: items, lastDoc: docs.isNotEmpty ? docs.last : null);
    } on FirebaseException catch (e) {
      // pubDate eksik/null ise burada patlar. Mesajı net görmen için:
      throw Exception("Firestore fetchFirstPage error: ${e.code} ${e.message}");
    }
  }

  Future<NewsPage> fetchNextPage({
    required DocumentSnapshot<Map<String, dynamic>> lastDoc,
    int limit = 20,
  }) async {
    try {
      final snap = await _baseQuery()
          .startAfterDocument(lastDoc)
          .limit(limit)
          .get();

      final docs = snap.docs;
      final items = docs.map((d) => NewsModel.fromFirestore(d)).toList();

      return NewsPage(items: items, lastDoc: docs.isNotEmpty ? docs.last : null);
    } on FirebaseException catch (e) {
      throw Exception("Firestore fetchNextPage error: ${e.code} ${e.message}");
    }
  }
}
