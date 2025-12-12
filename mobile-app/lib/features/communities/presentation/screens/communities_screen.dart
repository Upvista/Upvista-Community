import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  int _selectedBottomNavIndex = 1; // Communities tab selected

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientWarm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              AppHeader(
                onMenuTap: () {
                  // TODO: Open side menu
                },
                notificationBadge: 0,
                messageBadge: 0,
                onNotificationTap: () {
                  // TODO: Navigate to notifications
                },
                onMessageTap: () {
                  // TODO: Navigate to messages
                },
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  200, // Account for header, tabs, and bottom nav
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 32,
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                  left: 32,
                  right: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentPrimary.withOpacity(0.2),
                            AppColors.accentSecondary.withOpacity(0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 40,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Communities',
                      style: AppTextStyles.headlineSmall(weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scheduled for the next phase',
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Currently under development',
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: _selectedBottomNavIndex,
          onTap: (index) {
            if (index == 0) {
              // Home - navigate to home screen
              context.go('/home');
            } else if (index == 4) {
              // Profile - navigate to profile screen
              context.push('/profile');
            } else {
              setState(() {
                _selectedBottomNavIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}

