import 'package:flutter/material.dart';

import 'duty_pharmacy_controller.dart';
import 'widgets/duty_pharmacy_section.dart';

class DutyPharmacyPage extends StatefulWidget {
  const DutyPharmacyPage({super.key});

  @override
  State<DutyPharmacyPage> createState() => _DutyPharmacyPageState();
}

class _DutyPharmacyPageState extends State<DutyPharmacyPage> {
  final DutyPharmacyController controller = DutyPharmacyController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nöbetçi Eczaneler"),
        backgroundColor: Colors.red,
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: controller.fetchPharmacies(), // <-- doğru metot adı
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          // hata veya olmayan doc
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text("Veri bulunamadı."),
            );
          }

          final result = snapshot.data!;

          // controller dönen yapıda hata varsa göster
          if (result["error"] == true) {
            final msg = result["message"] ?? "Bir hata oluştu.";
            return Center(child: Text(msg));
          }

          // 'data' alanını çek (bu bizim districts map'imiz)
          final rawData = Map<String, dynamic>.from(result["data"] ?? {});

          if (rawData.isEmpty) {
            return const Center(child: Text("Nöbetçi eczane verisi boş."));
          }

          // rawData: { "Merkez": [ {...}, {...} ], "Merzifon": [ ... ], ... }
          // Convert to ordered list of entries
          final entries = rawData.entries.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: entries.map((entry) {
                final districtName = entry.key;
                final listDynamic = entry.value ?? [];
                // safety cast to List<Map<String,dynamic>>
                final pharmacies = List<Map<String, dynamic>>.from(
                  (listDynamic as List).map((e) => Map<String, dynamic>.from(e as Map)),
                );

                return DutyPharmacySection(
                  districtName: districtName,
                  pharmacies: pharmacies,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
