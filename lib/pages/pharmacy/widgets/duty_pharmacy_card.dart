import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DutyPharmacyCard extends StatelessWidget {
  final Map<String, dynamic> pharmacy;

  const DutyPharmacyCard({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final name = pharmacy['name'] ?? '';
    final address = pharmacy['address'] ?? '';
    final phone = pharmacy['phone'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(address),
            const SizedBox(height: 8),
            if (phone.isNotEmpty)
              InkWell(
                onTap: () async {
                  final uri = Uri.parse("tel:$phone");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
