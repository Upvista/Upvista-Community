import 'package:flutter/material.dart';
import '../config/theme.dart';

/**
 * Bottom Navigation Component
 * Mobile bottom navigation bar
 * iOS-inspired minimal professional design matching frontend-web
 */

class BottomNavItem {
  final String label;
  final IconData iconOutlined;
  final IconData iconFilled;
  final String route;
  final bool isSpecial;

  const BottomNavItem({
    required this.label,
    required this.iconOutlined,
    required this.iconFilled,
    required this.route,
    this.isSpecial = false,
  });
}

class BottomNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String>? onItemTap;

  static const List<BottomNavItem> items = [
    BottomNavItem(
      label: 'Home',
      iconOutlined: Icons.home_outlined,
      iconFilled: Icons.home,
      route: '/home',
    ),
    BottomNavItem(
      label: 'Communities',
      iconOutlined: Icons.group_outlined,
      iconFilled: Icons.group,
      route: '/communities',
    ),
    BottomNavItem(
      label: 'Create',
      iconOutlined: Icons.add,
      iconFilled: Icons.add,
      route: '/create',
      isSpecial: true,
    ),
    BottomNavItem(
      label: 'Explore',
      iconOutlined: Icons.explore_outlined,
      iconFilled: Icons.explore,
      route: '/explore',
    ),
    BottomNavItem(
      label: 'Profile',
      iconOutlined: Icons.person_outline,
      iconFilled: Icons.person,
      route: '/profile',
    ),
  ];

  const BottomNav({
    super.key,
    required this.currentRoute,
    this.onItemTap,
  });

  bool _isActive(BottomNavItem item) {
    return currentRoute == item.route;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A1A).withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade200.withOpacity(0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              final isActive = _isActive(item);
              return Expanded(
                child: _BottomNavItem(
                  item: item,
                  isActive: isActive,
                  isDark: isDark,
                  onTap: () => onItemTap?.call(item.route),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Container
            if (item.isSpecial)
              // Special Create button
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: Colors.white,
                ),
              )
            else
              // Regular icon with filled/outlined variant
              Icon(
                isActive ? item.iconFilled : item.iconOutlined,
                size: isActive ? 24 : 22,
                color: isActive ? activeColor : inactiveColor,
              ),
            const SizedBox(height: 2),
            // Label
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.1,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

