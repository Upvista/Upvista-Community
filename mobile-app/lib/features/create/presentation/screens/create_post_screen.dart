import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _selectedMedia = [];
  String _visibility = 'Public';
  bool _commentsEnabled = true;
  bool _sharingEnabled = true;
  int _characterCount = 0;
  final int _maxCharacters = 2000;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        _characterCount = _contentController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.backgroundSecondary.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      _showMessage('Please add some content or media');
      return;
    }

    setState(() {
      _isPosting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isPosting = false;
    });

    _showMessage('Post published successfully');
    Navigator.pop(context);
  }

  void _saveDraft() {
    _showMessage('Post saved to drafts');
    Navigator.pop(context);
  }

  void _schedulePost() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Schedule Post',
              style: AppTextStyles.headlineSmall(weight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Schedule post - Coming soon',
              style: AppTextStyles.bodyMedium(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMedia() {
    _showMessage('Add media - Coming soon');
  }

  void _showVisibilityOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Who can see this?',
              style: AppTextStyles.headlineSmall(weight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...['Public', 'Followers', 'Friends', 'Only Me'].map((option) {
              final isSelected = _visibility == option;
              return ListTile(
                leading: Icon(
                  option == 'Public'
                      ? Icons.public
                      : option == 'Followers'
                          ? Icons.people
                          : option == 'Friends'
                              ? Icons.group
                              : Icons.lock,
                  color: isSelected ? AppColors.accentPrimary : AppColors.textSecondary,
                ),
                title: Text(
                  option,
                  style: AppTextStyles.bodyMedium(
                    color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: AppColors.accentPrimary)
                    : null,
                onTap: () {
                  setState(() {
                    _visibility = option;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Create Post',
                      style: AppTextStyles.headlineMedium(
                        weight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saveDraft,
                      child: Text(
                        'Draft',
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.accentPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(20),
                  children: [
                    // User Info
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
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
                              'JD',
                              style: AppTextStyles.bodyLarge(
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
                                'John Doe',
                                style: AppTextStyles.bodyLarge(
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _showVisibilityOptions,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundSecondary.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _visibility == 'Public'
                                            ? Icons.public
                                            : _visibility == 'Followers'
                                                ? Icons.people
                                                : Icons.lock,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _visibility,
                                        style: AppTextStyles.bodySmall(
                                          color: AppColors.textSecondary,
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Content Input
                    TextField(
                      controller: _contentController,
                      maxLength: _maxCharacters,
                      maxLines: 8,
                      style: AppTextStyles.bodyLarge(),
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        hintStyle: AppTextStyles.bodyLarge(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    
                    // Character Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$_characterCount/$_maxCharacters',
                          style: AppTextStyles.bodySmall(
                            color: _characterCount > _maxCharacters
                                ? AppColors.accentQuaternary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Media Preview (if any)
                    if (_selectedMedia.isNotEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Media Preview',
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Actions Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Post',
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textSecondary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _ActionButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Photo',
                                color: AppColors.accentPrimary,
                                onTap: _addMedia,
                              ),
                              _ActionButton(
                                icon: Icons.videocam_outlined,
                                label: 'Video',
                                color: AppColors.accentSecondary,
                                onTap: () => _showMessage('Add video - Coming soon'),
                              ),
                              _ActionButton(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                color: AppColors.accentTertiary,
                                onTap: () => _showMessage('Add location - Coming soon'),
                              ),
                              _ActionButton(
                                icon: Icons.alternate_email,
                                label: 'Tag',
                                color: AppColors.success,
                                onTap: () => _showMessage('Tag people - Coming soon'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Post Settings
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _SettingToggle(
                            icon: Icons.comment_outlined,
                            title: 'Allow Comments',
                            value: _commentsEnabled,
                            onChanged: (value) => setState(() => _commentsEnabled = value),
                          ),
                          const SizedBox(height: 12),
                          _SettingToggle(
                            icon: Icons.share_outlined,
                            title: 'Allow Sharing',
                            value: _sharingEnabled,
                            onChanged: (value) => setState(() => _sharingEnabled = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary.withOpacity(0.9),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.glassBorder.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _schedulePost,
                        icon: Icon(
                          Icons.schedule,
                          size: 18,
                          color: AppColors.accentPrimary,
                        ),
                        label: Text(
                          'Schedule',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.accentPrimary,
                            weight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.accentPrimary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isPosting ? null : _publishPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          disabledBackgroundColor:
                              AppColors.textTertiary.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isPosting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Publish Post',
                                style: AppTextStyles.bodyLarge(
                                  color: Colors.white,
                                  weight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall(
                color: AppColors.textSecondary,
              ).copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyMedium(
              weight: FontWeight.w500,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accentPrimary,
        ),
      ],
    );
  }
}

