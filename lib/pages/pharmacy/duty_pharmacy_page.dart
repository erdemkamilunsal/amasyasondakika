import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'duty_pharmacy_controller.dart';
import 'widgets/duty_pharmacy_card.dart';

class DutyPharmacyPage extends StatelessWidget {
  const DutyPharmacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DutyPharmacyController>(
      create: (_) => DutyPharmacyController()..fetch(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Nöbetçi Eczaneler"),
        ),
        body: Consumer<DutyPharmacyController>(
          builder: (context, c, _) {
            if (c.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (c.error != null) {
              return Center(child: Text(c.error!));
            }

            return ListView(
              padding: const EdgeInsets.all(12),
              children: c.pharmaciesByDistrict.entries.map((entry) {
                final district = entry.key;
                final pharmacies = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      district,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (pharmacies.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text("Bugün nöbetçi eczane yok"),
                      ),
                    ...pharmacies.map(
                          (p) => DutyPharmacyCard(pharmacy: p),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
