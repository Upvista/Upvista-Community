import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PageController _pageController = PageController();
  int _selectedBottomNavIndex = 3; // Explore tab selected

  // Only reels for explore screen
  final List<Map<String, dynamic>> _reels = [
    {
      'id': '1',
      'username': 'Sarah Johnson',
      'userHandle': '@sarahj',
      'caption': 'Check out this amazing Flutter animation! 🚀 #flutter #mobile',
      'likes': 1250,
      'comments': 89,
      'shares': 23,
      'views': '12.5K',
      'isLiked': false,
      'isFollowing': false,
    },
    {
      'id': '2',
      'username': 'Emma Wilson',
      'userHandle': '@emmaw',
      'caption': 'UI/UX design tips for mobile apps 📱✨',
      'likes': 890,
      'comments': 67,
      'shares': 18,
      'views': '8.2K',
      'isLiked': true,
      'isFollowing': true,
    },
    {
      'id': '3',
      'username': 'Jessica Brown',
      'userHandle': '@jessicab',
      'caption': 'Behind the scenes of my latest project 🎬',
      'likes': 2100,
      'comments': 156,
      'shares': 45,
      'views': '25.3K',
      'isLiked': false,
      'isFollowing': false,
    },
    {
      'id': '4',
      'username': 'Mike Chen',
      'userHandle': '@mikec',
      'caption': 'Coding session live! Join me 🎥',
      'likes': 567,
      'comments': 34,
      'shares': 12,
      'views': '5.2K',
      'isLiked': false,
      'isFollowing': false,
    },
    {
      'id': '5',
      'username': 'Alex Turner',
      'userHandle': '@alext',
      'caption': 'New project reveal coming soon! 💫',
      'likes': 1890,
      'comments': 123,
      'shares': 56,
      'views': '18.7K',
      'isLiked': true,
      'isFollowing': true,
    },
    {
      'id': '6',
      'username': 'David Lee',
      'userHandle': '@davidl',
      'caption': 'Quick tutorial on Flutter animations 🎨',
      'likes': 2340,
      'comments': 189,
      'shares': 78,
      'views': '32.1K',
      'isLiked': false,
      'isFollowing': false,
    },
    {
      'id': '7',
      'username': 'Ryan Kim',
      'userHandle': '@ryank',
      'caption': 'Day in the life of a developer 📱',
      'likes': 1456,
      'comments': 98,
      'shares': 34,
      'views': '15.3K',
      'isLiked': false,
      'isFollowing': false,
    },
    {
      'id': '8',
      'username': 'Sophie Martinez',
      'userHandle': '@sophiem',
      'caption': 'Design process breakdown 🎯',
      'likes': 987,
      'comments': 67,
      'shares': 23,
      'views': '9.8K',
      'isLiked': true,
      'isFollowing': true,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientWarm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Reels Content
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final reel = _reels[index];
                return _ExploreReelCard(
                  reel: reel,
                  onLike: () => _handleLike(index),
                  onComment: () => _handleComment(reel),
                  onShare: () => _handleShare(reel),
                  onMore: () => _handleMore(reel),
                  onFollow: () => _handleFollow(index),
                  onProfileTap: () => _handleProfileTap(reel),
                );
              },
            ),
            // Bottom Navigation Overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: _selectedBottomNavIndex,
                onTap: (index) {
                  if (index == 0) {
                    context.go('/home');
                  } else if (index == 1) {
                    context.push('/communities');
                  } else if (index == 3) {
                    // Already on explore
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
          ],
        ),
      ),
    );
  }

  void _handleLike(int index) {
    setState(() {
      final reel = _reels[index];
      reel['isLiked'] = !(reel['isLiked'] as bool);
      if (reel['isLiked'] as bool) {
        reel['likes'] = (reel['likes'] as int) + 1;
      } else {
        reel['likes'] = (reel['likes'] as int) - 1;
      }
    });
  }

  void _handleComment(Map<String, dynamic> reel) {
    // TODO: Navigate to comments screen
  }

  void _handleShare(Map<String, dynamic> reel) {
    // TODO: Show share options
  }

  void _handleMore(Map<String, dynamic> reel) {
    // TODO: Show more options
  }

  void _handleFollow(int index) {
    setState(() {
      final reel = _reels[index];
      reel['isFollowing'] = !(reel['isFollowing'] as bool);
    });
  }

  void _handleProfileTap(Map<String, dynamic> reel) {
    // TODO: Navigate to profile
  }
}

// Explore Reel Card - Instagram Style
class _ExploreReelCard extends StatelessWidget {
  final Map<String, dynamic> reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final VoidCallback onFollow;
  final VoidCallback onProfileTap;

  const _ExploreReelCard({
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onMore,
    required this.onFollow,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = reel['isLiked'] as bool;
    final isFollowing = reel['isFollowing'] as bool;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Video/Content Area - Full Screen Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentPrimary.withOpacity(0.6),
                    AppColors.accentSecondary.withOpacity(0.8),
                    AppColors.accentTertiary.withOpacity(0.6),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 72,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),

          // Right Side Actions - Instagram Style
          Positioned(
            right: 12,
            bottom: 0,
            top: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(),
                _ReelActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(reel['likes'] as int),
                  isActive: isLiked,
                  onTap: onLike,
                ),
                const SizedBox(height: 20),
                _ReelActionButton(
                  icon: Icons.comment_outlined,
                  label: _formatCount(reel['comments'] as int),
                  onTap: onComment,
                ),
                const SizedBox(height: 20),
                _ReelActionButton(
                  icon: Icons.send_outlined,
                  label: _formatCount(reel['shares'] as int),
                  onTap: onShare,
                ),
                const SizedBox(height: 20),
                _ReelActionButton(
                  icon: Icons.more_vert,
                  onTap: onMore,
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
              ],
            ),
          ),

          // Bottom Info Section - Instagram Style
          Positioned(
            left: 0,
            right: 70, // Space for action buttons
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 80,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Row with Follow Button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Container(
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
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (reel['username'] as String).substring(0, 1),
                              style: AppTextStyles.bodySmall(
                                color: Colors.white,
                                weight: FontWeight.bold,
                              ).copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onProfileTap,
                          child: Text(
                            reel['userHandle'] as String,
                            style: AppTextStyles.bodyMedium(
                              color: Colors.white,
                              weight: FontWeight.w600,
                            ).copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onFollow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isFollowing
                                ? Colors.transparent
                                : Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: AppTextStyles.bodySmall(
                              color: isFollowing ? Colors.white : Colors.black,
                              weight: FontWeight.w600,
                            ).copyWith(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Caption
                  Text(
                    reel['caption'] as String,
                    style: AppTextStyles.bodyMedium(
                      color: Colors.white,
                    ).copyWith(
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Views
                  Text(
                    '${reel['views']} views',
                    style: AppTextStyles.bodySmall(
                      color: Colors.white.withOpacity(0.7),
                    ).copyWith(fontSize: 11),
                  ),
                ],
              ),
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

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.red : Colors.white,
            size: 28,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: AppTextStyles.bodySmall(
                color: Colors.white,
                weight: FontWeight.w600,
              ).copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
