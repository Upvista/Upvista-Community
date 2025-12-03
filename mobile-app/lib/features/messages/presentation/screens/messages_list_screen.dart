import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock conversation data
  final List<Map<String, dynamic>> _conversations = [
    {
      'userId': 'sarahj',
      'name': 'Sarah Johnson',
      'username': '@sarahj',
      'avatar': null,
      'lastMessage': 'Hey! How are you doing?',
      'timestamp': '2m',
      'unreadCount': 2,
      'isOnline': true,
    },
    {
      'userId': 'michaelc',
      'name': 'Michael Chen',
      'username': '@michaelc',
      'avatar': null,
      'lastMessage': 'Thanks for the help!',
      'timestamp': '1h',
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'userId': 'emmaw',
      'name': 'Emma Wilson',
      'username': '@emmaw',
      'avatar': null,
      'lastMessage': 'See you tomorrow!',
      'timestamp': '3h',
      'unreadCount': 1,
      'isOnline': true,
    },
    {
      'userId': 'davidb',
      'name': 'David Brown',
      'username': '@davidb',
      'avatar': null,
      'lastMessage': 'Great work on the project!',
      'timestamp': '5h',
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'userId': 'lisaa',
      'name': 'Lisa Anderson',
      'username': '@lisaa',
      'avatar': null,
      'lastMessage': 'Can we schedule a meeting?',
      'timestamp': '1d',
      'unreadCount': 3,
      'isOnline': true,
    },
    {
      'userId': 'jamest',
      'name': 'James Taylor',
      'username': '@jamest',
      'avatar': null,
      'lastMessage': 'Looking forward to working together!',
      'timestamp': '2d',
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'userId': 'oliviam',
      'name': 'Olivia Martinez',
      'username': '@oliviam',
      'avatar': null,
      'lastMessage': 'The design looks amazing!',
      'timestamp': '3d',
      'unreadCount': 1,
      'isOnline': true,
    },
    {
      'userId': 'robertl',
      'name': 'Robert Lee',
      'username': '@robertl',
      'avatar': null,
      'lastMessage': 'Thanks for the feedback',
      'timestamp': '4d',
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'userId': 'sophiag',
      'name': 'Sophia Garcia',
      'username': '@sophiag',
      'avatar': null,
      'lastMessage': 'When can we meet?',
      'timestamp': '5d',
      'unreadCount': 2,
      'isOnline': true,
    },
    {
      'userId': 'williamd',
      'name': 'William Davis',
      'username': '@williamd',
      'avatar': null,
      'lastMessage': 'Great job on the presentation!',
      'timestamp': '1w',
      'unreadCount': 0,
      'isOnline': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientWarm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header - Instagram style
              _MessagesHeader(
                onBack: () => context.pop(),
                onMenuTap: () {
                  // TODO: Show messages menu
                },
              ),
              // Conversations list with search bar
              Expanded(
                child: _ConversationsList(
                  conversations: _conversations,
                  searchController: _searchController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMenuTap;

  const _MessagesHeader({
    required this.onBack,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              // Back arrow
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  'Messages',
                  style: AppTextStyles.headlineSmall(
                    weight: FontWeight.bold,
                  ),
                ),
              ),
              // Menu dots
              GestureDetector(
                onTap: onMenuTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.glassBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium(),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: AppTextStyles.bodyMedium(
              color: AppColors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            filled: false,
          ),
        ),
      ),
    );
  }
}

class _ConversationsList extends StatelessWidget {
  final List<Map<String, dynamic>> conversations;
  final TextEditingController searchController;

  const _ConversationsList({
    required this.conversations,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: AppTextStyles.headlineSmall(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation',
              style: AppTextStyles.bodyMedium(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // Search bar (scrolls away)
        SliverToBoxAdapter(
          child: _SearchBar(controller: searchController),
        ),
        // Conversations list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                return Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.glassBorder.withOpacity(0.1),
                  indent: 80,
                );
              }
              
              final conversationIndex = index ~/ 2;
        final conversation = conversations[conversationIndex];
        return _ConversationTile(
          name: conversation['name'] as String,
          username: conversation['username'] as String,
          lastMessage: conversation['lastMessage'] as String,
          timestamp: conversation['timestamp'] as String,
          unreadCount: conversation['unreadCount'] as int,
          isOnline: conversation['isOnline'] as bool,
          onTap: () {
            // Navigate to chat screen
            context.push(
              '/chat/${conversation['userId']}',
              extra: {
                'userName': conversation['name'],
                'userUsername': conversation['username'],
                'isOnline': conversation['isOnline'],
              },
            );
          },
        );
      },
      childCount: conversations.length * 2 - 1,
    ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String username;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.username,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPrimary.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.glassBorder.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.accentPrimary,
                    size: 28,
                  ),
                ),
                // Online indicator
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundPrimary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyLarge(
                            weight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timestamp,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: AppTextStyles.bodyMedium(
                            color: unreadCount > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            weight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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

