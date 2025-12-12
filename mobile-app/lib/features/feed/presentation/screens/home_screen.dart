import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_side_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientWarm,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: AppSideMenu(
          onClose: () => _scaffoldKey.currentState?.closeDrawer(),
        ),
        drawerEdgeDragWidth: 0,
        body: SafeArea(
          child: Column(
            children: [
              // Header - Instagram style with transparent overlay
              AppHeader(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                notificationBadge: 2,
                messageBadge: 2,
                onNotificationTap: () {
                  context.push('/notifications');
                },
                onMessageTap: () {
                  context.push('/messages');
                },
              ),
              // Feed content
              Expanded(child: _FeedContent()),
              // Bottom Navigation - Instagram style with transparent overlay
              AppBottomNavigation(
                selectedIndex: _selectedBottomNavIndex,
                onTap: (index) {
                  if (index == 1) {
                    // Navigate to communities screen
                    context.push('/communities');
                  } else if (index == 3) {
                    // Navigate to jobs screen
                    context.push('/jobs');
                  } else if (index == 4) {
                    // Navigate to profile screen
                    context.push('/profile');
                  } else {
                    setState(() {
                      _selectedBottomNavIndex = index;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Header and Footer are now universal components in lib/core/widgets/

class _ActivityTags extends StatelessWidget {
  final List<Map<String, dynamic>> _tags = [
    {
      'icon': Icons.photo_library_outlined,
      'count': 60,
      'label': 'Posts',
      'color': AppColors.accentPrimary,
    },
    {
      'icon': Icons.play_circle_outline,
      'count': 12,
      'label': 'Reels',
      'color': AppColors.accentSecondary,
    },
    {
      'icon': Icons.bar_chart_rounded,
      'count': 5,
      'label': 'Polls',
      'color': const Color(0xFF11998E),
    },
    {
      'icon': Icons.event_outlined,
      'count': 8,
      'label': 'Events',
      'color': AppColors.accentTertiary,
    },
    {
      'icon': Icons.work_outline,
      'count': 23,
      'label': 'Jobs',
      'color': const Color(0xFF667EEA),
    },
    {
      'icon': Icons.science_outlined,
      'count': 3,
      'label': 'Research',
      'color': const Color(0xFFED8F03),
    },
    {
      'icon': Icons.article_outlined,
      'count': 15,
      'label': 'Articles',
      'color': const Color(0xFFF093FB),
    },
    {
      'icon': Icons.groups_outlined,
      'count': 7,
      'label': 'Communities',
      'color': const Color(0xFF38EF7D),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Text(
            'Since your last visit',
            style: AppTextStyles.bodySmall(
              color: AppColors.textSecondary,
              weight: FontWeight.w600,
            ).copyWith(fontSize: 11),
          ),
        ),
        SizedBox(
          height: 32,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              return true;
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];

                return GestureDetector(
                  onTap: () {
                    // TODO: Filter feed by this content type
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tag['icon'], size: 11, color: tag['color']),
                        const SizedBox(width: 3),
                        Text(
                          '${tag['count']}',
                          style: AppTextStyles.bodySmall(
                            color: tag['color'],
                            weight: FontWeight.w600,
                          ).copyWith(fontSize: 10),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          tag['label'],
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                            weight: FontWeight.w400,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StoriesBar extends StatelessWidget {
  final List<Map<String, dynamic>> _stories = [
    {
      'name': 'Your Story',
      'username': 'johndoe',
      'hasStory': false,
      'isYou': true,
      'seen': false,
    },
    {
      'name': 'Sarah J.',
      'username': 'sarahj',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Alex M.',
      'username': 'alexm',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Emma W.',
      'username': 'emmaw',
      'hasStory': true,
      'isYou': false,
      'seen': true,
    },
    {
      'name': 'Mike R.',
      'username': 'miker',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Lisa P.',
      'username': 'lisap',
      'hasStory': true,
      'isYou': false,
      'seen': true,
    },
    {
      'name': 'Tom B.',
      'username': 'tomb',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Nina K.',
      'username': 'ninak',
      'hasStory': true,
      'isYou': false,
      'seen': true,
    },
    {
      'name': 'David L.',
      'username': 'davidl',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Kate S.',
      'username': 'kates',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'James P.',
      'username': 'jamesp',
      'hasStory': true,
      'isYou': false,
      'seen': true,
    },
    {
      'name': 'Amy T.',
      'username': 'amyt',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Chris D.',
      'username': 'chrisd',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Rachel G.',
      'username': 'rachelg',
      'hasStory': true,
      'isYou': false,
      'seen': true,
    },
    {
      'name': 'Ben H.',
      'username': 'benh',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Sophie M.',
      'username': 'sophiem',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
    {
      'name': 'Ryan K.',
      'username': 'ryank',
      'hasStory': true,
      'isYou': false,
      'seen': true,
    },
    {
      'name': 'Olivia N.',
      'username': 'olivian',
      'hasStory': true,
      'isYou': false,
      'seen': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      color: Colors.transparent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Prevent scroll notification from bubbling up
          return true;
        },
        child: ListView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _stories.length,
          itemBuilder: (context, index) {
            final story = _stories[index];
            final isYou = story['isYou'] as bool;
            final hasStory = story['hasStory'] as bool;
            final seen = story['seen'] as bool;

            return GestureDetector(
              onTap: () {
                if (isYou && !hasStory) {
                  // Open create story
                  context.push('/create/story');
                } else {
                  // View story
                  // TODO: Navigate to story viewer
                }
              },
              child: Container(
                width: 74,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    // Story Circle
                    Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: !isYou && hasStory && !seen
                                ? LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      AppColors.accentPrimary,
                                      AppColors.accentSecondary,
                                      AppColors.accentTertiary,
                                    ],
                                  )
                                : null,
                            border: seen
                                ? Border.all(
                                    color: AppColors.glassBorder.withOpacity(
                                      0.3,
                                    ),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.backgroundSecondary.withOpacity(
                                0.3,
                              ),
                              border: Border.all(
                                color: AppColors.backgroundPrimary,
                                width: 3,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isYou
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.accentPrimary,
                                          AppColors.accentSecondary,
                                        ],
                                      )
                                    : null,
                                color: !isYou
                                    ? AppColors.backgroundSecondary.withOpacity(
                                        0.5,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  isYou
                                      ? 'JD'
                                      : story['name']
                                            .toString()
                                            .substring(0, 2)
                                            .toUpperCase(),
                                  style: AppTextStyles.bodyMedium(
                                    color: Colors.white,
                                    weight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Add button for "Your Story"
                        if (isYou && !hasStory)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentPrimary,
                                    AppColors.accentSecondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.backgroundPrimary,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Name
                    Text(
                      story['name'],
                      style: AppTextStyles.bodySmall(
                        weight: FontWeight.w400,
                      ).copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeedContent extends StatefulWidget {
  @override
  State<_FeedContent> createState() => _FeedContentState();
}

class _FeedContentState extends State<_FeedContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppColors.accentPrimary,
      backgroundColor: AppColors.backgroundSecondary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Stories Bar (scrolls away)
          SliverToBoxAdapter(child: _StoriesBar()),
          // Activity Tags (scrolls away)
          SliverToBoxAdapter(child: _ActivityTags()),
          // Feed Content
          SliverList(
            delegate: SliverChildListDelegate([
              // For You Section
              _SectionHeader(title: 'For You'),
              _PostCard(
                username: 'Sarah Johnson',
                userHandle: '@sarahj',
                timeAgo: '2h',
                content:
                    'Just launched my new project! 🚀 Check it out and let me know what you think!',
                imageUrl: null,
                likes: 234,
                comments: 45,
                shares: 12,
              ),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.glassBorder.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              _ReelCard(
                username: 'Alex Martinez',
                userHandle: '@alexm',
                caption: 'Amazing coding tutorial! 💻',
                views: '1.2M',
                likes: '45K',
              ),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.glassBorder.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              _PollCard(
                username: 'Tech Community',
                userHandle: '@techcommunity',
                timeAgo: '5h',
                question: 'What\'s your favorite programming language?',
                options: [
                  {'text': 'Python', 'votes': 45, 'percentage': 0.45},
                  {'text': 'JavaScript', 'votes': 35, 'percentage': 0.35},
                  {'text': 'Dart/Flutter', 'votes': 20, 'percentage': 0.20},
                ],
                totalVotes: 100,
                timeLeft: '2h left',
              ),

              const SizedBox(height: 24),

              // Trending Section
              _SectionHeader(title: 'Trending Now', icon: Icons.whatshot),
              _PostCard(
                username: 'Emma Wilson',
                userHandle: '@emmaw',
                timeAgo: '1h',
                content: 'The future of AI is here! This is incredible 🤖✨',
                imageUrl: 'placeholder',
                likes: 1250,
                comments: 189,
                shares: 67,
              ),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.glassBorder.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              _ArticleCard(
                username: 'Mike Roberts',
                userHandle: '@miker',
                title: 'How to Build a Successful Startup in 2024',
                readTime: '8 min read',
                category: 'Business',
              ),

              const SizedBox(height: 24),

              // From Your Network
              _SectionHeader(
                title: 'From Your Network',
                icon: Icons.people_outline,
              ),
              _PostCard(
                username: 'Lisa Parker',
                userHandle: '@lisap',
                timeAgo: '3h',
                content: 'Beautiful sunset today 🌅',
                imageUrl: 'placeholder',
                likes: 456,
                comments: 67,
                shares: 23,
              ),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.glassBorder.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Opportunities
              _SectionHeader(title: 'Opportunities', icon: Icons.work_outline),
              _JobCard(
                company: 'TechCorp Inc.',
                position: 'Senior Flutter Developer',
                location: 'Remote',
                salary: '\$100K - \$130K',
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const _SectionHeader({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.accentPrimary),
            const SizedBox(width: 8),
          ],
          Text(title, style: AppTextStyles.bodyLarge(weight: FontWeight.bold)),
          const Spacer(),
          Text(
            'See All',
            style: AppTextStyles.bodySmall(
              color: AppColors.accentPrimary,
              weight: FontWeight.w600,
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: AppColors.accentPrimary),
        ],
      ),
    );
  }
}

// Post Card
class _PostCard extends StatefulWidget {
  final String username;
  final String userHandle;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int shares;

  const _PostCard({
    required this.username,
    required this.userHandle,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPrimary,
                        AppColors.accentSecondary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.username.substring(0, 1),
                      style: AppTextStyles.bodyMedium(
                        color: Colors.white,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: AppTextStyles.bodyMedium(
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.userHandle} • ${widget.timeAgo}',
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.content, style: AppTextStyles.bodyMedium()),
          ),

          // Image (if exists)
          if (widget.imageUrl != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPrimary.withOpacity(0.3),
                    AppColors.accentSecondary.withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Interaction Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                _InteractionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(_likeCount),
                  color: _isLiked
                      ? AppColors.accentQuaternary
                      : AppColors.textSecondary,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 20),
                _InteractionButton(
                  icon: Icons.comment_outlined,
                  label: _formatCount(widget.comments),
                  color: AppColors.textSecondary,
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                _InteractionButton(
                  icon: Icons.share_outlined,
                  label: _formatCount(widget.shares),
                  color: AppColors.textSecondary,
                  onTap: () {},
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSaved = !_isSaved;
                    });
                  },
                  child: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall(
              color: color,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Poll Card
class _PollCard extends StatefulWidget {
  final String username;
  final String userHandle;
  final String timeAgo;
  final String question;
  final List<Map<String, dynamic>> options;
  final int totalVotes;
  final String timeLeft;

  const _PollCard({
    required this.username,
    required this.userHandle,
    required this.timeAgo,
    required this.question,
    required this.options,
    required this.totalVotes,
    required this.timeLeft,
  });

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  int? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentSecondary,
                        AppColors.accentTertiary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.username.substring(0, 1),
                      style: AppTextStyles.bodyMedium(
                        color: Colors.white,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: AppTextStyles.bodyMedium(
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.userHandle} • ${widget.timeAgo}',
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),

          // Poll Question
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.accentPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.question,
                    style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Poll Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(widget.options.length, (index) {
                final option = widget.options[index];
                final isSelected = _selectedOption == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentPrimary.withOpacity(0.15)
                          : AppColors.backgroundPrimary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentPrimary
                            : AppColors.glassBorder.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          option['text'],
                          style: AppTextStyles.bodyMedium(
                            weight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(option['percentage'] * 100).toInt()}%',
                          style: AppTextStyles.bodySmall(
                            color: isSelected
                                ? AppColors.accentPrimary
                                : AppColors.textSecondary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Poll Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Text(
                  '${widget.totalVotes} votes',
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.timeLeft,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.glassBorder.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Article Card
class _ArticleCard extends StatelessWidget {
  final String username;
  final String userHandle;
  final String title;
  final String readTime;
  final String category;

  const _ArticleCard({
    required this.username,
    required this.userHandle,
    required this.title,
    required this.readTime,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentTertiary.withOpacity(0.6),
                    AppColors.accentPrimary.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.article_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentTertiary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.accentTertiary,
                        weight: FontWeight.w600,
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        username,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        readTime,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
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

// Reel Card
class _ReelCard extends StatelessWidget {
  final String username;
  final String userHandle;
  final String caption;
  final String views;
  final String likes;

  const _ReelCard({
    required this.username,
    required this.userHandle,
    required this.caption,
    required this.views,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 550,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPrimary.withOpacity(0.5),
            AppColors.accentSecondary.withOpacity(0.7),
            AppColors.accentTertiary.withOpacity(0.5),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Play Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow, size: 56, color: Colors.white),
            ),
          ),

          // Views count overlay (top right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    views,
                    style: AppTextStyles.bodySmall(
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentPrimary,
                              AppColors.accentSecondary,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            username.substring(0, 1),
                            style: AppTextStyles.bodySmall(
                              color: Colors.white,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        username,
                        style: AppTextStyles.bodyMedium(
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caption,
                    style: AppTextStyles.bodySmall(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$likes likes',
                        style: AppTextStyles.bodySmall(
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Job Card
class _JobCard extends StatelessWidget {
  final String company;
  final String position;
  final String location;
  final String salary;

  const _JobCard({
    required this.company,
    required this.position,
    required this.location,
    required this.salary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withOpacity(0.2),
            const Color(0xFF764BA2).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: const Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position,
                      style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                    ),
                    Text(
                      company,
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _JobChip(icon: Icons.location_on_outlined, text: location),
              _JobChip(icon: Icons.attach_money, text: salary),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'View Job',
                style: AppTextStyles.bodyMedium(
                  color: Colors.white,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _JobChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// Header, Footer, and Side Menu are now universal components in lib/core/widgets/
