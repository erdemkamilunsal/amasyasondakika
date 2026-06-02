import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:amasyasondakika/widgets/app_header.dart';

class HavaDurumuPage extends StatefulWidget {
  const HavaDurumuPage({
    super.key,
    this.onMenuTap,
  });

  final VoidCallback? onMenuTap;

  @override
  State<HavaDurumuPage> createState() => _HavaDurumuPageState();
}

class _HavaDurumuPageState extends State<HavaDurumuPage> {
  static const Color _primaryColor = Color(0xFF2F80ED); // hava durumu mavi kalsın
  static const Color _backgroundColor = Color(0xFFF5F6FA); // vefat page arka plan
  static const Color _textColor = Color(0xFF151515); // ortak metin rengi
  static const Color _softBlue = Color(0xFFEAF4FF); // hava ikon kutuları kalsın
  static const Color _mutedTextColor = Color(0xFF777777);
  static const Color _borderColor = Color(0xFFF0F0F0);

  String _selectedDistrictId = 'amasya_merkez';

  final List<_DistrictItem> _districts = const [
    _DistrictItem(id: 'amasya_merkez', name: 'Amasya Merkez'),
    _DistrictItem(id: 'merzifon', name: 'Merzifon'),
    _DistrictItem(id: 'suluova', name: 'Suluova'),
    _DistrictItem(id: 'tasova', name: 'Taşova'),
    _DistrictItem(id: 'goynucek', name: 'Göynücek'),
    _DistrictItem(id: 'gumushacikoy', name: 'Gümüşhacıköy'),
    _DistrictItem(id: 'hamamozu', name: 'Hamamözü'),
  ];

  Stream<DocumentSnapshot<Map<String, dynamic>>> _weatherStream() {
    return FirebaseFirestore.instance
        .collection('weather_forecasts')
        .doc(_selectedDistrictId)
        .snapshots();
  }

  String _selectedDistrictName() {
    return _districts
        .firstWhere(
          (district) => district.id == _selectedDistrictId,
      orElse: () => _districts.first,
    )
        .name;
  }

  String _capitalizeWords(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return clean;

    return clean.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatTemp(dynamic value) {
    if (value == null) return '--';
    final numValue = value is num ? value : num.tryParse(value.toString());
    if (numValue == null) return '--';
    return '${numValue.round()}°';
  }

  String _formatWind(dynamic value) {
    if (value == null) return '--';
    final numValue = value is num ? value : num.tryParse(value.toString());
    if (numValue == null) return '--';
    return '${(numValue * 3.6).round()} km/s';
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String _formatHour(dynamic value) {
    final date = _toDate(value);
    if (date == null) return '--:--';
    return DateFormat('HH:mm', 'tr_TR').format(date);
  }

  String _formatDay(dynamic value) {
    final date = _toDate(value);
    if (date == null) return '--';
    return _capitalizeWords(DateFormat('EEEE', 'tr_TR').format(date));
  }

  String _formatUpdatedAt(dynamic value) {
    final date = _toDate(value);
    if (date == null) return 'Henüz güncellenmedi';
    return 'Son güncelleme: ${DateFormat('HH:mm', 'tr_TR').format(date)}';
  }

  String _weatherIconUrl(String? iconCode) {
    final code = (iconCode == null || iconCode.isEmpty) ? '02d' : iconCode;
    return 'https://openweathermap.org/img/wn/$code@4x.png';
  }

  Widget _buildWeatherIcon(String? iconCode, {double size = 72}) {
    return Image.network(
      _weatherIconUrl(iconCode),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(
          Icons.cloud_rounded,
          size: size * 0.72,
          color: _primaryColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _weatherStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              slivers: [
                AppHeader(onMenuTap: widget.onMenuTap),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data?.data();

          if (data == null) {
            return _buildEmptyState();
          }

          final current = Map<String, dynamic>.from(data['current'] ?? {});
          final hourly = List<Map<String, dynamic>>.from(
            (data['hourly'] ?? []).map((e) => Map<String, dynamic>.from(e)),
          );
          final daily = List<Map<String, dynamic>>.from(
            (data['daily'] ?? []).map((e) => Map<String, dynamic>.from(e)),
          );

          return RefreshIndicator(
            color: _primaryColor,
            onRefresh: () async {},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AppHeader(onMenuTap: widget.onMenuTap),
                SliverToBoxAdapter(child: _buildDistrictDropdown()),
                SliverToBoxAdapter(child: _buildCurrentCard(current)),
                SliverToBoxAdapter(child: _buildSectionTitle('Saatlik Tahmin')),
                SliverToBoxAdapter(child: _buildHourlyList(hourly)),
                SliverToBoxAdapter(child: _buildSectionTitle('7 Günlük Tahmin')),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildDailyItem(daily[index]),
                    childCount: daily.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildDistrictDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: InkWell(
        onTap: _showDistrictPicker,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE7F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedDistrictName(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6C7A92),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE7F2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'İlçe Seç',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 10),
                ..._districts.map((district) {
                  final selected = district.id == _selectedDistrictId;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDistrictId = district.id;
                      });

                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _softBlue : const Color(0xFFF8FBFF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFBBDDFB)
                              : const Color(0xFFE3EDF7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? _primaryColor
                                : const Color(0xFF9AA8BC),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              district.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                                color: selected ? _primaryColor : _textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentCard(Map<String, dynamic> current) {
    final description = _capitalizeWords(
      (current['description'] ?? 'Hava durumu').toString(),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWeatherIcon(current['icon']?.toString(), size: 92),
          const SizedBox(height: 12),
          Text(
            _formatTemp(current['temp']),
            style: const TextStyle(
              fontSize: 58,
              height: 1,
              fontWeight: FontWeight.w900,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  title: 'Hissedilen',
                  value: _formatTemp(current['feelsLike']),
                  icon: Icons.thermostat_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoBox(
                  title: 'Nem',
                  value: '%${current['humidity'] ?? '--'}',
                  icon: Icons.water_drop_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoBox(
                  title: 'Rüzgar',
                  value: _formatWind(current['windSpeed']),
                  icon: Icons.air_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: _primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6C7A92),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: _textColor,
        ),
      ),
    );
  }

  Widget _buildHourlyList(List<Map<String, dynamic>> hourly) {
    if (hourly.isEmpty) {
      return _buildSmallEmptyCard('Saatlik tahmin bulunamadı.');
    }

    return SizedBox(
      height: 128,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = hourly[index];

          return Container(
            width: 86,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatHour(item['dt']),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C7A92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _buildWeatherIcon(item['icon']?.toString(), size: 38),
                const SizedBox(height: 10),
                Text(
                  _formatTemp(item['temp']),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyItem(Map<String, dynamic> item) {
    final description = _capitalizeWords(
      (item['description'] ?? '').toString(),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              _formatDay(item['dt']),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textColor,
              ),
            ),
          ),
          _buildWeatherIcon(item['icon']?.toString(), size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6C7A92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_formatTemp(item['maxTemp'])} / ${_formatTemp(item['minTemp'])}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallEmptyCard(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6C7A92),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        AppHeader(onMenuTap: widget.onMenuTap),
        const SliverToBoxAdapter(

        ),
        SliverToBoxAdapter(child: _buildDistrictDropdown()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 54,
                    color: _primaryColor,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Hava durumu verisi bekleniyor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'OpenWeather aktif olduğunda bu ekran otomatik olarak dolacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF6C7A92),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DistrictItem {
  final String id;
  final String name;

  const _DistrictItem({
    required this.id,
    required this.name,
  });
}