import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class SignUpOptionsScreen extends StatefulWidget {
  const SignUpOptionsScreen({super.key});

  @override
  State<SignUpOptionsScreen> createState() => _SignUpOptionsScreenState();
}

class _SignUpOptionsScreenState extends State<SignUpOptionsScreen> {
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientWarm,
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
                Text(
                  'Let\'s get started!',
                  style: AppTextStyles.displayMedium(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you\'d like to sign up',
                  style: AppTextStyles.bodyLarge(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                // Email sign up button
                _EmailSignUpButton(
                  onPressed: () {
                    context.push('/signup-email');
                  },
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 1, color: AppColors.glassBorder),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: AppTextStyles.bodyMedium()),
                    ),
                    Expanded(
                      child: Container(height: 1, color: AppColors.glassBorder),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Social sign up buttons
                _SocialSignUpButton(
                  icon: _GoogleIcon(),
                  label: 'Continue with Google',
                  color: AppColors.googleRed,
                  onPressed: () {
                    // TODO: Implement Google sign up
                    context.push('/account-name');
                  },
                ),
                const SizedBox(height: 16),
                _SocialSignUpButton(
                  icon: _LinkedInIcon(),
                  label: 'Continue with LinkedIn',
                  color: AppColors.linkedInBlue,
                  onPressed: () {
                    // TODO: Implement LinkedIn sign up
                    context.push('/account-name');
                  },
                ),
                const SizedBox(height: 16),
                _SocialSignUpButton(
                  icon: _GitHubIcon(),
                  label: 'Continue with GitHub',
                  color: AppColors.githubGray,
                  onPressed: () {
                    // TODO: Implement GitHub sign up
                    context.push('/account-name');
                  },
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

class _EmailSignUpButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EmailSignUpButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accentPrimary.withOpacity(0.1),
        highlightColor: AppColors.accentPrimary.withOpacity(0.05),
        child: Container(
          width: double.infinity,
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
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPrimary.withOpacity(0.2),
                      AppColors.accentSecondary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: AppColors.accentPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: AppTextStyles.headlineSmall()),
                    const SizedBox(height: 4),
                    Text(
                      'Sign up with your email',
                      style: AppTextStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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

class _SocialSignUpButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SocialSignUpButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Center(child: icon),
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

// Professional icon widgets
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.googleRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _LinkedInIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.linkedInBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'in',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _GitHubIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.githubGray,
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(Icons.code, color: Colors.white, size: 14)),
    );
  }
}
