import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedBottomNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
                  context.push('/notifications');
                },
                onMessageTap: () {
                  context.push('/messages');
                },
              ),
              // Search Header - Professional underlined style
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: AppTextStyles.bodyLarge(),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search users, posts, communities...',
                          hintStyle: AppTextStyles.bodyLarge(
                            color: AppColors.textTertiary,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: AppColors.textSecondary,
                                    size: 22,
                                  ),
                                )
                              : null,
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.glassBorder.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.glassBorder.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.glassBorder.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Bar
              Container(
                height: 44,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.bodySmall(weight: FontWeight.w600),
                  unselectedLabelStyle: AppTextStyles.bodySmall(),
                  indicator: BoxDecoration(
                    color: AppColors.backgroundPrimary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Users'),
                    Tab(text: 'Posts'),
                    Tab(text: 'Communities'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tab Content
              Expanded(
                child: _searchQuery.isEmpty
                    ? _RecentSearches()
                    : TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        children: [
                          _AllResultsTab(searchQuery: _searchQuery),
                          _UsersTab(searchQuery: _searchQuery),
                          _PostsTab(searchQuery: _searchQuery),
                          _CommunitiesTab(searchQuery: _searchQuery),
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
            } else if (index == 1) {
              context.push('/communities');
            } else if (index == 3) {
              context.push('/jobs');
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

// Recent Searches
class _RecentSearches extends StatelessWidget {
  final List<Map<String, dynamic>> _recentSearches = [
    {'type': 'user', 'name': 'Sarah Johnson', 'username': '@sarahj'},
    {'type': 'user', 'name': 'Mike Chen', 'username': '@mikec'},
    {'type': 'community', 'name': 'Flutter Developers', 'members': '12.5K'},
    {'type': 'post', 'content': 'Amazing new project launch!'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                // TODO: Clear recent searches
              },
              child: Text(
                'Clear All',
                style: AppTextStyles.bodySmall(
                  color: AppColors.accentPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSearches.map((search) => _RecentSearchItem(search: search)),
      ],
    );
  }
}

class _RecentSearchItem extends StatelessWidget {
  final Map<String, dynamic> search;

  const _RecentSearchItem({required this.search});

  IconData _getIcon() {
    switch (search['type']) {
      case 'user':
        return Icons.person;
      case 'community':
        return Icons.people;
      case 'post':
        return Icons.article;
      default:
        return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getIcon(),
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
      title: Text(
        search['name'] ?? search['content'] ?? '',
        style: AppTextStyles.bodyMedium(weight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: search['username'] != null
          ? Text(
              search['username'],
              style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
            )
          : search['members'] != null
              ? Text(
                  '${search['members']} members',
                  style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
                )
              : null,
      trailing: IconButton(
        icon: Icon(Icons.close, color: AppColors.textTertiary, size: 20),
        onPressed: () {
          // TODO: Remove from recent
        },
      ),
      onTap: () {
        // TODO: Navigate to result
      },
    );
  }
}

// All Results Tab
class _AllResultsTab extends StatelessWidget {
  final String searchQuery;

  const _AllResultsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _SectionHeader(title: 'Users'),
        _UserResultItem(
          name: 'Sarah Johnson',
          username: '@sarahj',
          isVerified: true,
        ),
        _UserResultItem(name: 'Mike Chen', username: '@mikec'),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Communities'),
        _CommunityResultItem(
          name: 'Flutter Developers',
          members: '12.5K',
          icon: Icons.code,
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Posts'),
        _PostResultItem(
          author: 'Emma Wilson',
          username: '@emmaw',
          content: 'Just launched my new project! Check it out 🚀',
          likes: '234',
          time: '2h ago',
        ),
      ],
    );
  }
}

// Users Tab
class _UsersTab extends StatelessWidget {
  final String searchQuery;

  const _UsersTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _UserResultItem(
          name: 'Sarah Johnson',
          username: '@sarahj',
          isVerified: true,
          bio: 'Product Designer | Tech Enthusiast',
        ),
        _UserResultItem(
          name: 'Mike Chen',
          username: '@mikec',
          bio: 'Full Stack Developer',
        ),
        _UserResultItem(
          name: 'Emma Wilson',
          username: '@emmaw',
          isVerified: true,
          bio: 'Entrepreneur | Startup Founder',
        ),
      ],
    );
  }
}

// Posts Tab
class _PostsTab extends StatelessWidget {
  final String searchQuery;

  const _PostsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _PostResultItem(
          author: 'Emma Wilson',
          username: '@emmaw',
          content: 'Just launched my new project! Check it out 🚀',
          likes: '234',
          time: '2h ago',
          hasImage: true,
        ),
        _PostResultItem(
          author: 'Alex Turner',
          username: '@alext',
          content: 'Great article about Flutter development',
          likes: '156',
          time: '5h ago',
        ),
      ],
    );
  }
}

// Communities Tab
class _CommunitiesTab extends StatelessWidget {
  final String searchQuery;

  const _CommunitiesTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              style: AppTextStyles.headlineSmall(
                weight: FontWeight.bold,
              ),
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
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
      ),
    );
  }
}

// User Result Item
class _UserResultItem extends StatelessWidget {
  final String name;
  final String username;
  final bool isVerified;
  final String? bio;

  const _UserResultItem({
    required this.name,
    required this.username,
    this.isVerified = false,
    this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(0),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: AppColors.accentPrimary,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.verified,
                color: AppColors.success,
                size: 16,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username,
              style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
            ),
            if (bio != null) ...[
              const SizedBox(height: 4),
              Text(
                bio!,
                style: AppTextStyles.bodySmall(color: AppColors.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () {
            // TODO: Follow user
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            side: BorderSide(color: AppColors.accentPrimary, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Follow',
            style: AppTextStyles.bodySmall(
              color: AppColors.accentPrimary,
              weight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to profile
        },
      ),
    );
  }
}

// Community Result Item
class _CommunityResultItem extends StatelessWidget {
  final String name;
  final String members;
  final IconData icon;
  final String? description;

  const _CommunityResultItem({
    required this.name,
    required this.members,
    required this.icon,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(0),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.accentPrimary,
            size: 28,
          ),
        ),
        title: Text(
          name,
          style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$members members',
              style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: AppTextStyles.bodySmall(color: AppColors.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () {
            // TODO: Join community
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            side: BorderSide(color: AppColors.accentPrimary, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Join',
            style: AppTextStyles.bodySmall(
              color: AppColors.accentPrimary,
              weight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to community
        },
      ),
    );
  }
}

// Post Result Item
class _PostResultItem extends StatelessWidget {
  final String author;
  final String username;
  final String content;
  final String likes;
  final String time;
  final bool hasImage;

  const _PostResultItem({
    required this.author,
    required this.username,
    required this.content,
    required this.likes,
    required this.time,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: AppTextStyles.bodySmall(weight: FontWeight.w600),
                    ),
                    Text(
                      username,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: AppTextStyles.bodySmall(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextStyles.bodyMedium(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasImage) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: AppColors.textTertiary,
                  size: 40,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                likes,
                style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.comment_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '45',
                style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

