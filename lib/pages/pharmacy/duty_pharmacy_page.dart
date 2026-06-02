import 'package:flutter/material.dart';

import 'package:amasyasondakika/widgets/app_header.dart';

class DutyPharmacyPage extends StatelessWidget {
  const DutyPharmacyPage({
    super.key,
    this.onMenuTap,
  });

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: CustomScrollView(
        slivers: [
          AppHeader(onMenuTap: onMenuTap),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
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
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0x11E53935),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              size: 38,
                              color: Color(0xFFE53935),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Nöbetçi eczaneler yakında burada olacak',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Amasya ve ilçeleri için güncel nöbetçi eczane bilgileri bu ekranda gösterilecek.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF6F6F6F),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEDEDED),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFE53935),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Bu sayfa geliştirme aşamasında',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}