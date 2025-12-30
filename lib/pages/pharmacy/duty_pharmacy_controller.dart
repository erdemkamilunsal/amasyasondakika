import 'package:cloud_firestore/cloud_firestore.dart';

class DutyPharmacyController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchPharmacies() async {
    try {
      // 🔥 ALT KOLEKSİYON
      final snapshot = await _db
          .collection("duty_pharmacy")
          .doc("amasya")
          .collection("districts")
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          "error": false,
          "data": {},
          "message": "Liste boş",
        };
      }

      /// 🔥 Yapıyı normal map'e çevir
      final Map<String, dynamic> result = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        result[doc.id] = List<Map<String, dynamic>>.from(
          (data["list"] ?? []).map(
                (e) => Map<String, dynamic>.from(e),
          ),
        );
      }

      return {
        "error": false,
        "data": result,
      };
    } catch (e) {
      return {
        "error": true,
        "message": "Veri alınırken hata oluştu: $e",
        "data": {}
      };
    }
  }
}
