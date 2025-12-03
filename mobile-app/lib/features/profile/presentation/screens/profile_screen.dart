import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_side_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTag = 'Founder'; // Default tag
  int _selectedBottomNavIndex = 4; // Profile tab selected
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 3,
      animationDuration: const Duration(milliseconds: 300),
    ); // Start with About tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTagSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TagSelectorSheet(
        selectedTag: _selectedTag,
        onTagSelected: (tag) {
          setState(() {
            _selectedTag = tag;
          });
          Navigator.pop(context);
        },
      ),
    );
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
                onJobTap: () {
                  // TODO: Navigate to jobs
                },
                onMessageTap: () {
                  context.push('/messages');
                },
              ),
              Expanded(
                child: NestedScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // Profile Header
                      SliverToBoxAdapter(
                        child: _ProfileHeader(
                          selectedTag: _selectedTag,
                          onTagTap: () => _showTagSelector(context),
                        ),
                      ),
                      // Stats Section
                      SliverToBoxAdapter(child: _StatsSection()),
                      // Details Section
                      SliverToBoxAdapter(child: _DetailsSection()),
                      // Tab Bar
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.accentPrimary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.accentPrimary,
                            indicatorWeight: 2,
                            tabs: const [
                              Tab(icon: Icon(Icons.grid_on), text: 'Feed'),
                              Tab(
                                icon: Icon(Icons.people),
                                text: 'Communities',
                              ),
                              Tab(icon: Icon(Icons.work), text: 'Projects'),
                              Tab(
                                icon: Icon(Icons.info_outline),
                                text: 'About',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      _FeedTab(),
                      _CommunitiesTab(),
                      _ProjectsTab(),
                      _AboutTab(),
                    ],
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
            } else if (index != 4) {
              // Other tabs - update state
              setState(() {
                _selectedBottomNavIndex = index;
              });
            }
            // Index 4 (Profile) stays on current screen
          },
        ),
        drawer: AppSideMenu(
          onClose: () => _scaffoldKey.currentState?.closeDrawer(),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String selectedTag;
  final VoidCallback onTagTap;

  const _ProfileHeader({required this.selectedTag, required this.onTagTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPrimary,
                      AppColors.accentSecondary,
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.accentPrimary.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Icon(Icons.person, color: Colors.white, size: 50),
              ),
              // Verified badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundPrimary,
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.verified, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name with verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'John Doe',
                style: AppTextStyles.headlineMedium(weight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Icon(Icons.verified, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@johndoe',
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          // Public/Private badge and Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Public badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public,
                      color: AppColors.accentPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Public',
                      style: AppTextStyles.bodySmall(
                        color: AppColors.accentPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tag selector
              GestureDetector(
                onTap: onTagTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPrimary.withOpacity(0.2),
                        AppColors.accentSecondary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentPrimary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: AppColors.accentPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedTag,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.accentPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Edit Profile and Share Profile Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to edit profile
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accentPrimary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.accentPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Share profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: AppTextStyles.bodyMedium(
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bio
          Text(
            'Passionate developer | Tech enthusiast | Building the future one line of code at a time 🚀',
            style: AppTextStyles.bodyMedium(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Posts', value: '124'),
          _StatItem(label: 'Followers', value: '2.5K'),
          _StatItem(label: 'Following', value: '342'),
          _StatItem(label: 'Projects', value: '18'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall(weight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _DetailsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age and Gender in one row
          Row(
            children: [
              Icon(
                Icons.cake_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '18 years old',
                style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
              ),
              const SizedBox(width: 16),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Male',
                style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location
          _DetailRow(
            icon: Icons.location_on_outlined,
            text: 'San Francisco, CA',
          ),
          const SizedBox(height: 12),
          // Website
          _DetailRow(icon: Icons.language, text: 'johndoe.com', isLink: true),
          const SizedBox(height: 16),
          // Social Links - Official platform icons
          Row(
            children: [
              Icon(
                Icons.share_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Social:',
                style: AppTextStyles.bodySmall(
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              _SocialIconButton(
                icon: FontAwesomeIcons.linkedin,
                label: 'LinkedIn',
                color: const Color(0xFF2D9CDB),
              ),
              const SizedBox(width: 6),
              _SocialIconButton(
                icon: FontAwesomeIcons.github,
                label: 'GitHub',
                color: const Color(0xFFBBBBBB),
              ),
              const SizedBox(width: 6),
              _SocialIconButton(
                icon: FontAwesomeIcons.xTwitter,
                label: 'Twitter',
                color: const Color(0xFFE8E8E8),
              ),
              const SizedBox(width: 6),
              _SocialIconButton(
                icon: FontAwesomeIcons.instagram,
                label: 'Instagram',
                color: const Color(0xFFFF6B9D),
              ),
              const SizedBox(width: 6),
              _SocialIconButton(
                icon: FontAwesomeIcons.facebook,
                label: 'Facebook',
                color: const Color(0xFF4A9FF5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLink;

  const _DetailRow({
    required this.icon,
    required this.text,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium(
              color: isLink ? AppColors.accentPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SocialIconButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Open social link
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(child: FaIcon(icon, color: color, size: 18)),
      ),
    );
  }
}

// Tag Selector Sheet
class _TagSelectorSheet extends StatefulWidget {
  final String selectedTag;
  final Function(String) onTagSelected;

  const _TagSelectorSheet({
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  State<_TagSelectorSheet> createState() => _TagSelectorSheetState();
}

class _TagSelectorSheetState extends State<_TagSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController();
  String _searchQuery = '';
  int _selectedIndex = 0;

  final List<String> _commonTags = [
    'Search...',
    'Founder',
    'CEO',
    'CTO',
    'Student',
    'Developer',
    'Designer',
    'Engineer',
    'Entrepreneur',
    'Freelancer',
    'Consultant',
    'Manager',
    'Director',
    'Product Manager',
    'Project Manager',
    'Team Lead',
    'Software Engineer',
    'Full Stack Developer',
    'Frontend Developer',
    'Backend Developer',
    'Mobile Developer',
    'UI/UX Designer',
    'Graphic Designer',
    'Data Scientist',
    'Data Analyst',
    'DevOps Engineer',
    'Cloud Architect',
    'Security Engineer',
    'Marketing Manager',
    'Sales Manager',
    'Business Analyst',
    'Content Creator',
    'Influencer',
    'Blogger',
    'Writer',
    'Photographer',
    'Videographer',
    'Artist',
    'Musician',
    'Teacher',
    'Professor',
    'Researcher',
    'Scientist',
    'Doctor',
    'Lawyer',
    'Accountant',
    'Investor',
    'Mentor',
    'Coach',
    'Advisor',
    'Volunteer',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _commonTags.indexOf(widget.selectedTag);
    if (_selectedIndex == -1) _selectedIndex = 1; // Default to Founder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpToItem(_selectedIndex);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _filteredTags {
    if (_searchQuery.isEmpty) {
      return _commonTags;
    }
    return _commonTags
        .where((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: AppColors.glassBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: AppColors.accentPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select Tag',
                        style: AppTextStyles.headlineSmall(
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tags...',
                      hintStyle: AppTextStyles.bodyMedium(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundPrimary.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.accentPrimary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Wheel picker
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Selection indicator
                      Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentPrimary.withOpacity(0.15),
                              AppColors.accentSecondary.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentPrimary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Wheel
                      ListWheelScrollView(
                        controller: _scrollController,
                        itemExtent: 50,
                        physics: const FixedExtentScrollPhysics(),
                        diameterRatio: 1.5,
                        perspective: 0.003,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        children: _filteredTags.map((tag) {
                          final index = _filteredTags.indexOf(tag);
                          final isSelected = index == _selectedIndex;
                          final isSearch = tag == 'Search...';

                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSearch)
                                    Icon(
                                      Icons.search,
                                      color: isSelected
                                          ? AppColors.accentPrimary
                                          : AppColors.textTertiary,
                                      size: 20,
                                    )
                                  else
                                    Icon(
                                      Icons.badge_outlined,
                                      color: isSelected
                                          ? AppColors.accentPrimary
                                          : AppColors.textTertiary,
                                      size: 20,
                                    ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      tag,
                                      style: AppTextStyles.bodyLarge(
                                        color: isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        weight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Select button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedTag = _filteredTags[_selectedIndex];
                        if (selectedTag != 'Search...') {
                          widget.onTagSelected(selectedTag);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        'Select Tag',
                        style: AppTextStyles.bodyLarge(
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: AppColors.glassBorder.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Profile Drawer Menu
// Side menu is now a universal component in lib/core/widgets/

// Feed Tab
class _FeedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary.withOpacity(0.5),
            border: Border.all(
              color: AppColors.glassBorder.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 40,
            ),
          ),
        );
      },
    );
  }
}

// Communities Tab
class _CommunitiesTab extends StatelessWidget {
  final List<Map<String, dynamic>> _communities = [
    {'name': 'Flutter Developers', 'members': '12.5K', 'icon': Icons.code},
    {
      'name': 'UI/UX Designers',
      'members': '8.2K',
      'icon': Icons.design_services,
    },
    {
      'name': 'Startup Founders',
      'members': '5.7K',
      'icon': Icons.rocket_launch,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      itemCount: _communities.length,
      itemBuilder: (context, index) {
        final community = _communities[index];
        return _CommunityCard(
          name: community['name'] as String,
          members: community['members'] as String,
          icon: community['icon'] as IconData,
        );
      },
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String name;
  final String members;
  final IconData icon;

  const _CommunityCard({
    required this.name,
    required this.members,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentPrimary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$members members',
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
        ],
      ),
    );
  }
}

// Projects Tab
class _ProjectsTab extends StatelessWidget {
  final List<Map<String, dynamic>> _projects = [
    {
      'name': 'E-Commerce Platform',
      'description': 'Full-stack web application',
      'status': 'Active',
    },
    {
      'name': 'Mobile App',
      'description': 'Cross-platform mobile app',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _ProjectCard(
          name: project['name'] as String,
          description: project['description'] as String,
          status: project['status'] as String,
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String name;
  final String description;
  final String status;

  const _ProjectCard({
    required this.name,
    required this.description,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Active'
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.textSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.bodySmall(
                    color: status == 'Active'
                        ? AppColors.success
                        : AppColors.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// About Tab - Advanced and friendly design
class _AboutTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Story Section
        _AboutSection(
          title: 'Story',
          icon: Icons.auto_stories_outlined,
          content:
              'I\'m a passionate software developer with expertise in mobile and web development. I love creating beautiful and functional applications that solve real-world problems. My journey started 5 years ago when I built my first app, and I haven\'t looked back since.',
        ),
        _SectionDivider(),
        // Experience Section
        _ExperienceSection(),
        _SectionDivider(),
        // Education Section
        _EducationSection(),
        _SectionDivider(),
        // Skills Section
        _SkillsSection(),
        _SectionDivider(),
        // Certifications Section
        _CertificationsSection(),
        _SectionDivider(),
        // Languages Section
        _LanguagesSection(),
        _SectionDivider(),
        // Volunteering Section
        _VolunteeringSection(),
        _SectionDivider(),
        // Publications Section
        _PublicationsSection(),
        _SectionDivider(),
        // Interests Section
        _InterestsSection(),
        _SectionDivider(),
        // Achievements Section
        _AchievementsSection(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Light separator between sections
class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.glassBorder.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  final List<Map<String, String>> _experiences = [
    {
      'title': 'Senior Software Developer',
      'company': 'Tech Corp',
      'duration': '2020 - Present',
      'description':
          'Leading mobile development team, building scalable applications',
    },
    {
      'title': 'Software Developer',
      'company': 'StartupXYZ',
      'duration': '2018 - 2020',
      'description': 'Full-stack development, React and Node.js',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Experience',
      icon: Icons.work_outline,
      child: Column(
        children: _experiences.map((exp) {
          return _ExperienceCard(
            title: exp['title']!,
            company: exp['company']!,
            duration: exp['duration']!,
            description: exp['description']!,
          );
        }).toList(),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final String title;
  final String company;
  final String duration;
  final String description;

  const _ExperienceCard({
    required this.title,
    required this.company,
    required this.duration,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPrimary,
                      AppColors.accentSecondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accentPrimary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.accentPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textSecondary,
                  ).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationSection extends StatelessWidget {
  final List<Map<String, String>> _education = [
    {
      'degree': 'Bachelor of Computer Science',
      'school': 'Stanford University',
      'year': '2014 - 2018',
    },
    {
      'degree': 'High School Diploma',
      'school': 'Lincoln High School',
      'year': '2010 - 2014',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Education',
      icon: Icons.school_outlined,
      child: Column(
        children: _education.map((edu) {
          return _EducationCard(
            degree: edu['degree']!,
            school: edu['school']!,
            year: edu['year']!,
          );
        }).toList(),
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final String degree;
  final String school;
  final String year;

  const _EducationCard({
    required this.degree,
    required this.school,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school_outlined,
              color: AppColors.accentPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degree,
                  style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  school,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      year,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsSection extends StatelessWidget {
  final Map<String, List<String>> _skillCategories = {
    'Technical': ['Flutter', 'React', 'Node.js', 'Python', 'Firebase', 'AWS'],
    'Design': ['UI/UX Design', 'Figma', 'Adobe XD', 'Prototyping'],
    'Soft Skills': ['Leadership', 'Communication', 'Agile', 'Problem Solving'],
  };

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Skills',
      icon: Icons.stars_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _skillCategories.entries.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.key,
                  style: AppTextStyles.bodyMedium(
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.value.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentPrimary.withOpacity(0.15),
                            AppColors.accentSecondary.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentPrimary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        skill,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.accentPrimary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CertificationsSection extends StatelessWidget {
  final List<Map<String, String>> _certifications = [
    {
      'name': 'AWS Certified Solutions Architect',
      'issuer': 'Amazon Web Services',
      'date': 'Jan 2023',
    },
    {
      'name': 'Google Cloud Professional',
      'issuer': 'Google Cloud',
      'date': 'Mar 2022',
    },
    {
      'name': 'Flutter Development Bootcamp',
      'issuer': 'Udemy',
      'date': 'Sep 2021',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Certifications',
      icon: Icons.workspace_premium_outlined,
      child: Column(
        children: _certifications.map((cert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPrimary.withOpacity(0.2),
                        AppColors.accentSecondary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified,
                    color: AppColors.accentPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert['name']!,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cert['issuer']!,
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cert['date']!,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LanguagesSection extends StatelessWidget {
  final List<Map<String, dynamic>> _languages = [
    {'name': 'English', 'proficiency': 'Native', 'level': 1.0},
    {'name': 'Spanish', 'proficiency': 'Professional', 'level': 0.8},
    {'name': 'French', 'proficiency': 'Intermediate', 'level': 0.6},
    {'name': 'German', 'proficiency': 'Basic', 'level': 0.3},
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Languages',
      icon: Icons.translate,
      child: Column(
        children: _languages.map((lang) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang['name']!,
                      style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
                    ),
                    Text(
                      lang['proficiency']!,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: lang['level'],
                    backgroundColor: AppColors.backgroundSecondary.withOpacity(
                      0.3,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentPrimary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VolunteeringSection extends StatelessWidget {
  final List<Map<String, String>> _volunteering = [
    {
      'role': 'Coding Mentor',
      'organization': 'Code for Good',
      'duration': '2022 - Present',
      'description': 'Teaching underprivileged students programming basics',
    },
    {
      'role': 'Tech Volunteer',
      'organization': 'Local Community Center',
      'duration': '2021 - 2022',
      'description': 'Helping seniors learn to use smartphones and computers',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Volunteering',
      icon: Icons.volunteer_activism_outlined,
      child: Column(
        children: _volunteering.map((vol) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vol['role']!,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vol['organization']!,
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vol['duration']!,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vol['description']!,
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary,
                        ).copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PublicationsSection extends StatelessWidget {
  final List<Map<String, String>> _publications = [
    {
      'title': 'Building Scalable Mobile Apps with Flutter',
      'publisher': 'Medium',
      'date': 'Dec 2023',
      'link': 'medium.com/@johndoe',
    },
    {
      'title': 'The Future of Cross-Platform Development',
      'publisher': 'Dev.to',
      'date': 'Aug 2023',
      'link': 'dev.to/johndoe',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Publications',
      icon: Icons.article_outlined,
      child: Column(
        children: _publications.map((pub) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPrimary.withOpacity(0.2),
                        AppColors.accentSecondary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description,
                    color: AppColors.accentPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pub['title']!,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pub['publisher']!,
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pub['date']!,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 14,
                            color: AppColors.accentPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pub['link']!,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.accentPrimary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InterestsSection extends StatelessWidget {
  final List<Map<String, dynamic>> _interests = [
    {'name': 'Artificial Intelligence', 'icon': Icons.psychology_outlined},
    {'name': 'Mobile Development', 'icon': Icons.phone_android_outlined},
    {'name': 'Cloud Computing', 'icon': Icons.cloud_outlined},
    {'name': 'Open Source', 'icon': Icons.code_outlined},
    {'name': 'Entrepreneurship', 'icon': Icons.business_center_outlined},
    {'name': 'Photography', 'icon': Icons.camera_alt_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Interests',
      icon: Icons.favorite_border,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.glassBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  interest['icon'],
                  size: 16,
                  color: AppColors.accentPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  interest['name'],
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final List<Map<String, String>> _achievements = [
    {
      'title': 'Top Contributor 2023',
      'description':
          'Recognized for outstanding contributions to open source projects',
      'date': 'Dec 2023',
    },
    {
      'title': 'Hackathon Winner',
      'description':
          'First place at TechFest 2022 - Built an AI-powered mobile app',
      'date': 'Oct 2022',
    },
    {
      'title': 'Employee of the Year',
      'description': 'Awarded for exceptional performance and leadership',
      'date': 'Jan 2022',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Achievements',
      icon: Icons.emoji_events_outlined,
      child: Column(
        children: _achievements.map((achievement) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPrimary,
                        AppColors.accentSecondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['title']!,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        achievement['description']!,
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondary,
                        ).copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            achievement['date']!,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? content;
  final Widget? child;

  const _AboutSection({
    required this.title,
    this.icon,
    this.content,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPrimary.withOpacity(0.2),
                      AppColors.accentSecondary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accentPrimary, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              title,
              style: AppTextStyles.headlineSmall(weight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Content
        if (content != null)
          Text(
            content!,
            style: AppTextStyles.bodyMedium(
              color: AppColors.textSecondary,
            ).copyWith(height: 1.6),
          ),
        if (child != null) child!,
      ],
    );
  }
}
