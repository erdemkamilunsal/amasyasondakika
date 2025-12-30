import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DutyPharmacyCard extends StatelessWidget {
  final String name;
  final String address;
  final String phone;

  const DutyPharmacyCard({
    super.key,
    required this.name,
    required this.address,
    required this.phone,
  });

  /// Google Maps aç
  Future<void> _openMaps() async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$address");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Telefon et
  Future<void> _callPhone() async {
    final url = Uri.parse("tel:$phone");
    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ECZANE BAŞLIĞI
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          /// ADRES
          Text(
            address,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          /// BUTONLAR
          Row(
            children: [
              /// Yol Tarifi
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.location_on, color: Colors.black87),
                  label: const Text(
                    "Yol Tarifi",
                    style: TextStyle(color: Colors.black87),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// Telefon
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callPhone,
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: Text(
                    phone,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
