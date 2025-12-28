import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/services/token_storage_service.dart';
import '../../data/models/user.dart';

/// Sign-in options screen
///
/// Shows cached user account (if exists) and all sign-in options:
/// - "Yes, continue" (if cached user exists) → password screen
/// - "Continue with email" → email + password screen
/// - Social logins (Google, LinkedIn, GitHub) → OAuth flow
class SignInOptionsScreen extends StatefulWidget {
  const SignInOptionsScreen({super.key});

  @override
  State<SignInOptionsScreen> createState() => _SignInOptionsScreenState();
}

class _SignInOptionsScreenState extends State<SignInOptionsScreen> {
  User? _cachedUser;
  bool _isLoading = true;
  final TokenStorageService _tokenStorage = TokenStorageService();

  @override
  void initState() {
    super.initState();
    _loadCachedUser();
  }

  Future<void> _loadCachedUser() async {
    try {
      final userData = await _tokenStorage.getUserData();
      if (userData != null && userData.isNotEmpty) {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        setState(() {
          _cachedUser = User.fromJson(userJson);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleYesContinue() {
    // Navigate to password screen
    if (_cachedUser != null) {
      context.push('/signin-password', extra: _cachedUser!.email);
    }
  }

  void _handleContinueWithEmail() {
    // Navigate to email + password screen
    context.push('/signin-email-password');
  }

  void _handleSocialSignIn(String provider) {
    // TODO: Implement OAuth flow for each provider
    // For now, navigate to email/password screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GradientBackground(
        colors: AppColors.gradientCool,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return GradientBackground(
      colors: AppColors.gradientCool,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text('Welcome back!', style: AppTextStyles.displayMedium()),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your journey',
                  style: AppTextStyles.bodyLarge(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                // Cached user card (if exists)
                if (_cachedUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.glassBorder.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Is this your account?',
                          style: AppTextStyles.headlineSmall(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Profile picture
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.accentPrimary.withOpacity(
                            0.2,
                          ),
                          backgroundImage:
                              (_cachedUser!.profilePicture != null &&
                                  _cachedUser!.profilePicture!.isNotEmpty)
                              ? NetworkImage(_cachedUser!.profilePicture!)
                              : null,
                          child:
                              (_cachedUser!.profilePicture == null ||
                                  _cachedUser!.profilePicture!.isEmpty)
                              ? Text(
                                  _cachedUser!.displayName.isNotEmpty
                                      ? _cachedUser!.displayName[0]
                                            .toUpperCase()
                                      : _cachedUser!.username.isNotEmpty
                                      ? _cachedUser!.username[0].toUpperCase()
                                      : 'U',
                                  style: AppTextStyles.displayMedium(),
                                )
                              : null,
                        ),
                        const SizedBox(height: 20),
                        // Display name
                        Text(
                          _cachedUser!.displayName,
                          style: AppTextStyles.headlineSmall(),
                        ),
                        const SizedBox(height: 8),
                        // Username
                        Text(
                          '@${_cachedUser!.username}',
                          style: AppTextStyles.bodyLarge(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Email
                        Text(
                          _cachedUser!.email,
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Yes, continue button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleYesContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Yes, continue',
                              style: AppTextStyles.labelLarge(
                                color: AppColors.textPrimary,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.glassBorder,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.glassBorder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
                // Continue with email button
                _SignInOptionButton(
                  icon: Icons.email_outlined,
                  label: 'Continue with email',
                  onPressed: _handleContinueWithEmail,
                ),
                const SizedBox(height: 16),
                // Social sign-in buttons
                _SignInOptionButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continue with Google',
                  color: AppColors.googleRed,
                  onPressed: () => _handleSocialSignIn('Google'),
                ),
                const SizedBox(height: 16),
                _SignInOptionButton(
                  icon: Icons.business,
                  label: 'Continue with LinkedIn',
                  color: AppColors.linkedInBlue,
                  onPressed: () => _handleSocialSignIn('LinkedIn'),
                ),
                const SizedBox(height: 16),
                _SignInOptionButton(
                  icon: Icons.code,
                  label: 'Continue with GitHub',
                  color: AppColors.githubGray,
                  onPressed: () => _handleSocialSignIn('GitHub'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _SignInOptionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.glassBorder.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: buttonColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: buttonColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: buttonColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: AppTextStyles.labelLarge())),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
