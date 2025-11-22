import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/topbar.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/category_tabs.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/**
 * Home Feed Screen
 * Main feed page with category filters, topbar, and bottom navigation
 * Matching frontend-web design
 */

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  String _activeCategory = 'all';

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.logout();
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Topbar
            Topbar(
              unreadNotificationCount: 2, // TODO: Get from state management
              unreadMessageCount: 2, // TODO: Get from state management
              onMenuTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Logout'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _handleLogout();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Category Tabs
            CategoryTabs(
              activeTabId: _activeCategory,
              onTabChanged: (categoryId) {
                setState(() {
                  _activeCategory = categoryId;
                });
              },
            ),
            // Feed Content (empty for now)
            Expanded(
              child: Center(
                child: Text(
                  'Feed content coming soon',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNav(
        currentRoute: '/home',
        onItemTap: (route) {
          // TODO: Handle navigation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigating to $route'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
