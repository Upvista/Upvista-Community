import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../features/auth/data/providers/auth_provider.dart';
import '../../../../features/auth/data/models/user.dart';
import '../../data/providers/profile_provider.dart';
import '../../data/models/certification.dart';
import '../../data/models/skill.dart';
import '../../data/models/language.dart';
import '../../data/models/volunteering.dart';
import '../../data/models/publication.dart';
import '../../data/models/interest.dart';
import '../../data/models/achievement.dart';

/// Modern Edit Profile Screen
/// Clean, professional design with toggle switches for section visibility
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _scrollController = ScrollController();
  bool _initialLoad = true;

  // Section visibility toggles
  final Map<String, bool> _sectionVisibility = {
    'basic_info': true,
    'story': true,
    'experience': true,
    'education': true,
    'skills': true,
    'certifications': true,
    'languages': true,
    'volunteering': true,
    'publications': true,
    'interests': true,
    'achievements': true,
    'social_links': true,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final profileProvider = context.read<ProfileProvider>();
    // Load data in parallel for faster performance - don't wait for all to complete
    profileProvider.loadAllProfileData().then((_) {
      if (mounted) {
        setState(() {
          _initialLoad = false;
        });
      }
    });
    // Set initial load to false after a short delay to show UI faster
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _initialLoad = false;
        });
      }
    });
  }

  Future<void> _refreshData() async {
    final profileProvider = context.read<ProfileProvider>();
    setState(() => _initialLoad = true);
    await profileProvider.loadAllProfileData();
    if (mounted) {
      setState(() {
        _initialLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to edit your profile',
            style: AppTextStyles.bodyMedium(),
          ),
        ),
      );
    }

    return GradientBackground(
      colors: AppColors.gradientWarm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _ModernHeader(
                onBack: () => context.pop(),
                onRefresh: _refreshData,
                isLoading: _initialLoad || profileProvider.isLoading,
              ),
              Expanded(
                child: _initialLoad || profileProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 8),

                          // Profile Picture
                          _ProfilePictureSection(user: user),
                          const SizedBox(height: 32),

                          // Basic Information
                          _SectionHeader(
                            title: 'Basic Information',
                            icon: Icons.person_outline_rounded,
                            isVisible: _sectionVisibility['basic_info']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['basic_info'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['basic_info']!) ...[
                            const SizedBox(height: 12),
                            _BasicInfoSection(user: user, context: context),
                            const SizedBox(height: 24),
                          ],

                          // Story
                          _SectionHeader(
                            title: 'Story',
                            icon: Icons.book_outlined,
                            isVisible: _sectionVisibility['story']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['story'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['story']!) ...[
                            const SizedBox(height: 12),
                            _StorySection(
                              user: user,
                              context: context,
                              onUpdate: () {
                                // Refresh user data after story update
                                context.read<AuthProvider>().refreshUser();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Experience
                          _SectionHeader(
                            title: 'Experience',
                            icon: Icons.work_outline_rounded,
                            isVisible: _sectionVisibility['experience']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['experience'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['experience']!) ...[
                            const SizedBox(height: 12),
                            _ExperienceSection(context: context),
                            const SizedBox(height: 24),
                          ],

                          // Education
                          _SectionHeader(
                            title: 'Education',
                            icon: Icons.school_outlined,
                            isVisible: _sectionVisibility['education']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['education'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['education']!) ...[
                            const SizedBox(height: 12),
                            _EducationSection(context: context),
                            const SizedBox(height: 24),
                          ],

                          // Skills
                          _SectionHeader(
                            title: 'Skills',
                            icon: Icons.stars_outlined,
                            isVisible: _sectionVisibility['skills']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['skills'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['skills']!) ...[
                            const SizedBox(height: 12),
                            _SkillsSection(
                              skills: profileProvider.skills,
                              context: context,
                              onUpdate: () {
                                // Refresh skills after add/edit
                                profileProvider.loadSkills();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Certifications
                          _SectionHeader(
                            title: 'Certifications',
                            icon: Icons.verified_outlined,
                            isVisible: _sectionVisibility['certifications']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['certifications'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['certifications']!) ...[
                            const SizedBox(height: 12),
                            _CertificationsSection(
                              certifications: profileProvider.certifications,
                              context: context,
                              onUpdate: () {
                                profileProvider.loadCertifications();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Languages
                          _SectionHeader(
                            title: 'Languages',
                            icon: Icons.translate_outlined,
                            isVisible: _sectionVisibility['languages']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['languages'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['languages']!) ...[
                            const SizedBox(height: 12),
                            _LanguagesSection(
                              languages: profileProvider.languages,
                              context: context,
                              onUpdate: () {
                                profileProvider.loadLanguages();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Volunteering
                          _SectionHeader(
                            title: 'Volunteering',
                            icon: Icons.volunteer_activism_outlined,
                            isVisible: _sectionVisibility['volunteering']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['volunteering'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['volunteering']!) ...[
                            const SizedBox(height: 12),
                            _VolunteeringSection(
                              volunteering: profileProvider.volunteering,
                              context: context,
                              onUpdate: () {
                                profileProvider.loadVolunteering();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Publications
                          _SectionHeader(
                            title: 'Publications',
                            icon: Icons.article_outlined,
                            isVisible: _sectionVisibility['publications']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['publications'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['publications']!) ...[
                            const SizedBox(height: 12),
                            _PublicationsSection(
                              publications: profileProvider.publications,
                              context: context,
                              onUpdate: () {
                                profileProvider.loadPublications();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Interests
                          _SectionHeader(
                            title: 'Interests',
                            icon: Icons.favorite_outline_rounded,
                            isVisible: _sectionVisibility['interests']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['interests'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['interests']!) ...[
                            const SizedBox(height: 12),
                            _InterestsSection(
                              interests: profileProvider.interests,
                              context: context,
                              onUpdate: () {
                                profileProvider.loadInterests();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Achievements
                          _SectionHeader(
                            title: 'Achievements',
                            icon: Icons.emoji_events_outlined,
                            isVisible: _sectionVisibility['achievements']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['achievements'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['achievements']!) ...[
                            const SizedBox(height: 12),
                            _AchievementsSection(
                              achievements: profileProvider.achievements,
                              context: context,
                              onUpdate: () {
                                profileProvider.loadAchievements();
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Social Links
                          _SectionHeader(
                            title: 'Social Links',
                            icon: Icons.share_outlined,
                            isVisible: _sectionVisibility['social_links']!,
                            onToggle: (value) {
                              setState(() {
                                _sectionVisibility['social_links'] = value;
                              });
                            },
                          ),
                          if (_sectionVisibility['social_links']!) ...[
                            const SizedBox(height: 12),
                            _SocialLinksSection(user: user, context: context),
                            const SizedBox(height: 40),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern Header with back button and refresh
class _ModernHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const _ModernHeader({
    required this.onBack,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Edit Profile',
              style: AppTextStyles.headlineMedium(weight: FontWeight.bold),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
              onPressed: isLoading ? null : onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Section Header with Toggle Switch
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isVisible;
  final ValueChanged<bool> onToggle;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentPrimary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineSmall(weight: FontWeight.w600),
          ),
        ),
        Text(
          isVisible ? 'Visible' : 'Hidden',
          style: AppTextStyles.bodySmall(
            color: isVisible ? AppColors.accentPrimary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isVisible,
          onChanged: onToggle,
          activeColor: AppColors.accentPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

/// Profile Picture Section
class _ProfilePictureSection extends StatefulWidget {
  final User user;

  const _ProfilePictureSection({required this.user});

  @override
  State<_ProfilePictureSection> createState() => _ProfilePictureSectionState();
}

class _ProfilePictureSectionState extends State<_ProfilePictureSection> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        // TODO: Upload to backend
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilePicture = widget.user.profilePicture;
    final imageToShow = _selectedImage?.path ?? profilePicture;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: imageToShow == null
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
            child: imageToShow != null
                ? ClipOval(
                    child: imageToShow.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageToShow,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          )
                        : Image.file(File(imageToShow), fit: BoxFit.cover),
                  )
                : Icon(Icons.person, color: Colors.white, size: 50),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundPrimary,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Basic Info Section
class _BasicInfoSection extends StatelessWidget {
  final User user;
  final BuildContext context;

  const _BasicInfoSection({required this.user, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModernField(
          label: 'Display Name',
          value: user.displayName,
          icon: Icons.badge_outlined,
          onTap: () => this.context.push('/settings/profile/display-name'),
        ),
        _ModernField(
          label: 'Username',
          value: '@${user.username}',
          icon: Icons.alternate_email,
          onTap: () => this.context.push('/settings/account/username'),
        ),
        _ModernField(
          label: 'Bio',
          value: user.bio ?? 'Add a bio',
          icon: Icons.description_outlined,
          isPlaceholder: user.bio == null,
          onTap: () => this.context.push('/settings/profile/bio'),
        ),
        _ModernField(
          label: 'Age',
          value: user.age != null ? '${user.age} years old' : 'Add your age',
          icon: Icons.cake_outlined,
          isPlaceholder: user.age == null,
          onTap: () => this.context.push('/settings/account/birthday'),
        ),
        _ModernField(
          label: 'Gender',
          value: _getGenderDisplay(user),
          icon: Icons.person_outline,
          isPlaceholder: user.gender == null,
          onTap: () => this.context.push('/settings/account/gender'),
        ),
        _ModernField(
          label: 'Location',
          value: user.location ?? 'Add location',
          icon: Icons.location_on_outlined,
          isPlaceholder: user.location == null,
          onTap: () => this.context.push('/settings/profile/location'),
        ),
        _ModernField(
          label: 'Website',
          value: user.website ?? 'Add website',
          icon: Icons.language,
          isPlaceholder: user.website == null,
          onTap: () => this.context.push('/settings/profile/website'),
        ),
      ],
    );
  }

  String _getGenderDisplay(User user) {
    if (user.gender == null) return 'Add gender';
    if (user.gender == 'custom' && user.genderCustom != null) {
      return user.genderCustom!;
    }
    return user.gender!.substring(0, 1).toUpperCase() +
        user.gender!.substring(1);
  }
}

/// Modern Field Item
class _ModernField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _ModernField({
    required this.label,
    required this.value,
    required this.icon,
    this.isPlaceholder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
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
                    label,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.textSecondary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium(
                      color: isPlaceholder
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Story Section
class _StorySection extends StatelessWidget {
  final User user;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _StorySection({
    required this.user,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => this.context.push('/edit-profile/story'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book_outlined,
                color: AppColors.accentPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Story',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.textSecondary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.story ?? 'Tell your story (up to 1000 characters)',
                    style: AppTextStyles.bodyMedium(
                      color: user.story == null
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Experience Section
class _ExperienceSection extends StatelessWidget {
  final BuildContext context;

  const _ExperienceSection({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Experience',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/experience/add'),
        ),
        // TODO: Load and display experiences
      ],
    );
  }
}

/// Education Section
class _EducationSection extends StatelessWidget {
  final BuildContext context;

  const _EducationSection({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Education',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/education/add'),
        ),
        // TODO: Load and display education
      ],
    );
  }
}

/// Skills Section
class _SkillsSection extends StatelessWidget {
  final List<Skill> skills;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _SkillsSection({
    required this.skills,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Skill',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/skills/add'),
        ),
        if (skills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No skills added yet',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          )
        else
          ...skills.map(
            (skill) => _ListItem(
              title: skill.skillName,
              subtitle: skill.proficiencyLevel,
              onTap: () => context.push('/edit-profile/skills/${skill.id}'),
            ),
          ),
      ],
    );
  }
}

/// Certifications Section
class _CertificationsSection extends StatelessWidget {
  final List<Certification> certifications;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _CertificationsSection({
    required this.certifications,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Certification',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/certifications/add'),
        ),
        if (certifications.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No certifications added yet',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          )
        else
          ...certifications.map(
            (cert) => _ListItem(
              title: cert.name,
              subtitle: cert.issuingOrganization,
              onTap: () =>
                  context.push('/edit-profile/certifications/${cert.id}'),
            ),
          ),
      ],
    );
  }
}

/// Languages Section
class _LanguagesSection extends StatelessWidget {
  final List<Language> languages;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _LanguagesSection({
    required this.languages,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Language',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/languages/add'),
        ),
        if (languages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No languages added yet',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          )
        else
          ...languages.map(
            (lang) => _ListItem(
              title: lang.languageName,
              subtitle: lang.proficiencyLevel,
              onTap: () => context.push('/edit-profile/languages/${lang.id}'),
            ),
          ),
      ],
    );
  }
}

/// Volunteering Section
class _VolunteeringSection extends StatelessWidget {
  final List<Volunteering> volunteering;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _VolunteeringSection({
    required this.volunteering,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Volunteering',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/volunteering/add'),
        ),
        if (volunteering.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No volunteering added yet',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          )
        else
          ...volunteering.map(
            (vol) => _ListItem(
              title: '${vol.role} at ${vol.organizationName}',
              subtitle:
                  '${vol.startDate.year}${vol.endDate != null
                      ? ' - ${vol.endDate!.year}'
                      : vol.isCurrent
                      ? ' - Present'
                      : ''}',
              onTap: () => context.push('/edit-profile/volunteering/${vol.id}'),
            ),
          ),
      ],
    );
  }
}

/// Publications Section
class _PublicationsSection extends StatelessWidget {
  final List<Publication> publications;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _PublicationsSection({
    required this.publications,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Publication',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/publications/add'),
        ),
        if (publications.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No publications added yet',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          )
        else
          ...publications.map(
            (pub) => _ListItem(
              title: pub.title,
              subtitle: pub.publisher,
              onTap: () => context.push('/edit-profile/publications/${pub.id}'),
            ),
          ),
      ],
    );
  }
}

/// Interests Section
class _InterestsSection extends StatelessWidget {
  final List<Interest> interests;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _InterestsSection({
    required this.interests,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Interest',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/interests/add'),
        ),
        if (interests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No interests added yet',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          )
        else
          ...interests.map(
            (interest) => _ListItem(
              title: interest.interestName,
              subtitle: interest.category,
              onTap: () =>
                  context.push('/edit-profile/interests/${interest.id}'),
            ),
          ),
      ],
    );
  }
}

/// Achievements Section
class _AchievementsSection extends StatelessWidget {
  final List<Achievement> achievements;
  final BuildContext context;
  final VoidCallback? onUpdate;

  const _AchievementsSection({
    required this.achievements,
    required this.context,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddButton(
          label: 'Add Achievement',
          icon: Icons.add_circle_outline_rounded,
          onTap: () => context.push('/edit-profile/achievements/add'),
        ),
        if (achievements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No achievements added yet',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          )
        else
          ...achievements.map(
            (achievement) => _ListItem(
              title: achievement.title,
              subtitle: achievement.issuingOrganization,
              onTap: () =>
                  context.push('/edit-profile/achievements/${achievement.id}'),
            ),
          ),
      ],
    );
  }
}

/// Social Links Section
class _SocialLinksSection extends StatelessWidget {
  final User user;
  final BuildContext context;

  const _SocialLinksSection({required this.user, required this.context});

  @override
  Widget build(BuildContext context) {
    final socialLinks = user.socialLinks;
    final count = socialLinks != null
        ? socialLinks.values
              .where((link) => link != null && link.isNotEmpty)
              .length
        : 0;

    return InkWell(
      onTap: () => context.push('/settings/profile/social-links'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.share_outlined,
                color: AppColors.accentPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Social Media',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.textSecondary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count > 0
                        ? '$count social link${count != 1 ? 's' : ''} connected'
                        : 'Add social media links',
                    style: AppTextStyles.bodyMedium(
                      color: count > 0
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern List Item
class _ListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ListItem({required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium()),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add Button
class _AddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AddButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.accentPrimary.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accentPrimary, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium(
                color: AppColors.accentPrimary,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
