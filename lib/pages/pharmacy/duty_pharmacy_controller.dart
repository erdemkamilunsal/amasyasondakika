import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DutyPharmacyController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? error;

  /// İlçe -> Eczane Listesi
  Map<String, List<Map<String, dynamic>>> pharmaciesByDistrict = {};

  Future<void> fetch() async {
    try {
      isLoading = true;
      notifyListeners();

      final doc = await _firestore
          .collection('duty_pharmacy')
          .doc('amasya')
          .get();

      if (!doc.exists) {
        error = "Eczane verisi bulunamadı";
        return;
      }

      final data = doc.data()!;
      final List districts = List.from(data['districts'] ?? []);
      final Map rawData = Map.from(data['data'] ?? {});

      pharmaciesByDistrict.clear();

      for (final district in districts) {
        final list = rawData[district] ?? [];
        pharmaciesByDistrict[district] =
        List<Map<String, dynamic>>.from(list);
      }

      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
