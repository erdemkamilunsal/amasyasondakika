import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;

  static const Color _backgroundColor = Color(0xFFF5F6FA);
  static const Color _iconColor = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _backgroundColor,
      surfaceTintColor: _backgroundColor,
      centerTitle: true,
      titleSpacing: 0,
      toolbarHeight: 72,

      leadingWidth: 56,
      leading: IconButton(
        onPressed: onMenuTap,
        icon: const Icon(
          Icons.menu_rounded,
          color: _iconColor,
          size: 30,
        ),
      ),

      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Image.asset(
          'assets/logo.png',
          height: 64,
          fit: BoxFit.contain,
        ),
      ),

      actions: [
        SizedBox(
          width: 56,
          child: IconButton(
            onPressed: onSearchTap,
            icon: const Icon(
              Icons.search_rounded,
              color: _iconColor,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}