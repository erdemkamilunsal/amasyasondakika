import 'package:amasyasondakika/pages/pharmacy/duty_pharmacy_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'news_webview.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Drawer sayfaları
import 'namaz_vakitleri_page.dart';
import 'hava_durumu_page.dart';
import 'vefat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Stream<QuerySnapshot> newsStream = FirebaseFirestore.instance
      .collection("news")
      .orderBy("pubDate", descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null).then((_) {
      setState(() {});
    });
  }

  /// 🔥 URL temizleme
  String fixImageUrl(String? url) {
    if (url == null) return "";
    String u = url.replaceAll('"', '').trim();
    if (u.startsWith("http://")) {
      u = u.replaceFirst("http://", "https://");
    }
    return u;
  }

  String getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return "${diff.inSeconds} saniye önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  String getSource(String? url) {
    if (url == null) return "";
    try {
      return Uri.parse(url).host.replaceAll("www.", "");
    } catch (_) {
      return "";
    }
  }

  /// ----------------------------------------------------
  ///  📌 DRAWER WIDGET
  /// ----------------------------------------------------
  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ÜST KIRMIZI HEADER
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Menü",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 4),
                Text(
                  "Amasya Son Dakika",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Menü itemleri
          ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.red),
            title: const Text("Nöbetçi Eczane"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                  MaterialPageRoute(builder: (_) => const DutyPharmacyPage())
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.access_time, color: Colors.red),
            title: const Text("Namaz Vakitleri"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NamazVakitleriPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.red),
            title: const Text("Hava Durumu"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HavaDurumuPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.people, color: Colors.red),
            title: const Text("Vefat İlanları"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VefatPage()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text("Hakkında"),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// ----------------------------------------------------
  ///  📌 BUILD
  /// ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(context),

      appBar: AppBar(
        title: const Text("Amasya Son Dakika"),
        backgroundColor: Colors.red,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: newsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final imageUrl = fixImageUrl(data["image"]);
              final title = data["title"] ?? "";
              final link = data["link"] ?? "";
              final source = getSource(link);

              final pubDate = (data["pubDate"] as Timestamp?)?.toDate();

              final formattedDate = pubDate != null
                  ? "${DateFormat('d MMM yyyy', 'tr_TR').format(pubDate)} • ${getTimeAgo(pubDate)}"
                  : "";

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsWebView(url: link),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      imageUrl.isNotEmpty
                          ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.image, size: 60),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            pubDate != null
                                ? Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
