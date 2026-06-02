import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:amasyasondakika/widgets/app_header.dart';

class VefatPage extends StatelessWidget {
  const VefatPage({
    super.key,
    this.onMenuTap,
  });

  final VoidCallback? onMenuTap;

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFF5F6FA);
  static const Color _textColor = Color(0xFF151515);
  static const Color _softRed = Color(0xFFFFF1F1);
  static const Color _mutedTextColor = Color(0xFF777777);
  static const Color _borderColor = Color(0xFFF0F0F0);

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _shortText(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.length <= 120) return cleaned;
    return '${cleaned.substring(0, 120)}...';
  }

  Widget _sectionTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Vefat İlanları',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('vefat_records')
        .orderBy('deathDate', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CustomScrollView(
              slivers: [
                AppHeader(onMenuTap: onMenuTap),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Vefat ilanları alınırken bir hata oluştu.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _mutedTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              slivers: [
                AppHeader(onMenuTap: onMenuTap),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                ),
              ],
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return CustomScrollView(
              slivers: [
                AppHeader(onMenuTap: onMenuTap),
                _sectionTitle(),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Vefat ilanı bulunamadı.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _mutedTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              AppHeader(onMenuTap: onMenuTap),
              _sectionTitle(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final name = (data['name'] ?? '').toString();
                    final fullText = (data['fullText'] ?? '').toString();

                    final deathDate = data['deathDate'] is Timestamp
                        ? data['deathDate'] as Timestamp
                        : null;

                    final burialDate = data['burialDate'] is Timestamp
                        ? data['burialDate'] as Timestamp
                        : null;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _VefatDetailPage(
                              name: name,
                              fullText: fullText,
                              deathDate: deathDate,
                              burialDate: burialDate,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _borderColor),
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
                                    color: _softRed,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.3,
                                      fontWeight: FontWeight.w700,
                                      color: _textColor,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFB5B5B5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons.event_busy_rounded,
                                  text: 'Ölüm: ${_formatDate(deathDate)}',
                                ),
                                _InfoChip(
                                  icon: Icons.event_available_rounded,
                                  text: 'Defin: ${_formatDate(burialDate)}',
                                ),
                              ],
                            ),
                            if (fullText.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                _shortText(fullText),
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: _mutedTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _softRed = Color(0xFFFFF1F1);
  static const Color _textColor = Color(0xFF151515);
  static const Color _borderColor = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _softRed,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: _primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VefatDetailPage extends StatelessWidget {
  const _VefatDetailPage({
    required this.name,
    required this.fullText,
    required this.deathDate,
    required this.burialDate,
  });

  final String name;
  final String fullText;
  final Timestamp? deathDate;
  final Timestamp? burialDate;

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFF5F6FA);
  static const Color _textColor = Color(0xFF151515);
  static const Color _softRed = Color(0xFFFFF1F1);
  static const Color _mutedTextColor = Color(0xFF777777);
  static const Color _borderColor = Color(0xFFF0F0F0);

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Widget _detailBox({
    required IconData icon,
    required String title,
    required String value,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _softRed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _mutedTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Vefat Detayı',
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _softRed,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoChip(
                        icon: Icons.event_busy_rounded,
                        text: 'Ölüm: ${_formatDate(deathDate)}',
                      ),
                      _InfoChip(
                        icon: Icons.event_available_rounded,
                        text: 'Defin: ${_formatDate(burialDate)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _detailBox(
              icon: Icons.description_outlined,
              title: 'Açıklama',
              value: fullText,
            ),
          ],
        ),
      ),
    );
  }
}