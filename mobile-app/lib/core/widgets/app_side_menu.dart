import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppSideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const AppSideMenu({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundSecondary.withOpacity(0.95),
      width: 280,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // Compact Header - same color as sidebar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.glassBorder.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Logo placeholder
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.accentPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Menu',
                      style: AppTextStyles.headlineSmall(
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Compact Menu items - no scrolling needed
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _MenuTile(
                    icon: Icons.search,
                    title: 'Search',
                    onTap: () {
                      onClose();
                      context.push('/search');
                    },
                  ),
                  _MenuTile(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      onClose();
                      context.push('/settings');
                    },
                  ),
                  _MenuTile(
                    icon: Icons.timeline,
                    title: 'Your Activity',
                    onTap: () {
                      onClose();
                      // TODO: Navigate to activity
                    },
                  ),
                  _MenuTile(
                    icon: Icons.bookmark,
                    title: 'Saved',
                    onTap: () {
                      onClose();
                      // TODO: Navigate to saved
                    },
                  ),
                  _MenuTile(
                    icon: Icons.attach_money,
                    title: 'Your Earnings',
                    onTap: () {
                      onClose();
                      // TODO: Navigate to earnings
                    },
                  ),
                  _MenuTile(
                    icon: Icons.bar_chart,
                    title: 'Account Summary',
                    onTap: () {
                      onClose();
                      // TODO: Navigate to account summary
                    },
                  ),
                  _MenuTile(
                    icon: Icons.switch_account,
                    title: 'Switch Profiles',
                    onTap: () {
                      onClose();
                      // TODO: Switch profiles
                    },
                  ),
                  _MenuTile(
                    icon: Icons.language,
                    title: 'Switch Language',
                    onTap: () {
                      onClose();
                      // TODO: Switch language
                    },
                  ),
                  Divider(
                    color: AppColors.glassBorder,
                    thickness: 0.5,
                    height: 16,
                  ),
                  _MenuTile(
                    icon: Icons.flag,
                    title: 'Report a Problem',
                    onTap: () {
                      onClose();
                      // TODO: Report problem
                    },
                  ),
                  _MenuTile(
                    icon: Icons.info,
                    title: 'About',
                    onTap: () {
                      onClose();
                      // TODO: Navigate to about
                    },
                  ),
                  Divider(
                    color: AppColors.glassBorder,
                    thickness: 0.5,
                    height: 16,
                  ),
                  _MenuTile(
                    icon: Icons.exit_to_app,
                    title: 'Logout',
                    isLogout: true,
                    onTap: () {
                      onClose();
                      // TODO: Handle logout
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: isLogout ? AppColors.accentQuaternary : AppColors.textPrimary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? AppColors.accentQuaternary : AppColors.textPrimary,
          fontSize: 14,
          fontWeight: isLogout ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minLeadingWidth: 32,
    );
  }
}

