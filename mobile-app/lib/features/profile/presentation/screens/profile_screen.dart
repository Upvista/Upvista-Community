import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_side_menu.dart';
import '../../../../features/auth/data/providers/auth_provider.dart';
import '../../data/providers/profile_provider.dart';
import '../../data/models/skill.dart';
import '../../data/models/certification.dart';
import '../../data/models/language.dart';
import '../../data/models/volunteering.dart';
import '../../data/models/publication.dart';
import '../../data/models/interest.dart';
import '../../data/models/achievement.dart';

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

    // Refresh user data and profile data when profile screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();
      authProvider.refreshUser();
      profileProvider.loadAllProfileData();
    });
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
                              Tab(icon: Icon(Icons.work), text: 'Portfolio'),
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
            } else if (index == 1) {
              // Communities - navigate to communities screen
              context.push('/communities');
            } else if (index == 3) {
              // Jobs - navigate to jobs screen
              context.push('/jobs');
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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final profilePicture = user.profilePicture;
    final displayName = user.displayName;
    final username = user.username;
    final isVerified = user.isVerified;
    final bio = user.bio;

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
                  gradient: profilePicture == null || profilePicture.isEmpty
                      ? LinearGradient(
                          colors: [
                            AppColors.accentPrimary,
                            AppColors.accentSecondary,
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: AppColors.accentPrimary.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: profilePicture != null && profilePicture.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profilePicture,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.surface,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surface,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      )
                    : Icon(Icons.person, color: Colors.white, size: 50),
              ),
              // Verified badge (only show if verified)
              if (isVerified)
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
                )
              else
                // Grey verification icon for non-verified accounts
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundPrimary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name with verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  style: AppTextStyles.headlineMedium(weight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.verified,
                color: isVerified ? AppColors.success : AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@$username',
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
                    context.push('/edit-profile');
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
          if (bio != null && bio.isNotEmpty)
            Text(
              bio,
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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    // Format numbers (e.g., 2500 -> 2.5K, 1000000 -> 1M)
    String formatCount(int count) {
      if (count >= 1000000) {
        return '${(count / 1000000).toStringAsFixed(1)}M';
      } else if (count >= 1000) {
        return '${(count / 1000).toStringAsFixed(1)}K';
      }
      return count.toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Posts', value: formatCount(user.postsCount)),
          _StatItem(
            label: 'Followers',
            value: formatCount(user.followersCount),
          ),
          _StatItem(
            label: 'Following',
            value: formatCount(user.followingCount),
          ),
          _StatItem(label: 'Projects', value: formatCount(user.projectsCount)),
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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final age = user.age;
    final gender = user.gender;
    final genderCustom = user.genderCustom;
    final location = user.location;
    final website = user.website;
    final socialLinks = user.socialLinks;

    // Format gender display
    String getGenderDisplay() {
      if (gender == null) return '';
      if (gender == 'custom' && genderCustom != null) {
        return genderCustom;
      }
      return gender.substring(0, 1).toUpperCase() + gender.substring(1);
    }

    // Get social link URL
    String? getSocialLink(String platform) {
      if (socialLinks == null) return null;
      return socialLinks[platform];
    }

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
          // Age and Gender in one row (only show if available)
          if (age != null || gender != null)
            Row(
              children: [
                if (age != null) ...[
                  Icon(
                    Icons.cake_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$age years old',
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (age != null && gender != null) ...[
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
                ],
                if (gender != null) ...[
                  Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    getGenderDisplay(),
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          if (age != null || gender != null) const SizedBox(height: 12),
          // Location
          if (location != null && location.isNotEmpty)
            _DetailRow(icon: Icons.location_on_outlined, text: location),
          if (location != null && location.isNotEmpty)
            const SizedBox(height: 12),
          // Website
          if (website != null && website.isNotEmpty)
            _DetailRow(icon: Icons.language, text: website, isLink: true),
          if (website != null && website.isNotEmpty) const SizedBox(height: 16),
          // Social Links - Only show if there are social links
          if (socialLinks != null && socialLinks.isNotEmpty)
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
                if (getSocialLink('linkedin') != null)
                  _SocialIconButton(
                    icon: FontAwesomeIcons.linkedin,
                    label: 'LinkedIn',
                    color: const Color(0xFF2D9CDB),
                    url: getSocialLink('linkedin'),
                  ),
                if (getSocialLink('linkedin') != null) const SizedBox(width: 6),
                if (getSocialLink('github') != null)
                  _SocialIconButton(
                    icon: FontAwesomeIcons.github,
                    label: 'GitHub',
                    color: const Color(0xFFBBBBBB),
                    url: getSocialLink('github'),
                  ),
                if (getSocialLink('github') != null) const SizedBox(width: 6),
                if (getSocialLink('twitter') != null ||
                    getSocialLink('x') != null)
                  _SocialIconButton(
                    icon: FontAwesomeIcons.xTwitter,
                    label: 'Twitter',
                    color: const Color(0xFFE8E8E8),
                    url: getSocialLink('twitter') ?? getSocialLink('x'),
                  ),
                if (getSocialLink('twitter') != null ||
                    getSocialLink('x') != null)
                  const SizedBox(width: 6),
                if (getSocialLink('instagram') != null)
                  _SocialIconButton(
                    icon: FontAwesomeIcons.instagram,
                    label: 'Instagram',
                    color: const Color(0xFFFF6B9D),
                    url: getSocialLink('instagram'),
                  ),
                if (getSocialLink('instagram') != null)
                  const SizedBox(width: 6),
                if (getSocialLink('facebook') != null)
                  _SocialIconButton(
                    icon: FontAwesomeIcons.facebook,
                    label: 'Facebook',
                    color: const Color(0xFF4A9FF5),
                    url: getSocialLink('facebook'),
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
  final String? url;

  const _SocialIconButton({
    required this.icon,
    required this.label,
    required this.color,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (url != null && url!.isNotEmpty) {
          // TODO: Open social link using url_launcher
          // You can add url_launcher package and implement this
        }
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

// Feed Tab - Instagram Style
class _FeedTab extends StatelessWidget {
  // Sample post data
  final List<Map<String, dynamic>> _posts = List.generate(18, (index) {
    final types = ['image', 'video', 'carousel'];
    final randomType = types[index % types.length];
    return {
      'id': index,
      'type': randomType,
      'likes': (index * 23 + 45) % 5000,
      'comments': (index * 7 + 12) % 200,
      'isLiked': index % 3 == 0,
      'hasMultiple': randomType == 'carousel',
    };
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1.0, // Square posts like Instagram
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _InstagramPostTile(
          post: post,
          onTap: () {
            // TODO: Navigate to post detail screen
          },
        );
      },
    );
  }
}

class _InstagramPostTile extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const _InstagramPostTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Post Image/Video Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentPrimary.withOpacity(0.3),
                    AppColors.accentSecondary.withOpacity(0.3),
                    AppColors.accentTertiary.withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  post['type'] == 'video'
                      ? Icons.play_circle_filled
                      : Icons.image_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 28,
                ),
              ),
            ),
            // Indicators - Top Right
            Positioned(top: 6, right: 6, child: _buildIndicator()),
            // Video Play Icon - Center (for videos)
            if (post['type'] == 'video')
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ),
            // Carousel Indicator - Top Right (for multiple images)
            if (post['hasMultiple'] == true && post['type'] != 'video')
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${(post['id'] % 5) + 2}',
                      style: AppTextStyles.bodySmall(
                        color: Colors.white,
                        weight: FontWeight.w600,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            // Like indicator - Bottom Left (if liked)
            if (post['isLiked'] == true)
              Positioned(
                bottom: 6,
                left: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(post['likes']),
                      style: AppTextStyles.bodySmall(
                        color: Colors.white,
                        weight: FontWeight.w600,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            // Comments indicator - Bottom Right
            Positioned(
              bottom: 6,
              right: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: Colors.white.withOpacity(0.8),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post['comments']),
                    style: AppTextStyles.bodySmall(
                      color: Colors.white.withOpacity(0.8),
                      weight: FontWeight.w500,
                    ).copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            // Hover/Press effect
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildIndicator() {
    // Only show if it's a single image (carousel and video have their own indicators)
    if (post['type'] == 'image' && post['hasMultiple'] != true) {
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}

// Communities Tab
class _CommunitiesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
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
    );
  }
}

// Portfolio Tab - Professional Portfolio Section
class _ProjectsTab extends StatefulWidget {
  @override
  State<_ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<_ProjectsTab> {
  int _selectedSection = 0; // 0: Projects, 1: Case Studies, 2: Achievements

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact Portfolio Stats Header - Mobile Optimized
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
              Expanded(
                child: _PortfolioStat(
                  value: '24',
                  label: 'Projects',
                  isSelected: _selectedSection == 0,
                  onTap: () => setState(() => _selectedSection = 0),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: AppColors.glassBorder.withOpacity(0.2),
              ),
              Expanded(
                child: _PortfolioStat(
                  value: '12',
                  label: 'Case Studies',
                  isSelected: _selectedSection == 1,
                  onTap: () => setState(() => _selectedSection = 1),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: AppColors.glassBorder.withOpacity(0.2),
              ),
              Expanded(
                child: _PortfolioStat(
                  value: '18',
                  label: 'Achievements',
                  isSelected: _selectedSection == 2,
                  onTap: () => setState(() => _selectedSection = 2),
                ),
              ),
            ],
          ),
        ),
        // Content Section
        Expanded(
          child: IndexedStack(
            index: _selectedSection,
            children: [
              _ProjectsSection(),
              _CaseStudiesSection(),
              _PortfolioAchievementsSection(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortfolioStat extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PortfolioStat({
    required this.value,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineSmall(
                weight: FontWeight.bold,
                color: isSelected
                    ? AppColors.accentPrimary
                    : AppColors.textPrimary,
              ).copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall(
                color: isSelected
                    ? AppColors.accentPrimary
                    : AppColors.textSecondary,
                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ).copyWith(fontSize: 11),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPrimary,
                      AppColors.accentSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Projects Section
class _ProjectsSection extends StatelessWidget {
  final List<Map<String, dynamic>> _projects = [
    {
      'title': 'E-Commerce Platform',
      'description':
          'A full-stack e-commerce solution with real-time inventory management, payment integration, and admin dashboard.',
      'category': 'Web Application',
      'status': 'Completed',
      'techStack': ['Flutter', 'Node.js', 'MongoDB', 'Stripe'],
      'year': '2024',
      'thumbnail': Icons.shopping_cart_outlined,
      'links': {
        'live': 'https://example.com',
        'github': 'https://github.com/example',
      },
      'metrics': {'users': '10K+', 'revenue': '\$50K+'},
    },
    {
      'title': 'AI-Powered Mobile App',
      'description':
          'Cross-platform mobile application with machine learning features for personalized recommendations.',
      'category': 'Mobile App',
      'status': 'Active',
      'techStack': ['Flutter', 'TensorFlow', 'Firebase', 'Python'],
      'year': '2024',
      'thumbnail': Icons.smartphone_outlined,
      'links': {
        'live': 'https://example.com',
        'github': 'https://github.com/example',
      },
      'metrics': {'downloads': '25K+', 'rating': '4.8'},
    },
    {
      'title': 'Blockchain Analytics Dashboard',
      'description':
          'Real-time analytics dashboard for tracking cryptocurrency transactions and market trends.',
      'category': 'Web Application',
      'status': 'Completed',
      'techStack': ['React', 'Web3.js', 'Ethereum', 'D3.js'],
      'year': '2023',
      'thumbnail': Icons.account_balance_wallet_outlined,
      'links': {
        'live': 'https://example.com',
        'github': 'https://github.com/example',
      },
      'metrics': {'transactions': '1M+', 'users': '5K+'},
    },
    {
      'title': 'Social Media Management Tool',
      'description':
          'Comprehensive tool for managing multiple social media accounts with scheduling and analytics.',
      'category': 'Web Application',
      'status': 'Active',
      'techStack': ['Vue.js', 'Express', 'PostgreSQL', 'Redis'],
      'year': '2024',
      'thumbnail': Icons.share_outlined,
      'links': {
        'live': 'https://example.com',
        'github': 'https://github.com/example',
      },
      'metrics': {'accounts': '500+', 'posts': '10K+'},
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 60,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _ProjectCard(
          title: project['title'] as String,
          description: project['description'] as String,
          category: project['category'] as String,
          status: project['status'] as String,
          techStack: project['techStack'] as List<String>,
          year: project['year'] as String,
          thumbnail: project['thumbnail'] as IconData,
          links: project['links'] as Map<String, String>,
          metrics: project['metrics'] as Map<String, String>,
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final String status;
  final List<String> techStack;
  final String year;
  final IconData thumbnail;
  final Map<String, String> links;
  final Map<String, String> metrics;

  const _ProjectCard({
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.techStack,
    required this.year,
    required this.thumbnail,
    required this.links,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
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
                  thumbnail,
                  size: 24,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: 12),
              // Title and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyLarge(
                              weight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'Active'
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.textSecondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: status == 'Active'
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: AppTextStyles.bodySmall(
                                  color: status == 'Active'
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  weight: FontWeight.w600,
                                ).copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          category,
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          year,
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            description,
            style: AppTextStyles.bodySmall(
              color: AppColors.textSecondary,
            ).copyWith(height: 1.4, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Tech Stack
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: techStack.take(4).map((tech) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tech,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.accentPrimary,
                    weight: FontWeight.w500,
                  ).copyWith(fontSize: 10),
                ),
              );
            }).toList(),
          ),
          if (techStack.length > 4) ...[
            const SizedBox(height: 6),
            Text(
              '+${techStack.length - 4} more',
              style: AppTextStyles.bodySmall(
                color: AppColors.textSecondary,
              ).copyWith(fontSize: 10),
            ),
          ],
          const SizedBox(height: 12),
          // Metrics and Links Row
          Row(
            children: [
              // Metrics
              ...metrics.entries.take(2).map((entry) {
                return Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          entry.value,
                          style: AppTextStyles.bodySmall(
                            weight: FontWeight.w600,
                            color: AppColors.accentPrimary,
                          ).copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.key,
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Spacer(),
              // Links
              if (links.containsKey('github'))
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.code,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (links.containsKey('live')) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.launch,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Case Studies Section
class _CaseStudiesSection extends StatelessWidget {
  final List<Map<String, dynamic>> _caseStudies = [
    {
      'title': 'E-Commerce Platform Redesign',
      'client': 'TechCorp Inc.',
      'challenge':
          'Low conversion rates and poor user experience on the existing platform.',
      'solution':
          'Redesigned the entire user journey with modern UI/UX, implemented A/B testing, and optimized checkout flow.',
      'results': {
        'conversion': '+45%',
        'revenue': '+120%',
        'satisfaction': '4.9/5',
      },
      'duration': '3 months',
      'year': '2024',
      'category': 'Web Design',
    },
    {
      'title': 'Mobile App Performance Optimization',
      'client': 'StartupXYZ',
      'challenge':
          'App crashes and slow loading times affecting user retention.',
      'solution':
          'Refactored codebase, implemented caching strategies, and optimized API calls reducing load time by 70%.',
      'results': {
        'performance': '+70%',
        'crashes': '-95%',
        'retention': '+60%',
      },
      'duration': '2 months',
      'year': '2023',
      'category': 'Mobile Development',
    },
    {
      'title': 'AI-Powered Recommendation System',
      'client': 'MediaStream',
      'challenge': 'Low engagement due to generic content recommendations.',
      'solution':
          'Built machine learning model for personalized recommendations using collaborative filtering and deep learning.',
      'results': {
        'engagement': '+85%',
        'watch_time': '+110%',
        'accuracy': '92%',
      },
      'duration': '4 months',
      'year': '2023',
      'category': 'AI/ML',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 60,
      ),
      itemCount: _caseStudies.length,
      itemBuilder: (context, index) {
        final caseStudy = _caseStudies[index];
        return _CaseStudyCard(
          title: caseStudy['title'] as String,
          client: caseStudy['client'] as String,
          challenge: caseStudy['challenge'] as String,
          solution: caseStudy['solution'] as String,
          results: caseStudy['results'] as Map<String, String>,
          duration: caseStudy['duration'] as String,
          year: caseStudy['year'] as String,
          category: caseStudy['category'] as String,
        );
      },
    );
  }
}

class _CaseStudyCard extends StatelessWidget {
  final String title;
  final String client;
  final String challenge;
  final String solution;
  final Map<String, String> results;
  final String duration;
  final String year;
  final String category;

  const _CaseStudyCard({
    required this.title,
    required this.client,
    required this.challenge,
    required this.solution,
    required this.results,
    required this.duration,
    required this.year,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.accentPrimary,
                              weight: FontWeight.w600,
                            ).copyWith(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          year,
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          client,
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.schedule_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          duration,
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
          const SizedBox(height: 12),
          // Challenge & Solution (Compact)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 12,
                          color: AppColors.accentQuaternary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Challenge',
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                            weight: FontWeight.w600,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ).copyWith(fontSize: 11, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outlined,
                          size: 12,
                          color: AppColors.accentTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Solution',
                          style: AppTextStyles.bodySmall(
                            color: AppColors.textSecondary,
                            weight: FontWeight.w600,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      solution,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ).copyWith(fontSize: 11, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Results (Compact)
          Row(
            children: results.entries.map((entry) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: entry.key != results.keys.last ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.value,
                        style: AppTextStyles.bodySmall(
                          weight: FontWeight.w600,
                          color: AppColors.success,
                        ).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.key.replaceAll('_', ' '),
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 9),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Portfolio Achievements Section
class _PortfolioAchievementsSection extends StatelessWidget {
  final List<Map<String, dynamic>> _achievements = [
    {
      'title': 'Top Contributor 2024',
      'organization': 'Open Source Community',
      'description':
          'Recognized for outstanding contributions to open source projects with 500+ commits and 20+ repositories.',
      'date': 'Dec 2024',
      'badge': Icons.star,
      'color': AppColors.accentPrimary,
    },
    {
      'title': 'Hackathon Winner',
      'organization': 'TechFest 2024',
      'description':
          'First place at TechFest 2024 - Built an AI-powered mobile app in 48 hours that won the grand prize.',
      'date': 'Oct 2024',
      'badge': Icons.emoji_events,
      'color': AppColors.accentTertiary,
    },
    {
      'title': 'Best Mobile App Award',
      'organization': 'Mobile Dev Conference',
      'description':
          'Awarded Best Mobile App for innovative design and exceptional user experience at Mobile Dev Conference 2024.',
      'date': 'Aug 2024',
      'badge': Icons.workspace_premium,
      'color': AppColors.accentSecondary,
    },
    {
      'title': 'Employee of the Year',
      'organization': 'TechCorp Inc.',
      'description':
          'Awarded for exceptional performance, leadership, and contributions to company growth in 2023.',
      'date': 'Jan 2024',
      'badge': Icons.celebration,
      'color': AppColors.success,
    },
    {
      'title': 'Published Author',
      'organization': 'Tech Publications',
      'description':
          'Published 10+ technical articles on mobile development and software architecture with 50K+ total views.',
      'date': '2023',
      'badge': Icons.article,
      'color': AppColors.accentQuaternary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 60,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return _AchievementCard(
          title: achievement['title'] as String,
          organization: achievement['organization'] as String,
          description: achievement['description'] as String,
          date: achievement['date'] as String,
          badge: achievement['badge'] as IconData,
          color: achievement['color'] as Color,
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String title;
  final String organization;
  final String description;
  final String date;
  final IconData badge;
  final Color color;

  const _AchievementCard({
    required this.title,
    required this.organization,
    required this.description,
    required this.date,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(badge, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      date,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.business_center_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        organization,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ).copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textSecondary,
                  ).copyWith(fontSize: 11, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Story Section
        user.story != null && user.story!.isNotEmpty
            ? _AboutSection(
                title: 'Story',
                icon: Icons.auto_stories_outlined,
                content: user.story!,
              )
            : _AddPlaceholder(
                title: 'Story',
                icon: Icons.auto_stories_outlined,
                placeholderText: 'Add a story',
                onTap: () => context.push('/edit-profile/story'),
              ),
        _SectionDivider(),
        // Experience Section
        _ExperienceSection(),
        _SectionDivider(),
        // Education Section
        _EducationSection(),
        _SectionDivider(),
        // Skills Section
        profileProvider.skills.isNotEmpty
            ? _SkillsSection(skills: profileProvider.skills)
            : _AddPlaceholder(
                title: 'Skills',
                icon: Icons.stars_outlined,
                placeholderText: 'Add your skills',
                onTap: () => context.push('/edit-profile/skills/add'),
              ),
        _SectionDivider(),
        // Certifications Section
        profileProvider.certifications.isNotEmpty
            ? _CertificationsSection(
                certifications: profileProvider.certifications,
              )
            : _AddPlaceholder(
                title: 'Certifications',
                icon: Icons.workspace_premium_outlined,
                placeholderText: 'Add your certifications',
                onTap: () => context.push('/edit-profile/certifications/add'),
              ),
        _SectionDivider(),
        // Languages Section
        profileProvider.languages.isNotEmpty
            ? _LanguagesSection(languages: profileProvider.languages)
            : _AddPlaceholder(
                title: 'Languages',
                icon: Icons.translate,
                placeholderText: 'Add languages you speak',
                onTap: () => context.push('/edit-profile/languages/add'),
              ),
        _SectionDivider(),
        // Volunteering Section
        profileProvider.volunteering.isNotEmpty
            ? _VolunteeringSection(volunteering: profileProvider.volunteering)
            : _AddPlaceholder(
                title: 'Volunteering',
                icon: Icons.volunteer_activism_outlined,
                placeholderText: 'Add your volunteer work',
                onTap: () => context.push('/edit-profile/volunteering/add'),
              ),
        _SectionDivider(),
        // Publications Section
        profileProvider.publications.isNotEmpty
            ? _PublicationsSection(publications: profileProvider.publications)
            : _AddPlaceholder(
                title: 'Publications',
                icon: Icons.article_outlined,
                placeholderText: 'Add your publications',
                onTap: () => context.push('/edit-profile/publications/add'),
              ),
        _SectionDivider(),
        // Interests Section
        profileProvider.interests.isNotEmpty
            ? _InterestsSection(interests: profileProvider.interests)
            : _AddPlaceholder(
                title: 'Interests',
                icon: Icons.favorite_border,
                placeholderText: 'Add your interests',
                onTap: () => context.push('/edit-profile/interests/add'),
              ),
        _SectionDivider(),
        // Achievements Section
        profileProvider.achievements.isNotEmpty
            ? _AchievementsSection(achievements: profileProvider.achievements)
            : _AddPlaceholder(
                title: 'Achievements',
                icon: Icons.emoji_events_outlined,
                placeholderText: 'Add your achievements',
                onTap: () => context.push('/edit-profile/achievements/add'),
              ),
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

/// Add Placeholder - Dotted border box for missing info
class _AddPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final String placeholderText;
  final VoidCallback onTap;

  const _AddPlaceholder({
    required this.title,
    required this.icon,
    required this.placeholderText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.accentPrimary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accentPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    placeholderText,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.accentPrimary,
              size: 24,
            ),
          ],
        ),
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
  final List<Skill> skills;

  const _SkillsSection({required this.skills});

  @override
  Widget build(BuildContext context) {
    // Group skills by category
    final Map<String, List<Skill>> skillCategories = {};
    for (final skill in skills) {
      final category = skill.category ?? 'Other';
      if (!skillCategories.containsKey(category)) {
        skillCategories[category] = [];
      }
      skillCategories[category]!.add(skill);
    }

    return _AboutSection(
      title: 'Skills',
      icon: Icons.stars_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: skillCategories.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key[0].toUpperCase() + entry.key.substring(1),
                  style: AppTextStyles.bodyMedium(
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((skill) {
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            skill.skillName,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.accentPrimary,
                              weight: FontWeight.w500,
                            ),
                          ),
                          if (skill.proficiencyLevel != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• ${skill.proficiencyLevel}',
                              style: AppTextStyles.bodySmall(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
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
  final List<Certification> certifications;

  const _CertificationsSection({required this.certifications});

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Certifications',
      icon: Icons.workspace_premium_outlined,
      child: Column(
        children: certifications.map((cert) {
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
                        cert.name,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      if (cert.issuingOrganization != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          cert.issuingOrganization!,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
                            DateFormat('MMM yyyy').format(cert.issueDate),
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
  final List<Language> languages;

  const _LanguagesSection({required this.languages});

  double _getProficiencyLevel(String? proficiency) {
    switch (proficiency?.toLowerCase()) {
      case 'native':
        return 1.0;
      case 'fluent':
        return 0.9;
      case 'conversational':
        return 0.7;
      case 'basic':
        return 0.4;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Languages',
      icon: Icons.translate,
      child: Column(
        children: languages.map((lang) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.languageName,
                      style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
                    ),
                    if (lang.proficiencyLevel != null)
                      Text(
                        lang.proficiencyLevel![0].toUpperCase() +
                            lang.proficiencyLevel!.substring(1),
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (lang.proficiencyLevel != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _getProficiencyLevel(lang.proficiencyLevel),
                      backgroundColor: AppColors.backgroundSecondary
                          .withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentPrimary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VolunteeringSection extends StatelessWidget {
  final List<Volunteering> volunteering;

  const _VolunteeringSection({required this.volunteering});

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Volunteering',
      icon: Icons.volunteer_activism_outlined,
      child: Column(
        children: volunteering.map((vol) {
          final duration = vol.isCurrent
              ? '${vol.startDate.year} - Present'
              : vol.endDate != null
              ? '${vol.startDate.year} - ${vol.endDate!.year}'
              : '${vol.startDate.year}';
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
                        vol.role,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vol.organizationName,
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
                            duration,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      if (vol.description != null &&
                          vol.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          vol.description!,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ).copyWith(height: 1.5),
                        ),
                      ],
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
  final List<Publication> publications;

  const _PublicationsSection({required this.publications});

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Publications',
      icon: Icons.article_outlined,
      child: Column(
        children: publications.map((pub) {
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
                        pub.title,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      if (pub.publisher != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          pub.publisher!,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (pub.publicationDate != null) ...[
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
                              DateFormat(
                                'MMM yyyy',
                              ).format(pub.publicationDate!),
                              style: AppTextStyles.bodySmall(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (pub.publicationUrl != null &&
                          pub.publicationUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 14,
                              color: AppColors.accentPrimary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pub.publicationUrl!,
                                style: AppTextStyles.bodySmall(
                                  color: AppColors.accentPrimary,
                                  weight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
  final List<Interest> interests;

  const _InterestsSection({required this.interests});

  IconData _getInterestIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'hobby':
        return Icons.sports_soccer_outlined;
      case 'professional':
        return Icons.business_center_outlined;
      case 'academic':
        return Icons.school_outlined;
      case 'sports':
        return Icons.sports_soccer_outlined;
      case 'arts':
        return Icons.palette_outlined;
      default:
        return Icons.favorite_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Interests',
      icon: Icons.favorite_border,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: interests.map((interest) {
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
                  _getInterestIcon(interest.category),
                  size: 16,
                  color: AppColors.accentPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  interest.interestName,
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
  final List<Achievement> achievements;

  const _AchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return _AboutSection(
      title: 'Achievements',
      icon: Icons.emoji_events_outlined,
      child: Column(
        children: achievements.map((achievement) {
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
                        achievement.title,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                      ),
                      if (achievement.issuingOrganization != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          achievement.issuingOrganization!,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (achievement.achievementDate != null) ...[
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
                              DateFormat(
                                'yyyy',
                              ).format(achievement.achievementDate!),
                              style: AppTextStyles.bodySmall(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (achievement.description != null &&
                          achievement.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          achievement.description!,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ).copyWith(height: 1.5),
                        ),
                      ],
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
