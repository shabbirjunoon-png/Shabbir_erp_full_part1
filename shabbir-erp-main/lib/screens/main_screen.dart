import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/locale_service.dart';
import 'parties_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'khata_book_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainScreen({super.key, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();
    final screens = [
      const PartiesScreen(),
      const InventoryScreen(),
      const ReportsScreen(),
      const KhataBookScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: locale.t3('Parties', 'Parties', 'پارٹیاں'), active: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: locale.t3('Stock', 'Stock', 'اسٹاک'), active: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: locale.t3('Reports', 'Reports', 'رپورٹس'), active: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: Icons.book_outlined, activeIcon: Icons.book, label: locale.t3('Ledger', 'Khata', 'کھاتہ'), active: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
                _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: locale.t3('Settings', 'Settings', 'ترتیبات'), active: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: active ? AppColors.primary : AppColors.mutedForeground),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
                color: active ? AppColors.primary : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
