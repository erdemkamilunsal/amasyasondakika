import 'package:flutter/material.dart';

import 'package:amasyasondakika/pages/home_page.dart';
import 'package:amasyasondakika/pages/notifications_page.dart';
import 'package:amasyasondakika/pages/profil_page.dart';
import 'package:amasyasondakika/pages/settings_page.dart';

// Drawer sayfaları
import 'package:amasyasondakika/pages/pharmacy/duty_pharmacy_page.dart';
import 'package:amasyasondakika/pages/namaz_vakitleri_page.dart';
import 'package:amasyasondakika/pages/hava_durumu_page.dart';
import 'package:amasyasondakika/pages/vefat_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    NotificationsPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  String get _title {
    switch (_currentIndex) {
      case 0:
        return "Amasya Son Dakika";
      case 1:
        return "Bildirimler";
      case 2:
        return "Profil";
      case 3:
        return "Ayarlar";
      default:
        return "Amasya Son Dakika";
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Menü", style: TextStyle(color: Colors.white, fontSize: 24)),
                SizedBox(height: 4),
                Text("Amasya Son Dakika", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.red),
            title: const Text("Nöbetçi Eczane"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DutyPharmacyPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: Colors.red),
            title: const Text("Namaz Vakitleri"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NamazVakitleriPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.red),
            title: const Text("Hava Durumu"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HavaDurumuPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.red),
            title: const Text("Vefat İlanları"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VefatPage()));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context), // ✅ Drawer artık her tab’da var
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.red,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Anasayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Bildirimler"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ayarlar"),
        ],
      ),
    );
  }
}