import 'package:flutter/material.dart';

import 'package:amasyasondakika/pages/home_page.dart';
import 'package:amasyasondakika/pages/vefat_page.dart';
import 'package:amasyasondakika/pages/pharmacy/duty_pharmacy_page.dart';
import 'package:amasyasondakika/pages/hava_durumu_page.dart';
import 'package:amasyasondakika/pages/namaz_vakitleri_page.dart';
import 'package:amasyasondakika/pages/shorts/shorts_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFF5F6FA);

  late final List<Widget> _pages = [
    HomePage(
      onMenuTap: _openDrawer,
    ),
    const _PlaceholderPage(title: 'Arama'),
    ShortsPage(
      isPageActive: _currentIndex == 2,
    ),
    const _PlaceholderPage(title: 'Bildirimler'),
    const _PlaceholderPage(title: 'Profil'),
    VefatPage(
      onMenuTap: _openDrawer,
    ),
    const DutyPharmacyPage(),
    const HavaDurumuPage(),
    const NamazVakitleriPage(),
  ];

  final List<_BottomNavItem> _items = const [
    _BottomNavItem(
      icon: Icons.home_rounded,
      label: 'Anasayfa',
    ),
    _BottomNavItem(
      icon: Icons.search_rounded,
      label: 'Arama',
    ),
    _BottomNavItem(
      icon: Icons.play_circle_fill_rounded,
      label: 'Shorts',
      isSpecial: true,
    ),
    _BottomNavItem(
      icon: Icons.notifications_rounded,
      label: 'Bildirimler',
    ),
    _BottomNavItem(
      icon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  void _onTabSelected(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  void _openDrawer() {
    if (_currentIndex == 2) return;
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectPageFromDrawer(int index) {
    Navigator.pop(context);

    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _currentIndex = index;
    });
  }

  bool get _showFloatingMenuButton => false;

  int get _safePageIndex {
    if (_currentIndex < 0 || _currentIndex >= _pages.length) return 0;
    return _currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      drawerScrimColor: Colors.transparent,
      drawer: _AppSideMenu(
        currentIndex: _currentIndex,
        onItemTap: _selectPageFromDrawer,
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _safePageIndex,
            children: _pages,
          ),
          if (_showFloatingMenuButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 14,
              child: _FloatingMenuButton(
                onTap: _openDrawer,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _CustomBottomNavigationBar(
        items: _items,
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _AppSideMenu extends StatelessWidget {
  const _AppSideMenu({
    required this.currentIndex,
    required this.onItemTap,
  });

  final int currentIndex;
  final ValueChanged<int> onItemTap;

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFF5F6FA);
  static const Color _textColor = Color(0xFF151515);
  static const Color _mutedColor = Color(0xFF777777);
  static const Color _borderColor = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 318,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 20),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.newspaper_rounded,
                      color: _primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amasya',
                          style: TextStyle(
                            color: _mutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Son Dakika',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                children: [
                  const _MenuSectionTitle(title: 'Ana Menü'),
                  _SideMenuItem(
                    icon: Icons.home_rounded,
                    label: 'Anasayfa',
                    selected: currentIndex == 0,
                    onTap: () => onItemTap(0),
                  ),
                  _SideMenuItem(
                    icon: Icons.notifications_rounded,
                    label: 'Bildirimler',
                    selected: currentIndex == 3,
                    onTap: () => onItemTap(3),
                  ),
                  _SideMenuItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    selected: currentIndex == 4,
                    onTap: () => onItemTap(4),
                  ),
                  const SizedBox(height: 18),
                  const _MenuSectionTitle(title: 'Hizmetler'),
                  _SideMenuItem(
                    icon: Icons.favorite_rounded,
                    label: 'Vefat İlanları',
                    selected: currentIndex == 5,
                    onTap: () => onItemTap(5),
                  ),
                  _SideMenuItem(
                    icon: Icons.medical_services_rounded,
                    label: 'Nöbetçi Eczane',
                    selected: currentIndex == 6,
                    onTap: () => onItemTap(6),
                  ),
                  _SideMenuItem(
                    icon: Icons.wb_cloudy_rounded,
                    label: 'Hava Durumu',
                    selected: currentIndex == 7,
                    onTap: () => onItemTap(7),
                  ),
                  _SideMenuItem(
                    icon: Icons.schedule_rounded,
                    label: 'Namaz Vakitleri',
                    selected: currentIndex == 8,
                    onTap: () => onItemTap(8),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Amasya için hızlı erişim menüsü',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingMenuButton extends StatelessWidget {
  const _FloatingMenuButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  static const Color _primaryColor = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_rounded,
            color: _primaryColor,
            size: 27,
          ),
        ),
      ),
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  const _MenuSectionTitle({
    required this.title,
  });

  final String title;

  static const Color _mutedColor = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _mutedColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  const _SideMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _textColor = Color(0xFF151515);
  static const Color _mutedColor = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF1F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          color: selected ? _primaryColor : _mutedColor,
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? _primaryColor : _textColor,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        trailing: selected
            ? const Icon(
          Icons.chevron_right_rounded,
          color: _primaryColor,
        )
            : null,
      ),
    );
  }
}

class _CustomBottomNavigationBar extends StatelessWidget {
  const _CustomBottomNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color _primaryColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFF5F6FA);
  static const Color _mutedColor = Color(0xFF8A8A8A);

  bool get _isBottomTabSelected {
    return currentIndex >= 0 && currentIndex < items.length;
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 28) / items.length;

    return Container(
      color: _backgroundColor,
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        bottomSafe > 0 ? bottomSafe + 8 : 14,
      ),
      child: SizedBox(
        height: 88,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 66,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = currentIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: selected ? 0 : 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                size: item.isSpecial ? 28 : 24,
                                color: item.isSpecial
                                    ? _primaryColor
                                    : _mutedColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: item.isSpecial
                                      ? _primaryColor
                                      : _mutedColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            if (_isBottomTabSelected)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: itemWidth * currentIndex,
                top: items[currentIndex].isSpecial ? -4 : 0,
                child: GestureDetector(
                  onTap: () => onTap(currentIndex),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: itemWidth,
                    height: items[currentIndex].isSpecial ? 90 : 82,
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        items[currentIndex].isSpecial ? 30 : 26,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: items[currentIndex].isSpecial
                              ? const Color(0x33E53935)
                              : const Color(0x22000000),
                          blurRadius: items[currentIndex].isSpecial ? 30 : 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[currentIndex].icon,
                          color: _primaryColor,
                          size: items[currentIndex].isSpecial ? 38 : 30,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          items[currentIndex].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize:
                            items[currentIndex].isSpecial ? 12 : 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: items[currentIndex].isSpecial ? 34 : 28,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isSpecial = false,
  });

  final IconData icon;
  final String label;
  final bool isSpecial;
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF151515),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}