import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DutyPharmacyLivePage extends StatefulWidget {
  const DutyPharmacyLivePage({super.key});

  @override
  State<DutyPharmacyLivePage> createState() => _DutyPharmacyLivePageState();
}

class _DutyPharmacyLivePageState extends State<DutyPharmacyLivePage> {
  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('duty_pharmacy')
        .doc('amasya')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF6F7F9),
        centerTitle: true,
        title: const Text(
          'Nöbetçi Eczane',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorView(
                message: 'Nöbetçi eczane verisi alınamadı.',
                onRetry: () => setState(() {}),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE53935),
                ),
              );
            }

            final data = snapshot.data?.data();
            if (data == null) {
              return const _EmptyView();
            }

            final dateText = (data['date'] ?? '').toString();

            final rawItems = (data['items'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
                <Map<String, dynamic>>[];

            final pharmacies = rawItems
                .map(
                  (e) => PharmacyItem(
                name: (e['name'] ?? '').toString(),
                address: (e['address'] ?? '').toString(),
                district: _formatDistrict((e['dist'] ?? '').toString()),
                phone: (e['phone'] ?? '').toString(),
                loc: (e['loc'] ?? '').toString(),
              ),
            )
                .toList();

            if (pharmacies.isEmpty) {
              return const _EmptyView();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  subtitle: dateText,
                  totalCount: pharmacies.length,
                ),
                const SizedBox(height: 14),
                ..._buildDistrictSections(pharmacies),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDistrict(String value) {
    if (value.trim().isEmpty) return 'Diğer';

    const specialMap = {
      'MERKEZ': 'Merkez',
      'MERZIFON': 'Merzifon',
      'SULUOVA': 'Suluova',
      'TAŞOVA': 'Taşova',
      'GÜMÜŞHACIKÖY': 'Gümüşhacıköy',
      'GÖYNÜCEK': 'Göynücek',
      'HAMAMÖZÜ': 'Hamamözü',
    };


    final upper = value.trim().toUpperCase();
    return specialMap[upper] ?? value.trim();
  }

  List<Widget> _buildDistrictSections(List<PharmacyItem> pharmacies) {
    final byDistrict = <String, List<PharmacyItem>>{};

    for (final item in pharmacies) {
      final district = item.district.trim().isEmpty ? 'Diğer' : item.district;
      byDistrict.putIfAbsent(district, () => []).add(item);
    }

    final districtNames = byDistrict.keys.toList()
      ..sort((a, b) => _districtOrder(a).compareTo(_districtOrder(b)));

    final widgets = <Widget>[];

    for (final district in districtNames) {
      widgets.add(_DistrictHeader(title: district));
      widgets.add(const SizedBox(height: 10));

      final items = byDistrict[district]!;
      for (int i = 0; i < items.length; i++) {
        widgets.add(_PharmacyCard(item: items[i]));
        if (i != items.length - 1) {
          widgets.add(const SizedBox(height: 12));
        }
      }

      widgets.add(const SizedBox(height: 18));
    }

    return widgets;
  }

  int _districtOrder(String district) {
    const order = {
      'Merkez': 0,
      'Merzifon': 1,
      'Suluova': 2,
      'Taşova': 3,
      'Gümüşhacıköy': 4,
      'Göynücek': 5,
      'Hamamözü': 6,
    };
    return order[district] ?? 999;
  }
}

class PharmacyItem {
  final String name;
  final String address;
  final String district;
  final String phone;
  final String loc;

  const PharmacyItem({
    required this.name,
    required this.address,
    required this.district,
    required this.phone,
    required this.loc,
  });
}

class _HeaderCard extends StatelessWidget {
  final String subtitle;
  final int totalCount;

  const _HeaderCard({
    required this.subtitle,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amasya Nöbetçi Eczaneler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle.isEmpty ? '-' : subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF6F6F6F),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$totalCount eczane bulundu',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistrictHeader extends StatelessWidget {
  final String title;

  const _DistrictHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F1F1F),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyItem item;

  const _PharmacyCard({required this.item});

  Future<void> _callPhone() async {
    final cleanedPhone = item.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanedPhone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMap() async {
    if (item.loc.trim().isEmpty) return;

    final coords = item.loc.split(',');
    if (coords.length != 2) return;

    final lat = coords[0].trim();
    final lng = coords[1].trim();

    final googleMapsUri =
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x11E53935),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    if (item.district.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.district,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.location_on_outlined,
            text: item.address,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.call_outlined,
            text: item.phone,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callPhone,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text(
                    'Ara',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: item.loc.trim().isEmpty ? null : _openMap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text(
                    'Harita',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF777777)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_pharmacy_outlined,
              size: 46,
              color: Color(0xFFE53935),
            ),
            SizedBox(height: 12),
            Text(
              'Gösterilecek nöbetçi eczane bulunamadı.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}