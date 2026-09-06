import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold bottom nav 4 tab + FAB tengah (docked) — sesuai DESIGN.md #6.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _labels = ['Home', 'Transactions', 'Insights', 'More'];
  static const _icons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.insights_outlined,
    Icons.more_horiz,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keyboard nutupin FAB + bottom nav (bukan ndorong FAB naik nangkring di
      // atas keyboard). Form punya Scaffold sendiri buat resize kontennya.
      resizeToAvoidBottomInset: false,
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_labels.length, (index) {
            // FAB duduk di antara index 1 (Transactions) & 2 (Insights).
            final isSelected = navigationShell.currentIndex == index;
            return _NavItem(
              icon: _icons[index],
              label: _labels[index],
              selected: isSelected,
              onTap: () => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            );
          })
            ..insert(2, const SizedBox(width: 40)), // ruang buat notch FAB
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Garis lapangan di atas item aktif.
            Container(
              height: 3,
              width: 20,
              margin: const EdgeInsets.only(bottom: 3),
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
