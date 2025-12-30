import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation/main_navigation_page.dart';

class DistrictSelectionPage extends StatefulWidget {
  const DistrictSelectionPage({super.key});

  @override
  State<DistrictSelectionPage> createState() => _DistrictSelectionPageState();
}

class _DistrictSelectionPageState extends State<DistrictSelectionPage> {
  final List<String> districts = [
    "Merkez",
    "Merzifon",
    "Suluova",
    "Taşova",
    "Göynücek",
    "Gümüşhacıköy",
    "Hamamözü",
  ];

  List<String> selectedDistricts = [];

  Future<void> saveSelection() async {
    final prefs = await SharedPreferences.getInstance();

    // SEÇİMLERİ KAYDET
    await prefs.setStringList("selectedDistricts", selectedDistricts);

    // BU SATIR EKSİKTİ — ŞART!
    await prefs.setBool("hasSeenDistrictSelection", true);

    // Ana sayfaya yönlendir
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("İlçe Seçimi"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hangi ilçeleri takip etmek istersiniz?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Birden fazla seçim yapabilirsiniz.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: districts.length,
                itemBuilder: (context, index) {
                  final district = districts[index];
                  final isSelected = selectedDistricts.contains(district);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedDistricts.remove(district);
                        } else {
                          selectedDistricts.add(district);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isSelected ? Colors.red.shade50 : Colors.white,
                        border: Border.all(
                          width: 2,
                          color: isSelected ? Colors.red : Colors.grey.shade300,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected ? Colors.red : Colors.grey,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            district,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? Colors.red : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                selectedDistricts.isEmpty ? null : () => saveSelection(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Kaydet ve Devam Et",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
