import 'package:flutter/material.dart';
import 'duty_pharmacy_card.dart';

class DutyPharmacySection extends StatelessWidget {
  final String districtName;
  final List<Map<String, dynamic>> pharmacies;

  const DutyPharmacySection({
    super.key,
    required this.districtName,
    required this.pharmacies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// BAŞLIK
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            districtName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),

        /// Eğer liste boşsa uyarı göster
        if (pharmacies.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Bugün için nöbetçi eczane bulunmamaktadır.",
              style: TextStyle(color: Colors.red),
            ),
          ),

        /// Eczaneleri kart şeklinde göster
        ...pharmacies.map((pharmacy) {
          return DutyPharmacyCard(
            name: pharmacy["name"] ?? "",
            address: pharmacy["address"] ?? "",
            phone: pharmacy["phone"] ?? "",
          );
        }).toList(),

        const SizedBox(height: 16),
      ],
    );
  }
}
