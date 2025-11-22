import 'package:flutter/material.dart';
import '../config/theme.dart';

/**
 * Topbar Component
 * Mobile top bar with logo, burger menu, and action icons
 * Glassmorphic styling matching frontend-web design
 */

class Topbar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onJobsTap;
  final VoidCallback? onMessagesTap;
  final int? unreadNotificationCount;
  final int? unreadMessageCount;

  const Topbar({
    super.key,
    this.onMenuTap,
    this.onNotificationsTap,
    this.onJobsTap,
    this.onMessagesTap,
    this.unreadNotificationCount,
    this.unreadMessageCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A1A).withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
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
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Logo with Stacked Text
            Row(
              children: [
                // U Logo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Upvista Community Text (stacked)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upvista',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Action Icons
            Row(
              children: [
                // Menu Icon - Instagram style minimal
                IconButton(
                  onPressed: onMenuTap,
                  icon: Icon(
                    Icons.density_medium,
                    size: 22,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                // Notifications Icon - Instagram style
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotificationsTap,
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    // Notification Badge
                    if (unreadNotificationCount != null && unreadNotificationCount! > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadNotificationCount! > 9 ? '9+' : '$unreadNotificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Jobs/Briefcase Icon - Instagram style
                IconButton(
                  onPressed: onJobsTap,
                  icon: Icon(
                    Icons.badge_outlined,
                    size: 24,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                // Messages Icon - Instagram style
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onMessagesTap,
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    // Badge for unread messages
                    if (unreadMessageCount != null && unreadMessageCount! > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadMessageCount! > 9 ? '9+' : '$unreadMessageCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

