import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DutyPharmacyController extends ChangeNotifier {
  DutyPharmacyController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool isLoading = false;
  String? error;

  /// İlçe -> Eczane Listesi
  Map<String, List<Map<String, dynamic>>> pharmaciesByDistrict = {};

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('duty_pharmacy')
          .doc('amasya')
          .get();

      if (!doc.exists) {
        pharmaciesByDistrict = {};
        error = "Eczane verisi bulunamadı.";
        return;
      }

      final data = doc.data();
      if (data == null) {
        pharmaciesByDistrict = {};
        error = "Eczane verisi boş geldi.";
        return;
      }

      final List<dynamic> districts = List<dynamic>.from(data['districts'] ?? []);
      final Map<String, dynamic> rawData =
      Map<String, dynamic>.from(data['data'] ?? {});

      final Map<String, List<Map<String, dynamic>>> parsedData = {};

      for (final district in districts) {
        final districtName = district.toString();
        final rawList = rawData[districtName];

        if (rawList is List) {
          parsedData[districtName] = rawList
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else {
          parsedData[districtName] = [];
        }
      }

      pharmaciesByDistrict = parsedData;
      error = null;
    } catch (e) {
      pharmaciesByDistrict = {};
      error = "Eczane verileri alınamadı: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetch();
  }

  bool get hasError => error != null && error!.trim().isNotEmpty;

  bool get hasData => pharmaciesByDistrict.isNotEmpty;
}