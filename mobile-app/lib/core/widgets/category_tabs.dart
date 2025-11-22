import 'package:flutter/material.dart';
import '../config/theme.dart';

/**
 * Category Tabs Component
 * Horizontal scrollable category filter tabs
 * Matching frontend-web design
 */

class CategoryTab {
  final String id;
  final String label;

  const CategoryTab({
    required this.id,
    required this.label,
  });
}

class CategoryTabs extends StatelessWidget {
  final List<CategoryTab> tabs;
  final String activeTabId;
  final ValueChanged<String>? onTabChanged;

  static const List<CategoryTab> defaultTabs = [
    CategoryTab(id: 'all', label: 'All'),
    CategoryTab(id: 'communities', label: 'Communities'),
    CategoryTab(id: 'research', label: 'Research'),
    CategoryTab(id: 'posts', label: 'Posts'),
  ];

  const CategoryTabs({
    super.key,
    this.tabs = defaultTabs,
    required this.activeTabId,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = activeTabId == tab.id;

          return Padding(
            padding: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
            child: _CategoryTabButton(
              tab: tab,
              isActive: isActive,
              isDark: isDark,
              onTap: () => onTabChanged?.call(tab.id),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTabButton extends StatelessWidget {
  final CategoryTab tab;
  final bool isActive;
  final bool isDark;
  final VoidCallback? onTap;

  const _CategoryTabButton({
    required this.tab,
    required this.isActive,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor
              : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            tab.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : isDark
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

