import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBottomNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientWarm,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                notificationBadge: 2,
                messageBadge: 2,
                onNotificationTap: () {
                  // Already on notifications
                },
                onJobTap: () {
                  // TODO: Navigate to jobs
                },
                onMessageTap: () {
                  context.push('/messages');
                },
              ),
              // Notifications Header - Instagram style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.glassBorder.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Notifications',
                      style: AppTextStyles.headlineMedium(
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Bar - Instagram style
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.bodyMedium(weight: FontWeight.w600),
                  unselectedLabelStyle: AppTextStyles.bodyMedium(),
                  indicator: BoxDecoration(
                    color: AppColors.backgroundPrimary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Follow Requests'),
                  ],
                ),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  children: [
                    _AllNotificationsTab(),
                    _RequestsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: _selectedBottomNavIndex,
          onTap: (index) {
            if (index == 0) {
              context.go('/home');
            } else if (index == 4) {
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

// All Notifications Tab - Instagram style
class _AllNotificationsTab extends StatelessWidget {
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'like',
      'user': 'Sarah Johnson',
      'username': '@sarahj',
      'action': 'liked your post.',
      'time': '2m',
      'isRead': false,
      'hasImage': true,
    },
    {
      'type': 'comment',
      'user': 'Mike Chen',
      'username': '@mikec',
      'action': 'commented: Great work! This is amazing 🔥',
      'time': '15m',
      'isRead': false,
      'hasImage': true,
    },
    {
      'type': 'follow',
      'user': 'Emma Wilson',
      'username': '@emmaw',
      'action': 'started following you.',
      'time': '1h',
      'isRead': true,
      'hasImage': false,
      'hasButton': true,
    },
    {
      'type': 'mention',
      'user': 'Alex Turner',
      'username': '@alext',
      'action': 'mentioned you in a comment: @johndoe check this out!',
      'time': '2h',
      'isRead': true,
      'hasImage': true,
    },
    {
      'type': 'collaboration',
      'user': 'Tech Startup',
      'username': '@techstartup',
      'action': 'invited you to collaborate on a project.',
      'time': '3h',
      'isRead': true,
      'hasImage': false,
      'hasButton': true,
    },
    {
      'type': 'like',
      'user': 'David Lee',
      'username': '@davidl',
      'action': 'liked your comment.',
      'time': '5h',
      'isRead': true,
      'hasImage': false,
    },
    {
      'type': 'follow_request',
      'user': 'Jessica Brown',
      'username': '@jessicab',
      'action': 'requested to follow you.',
      'time': '1d',
      'isRead': true,
      'hasImage': false,
      'hasButton': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.glassBorder.withOpacity(0.1),
        indent: 68,
      ),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _NotificationItem(notification: notification);
      },
    );
  }
}

// Requests Tab
class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No requests',
            style: AppTextStyles.bodyLarge(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Notification Item - Instagram style (compact, no card)
class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] as bool;
    final hasImage = notification['hasImage'] as bool;
    final hasButton = notification['hasButton'] as bool? ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showNotificationOptions(context, notification);
        },
        onLongPress: () {
          _showNotificationOptions(context, notification);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isRead
              ? Colors.transparent
              : AppColors.backgroundSecondary.withOpacity(0.2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.accentPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: notification['user'],
                            style: AppTextStyles.bodyMedium(
                              weight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' ${notification['action']}',
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: ' ${notification['time']}',
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasButton) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: Handle follow/accept
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                side: BorderSide(
                                  color: AppColors.accentPrimary,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                notification['type'] == 'follow_request'
                                    ? 'Confirm'
                                    : 'Follow Back',
                                style: AppTextStyles.bodySmall(
                                  color: AppColors.accentPrimary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: Handle delete/ignore
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                side: BorderSide(
                                  color: AppColors.textTertiary,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                notification['type'] == 'follow_request'
                                    ? 'Delete'
                                    : 'Remove',
                                style: AppTextStyles.bodySmall(
                                  color: AppColors.textSecondary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPrimary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.image,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ],
              if (!isRead && !hasButton) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationOptions(
      BuildContext context, Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _OptionTile(
                icon: Icons.visibility_off,
                title: 'Hide this notification',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Hide notification
                },
              ),
              _OptionTile(
                icon: Icons.person_off,
                title: 'Turn off notifications from ${notification['user']}',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Mute user notifications
                },
              ),
              _OptionTile(
                icon: Icons.block,
                title: 'Block ${notification['user']}',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Block user
                },
                isDestructive: true,
              ),
              _OptionTile(
                icon: Icons.report,
                title: 'Report',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Report
                },
                isDestructive: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.accentQuaternary : AppColors.textPrimary,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(
          color: isDestructive ? AppColors.accentQuaternary : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

