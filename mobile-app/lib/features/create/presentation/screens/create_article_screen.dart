import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = 'Technology';
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
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

  Future<void> _publishArticle() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Please add a title');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showMessage('Please add content');
      return;
    }

    setState(() {
      _isPosting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isPosting = false;
    });

    _showMessage('Article published successfully');
    Navigator.pop(context);
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
                      'Write Article',
                      style: AppTextStyles.headlineMedium(
                        weight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _showMessage('Saved to drafts');
                        Navigator.pop(context);
                      },
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
                    // Title
                    TextField(
                      controller: _titleController,
                      maxLength: 100,
                      style: AppTextStyles.headlineMedium(
                        weight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Article Title',
                        hintStyle: AppTextStyles.headlineMedium(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 16,
                            color: AppColors.accentPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCategory,
                            style: AppTextStyles.bodySmall(
                              color: AppColors.accentPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Content
                    TextField(
                      controller: _contentController,
                      maxLines: 15,
                      style: AppTextStyles.bodyLarge(),
                      decoration: InputDecoration(
                        hintText: 'Start writing your article...',
                        hintStyle: AppTextStyles.bodyLarge(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : _publishArticle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      disabledBackgroundColor:
                          AppColors.textTertiary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Publish Article',
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
    );
  }
}

