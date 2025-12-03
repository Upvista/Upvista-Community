import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  
  const OTPVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isComplete = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Check if all fields are filled
    bool allFilled = _controllers.every((c) => c.text.isNotEmpty);
    if (allFilled && !_isComplete) {
      setState(() {
        _isComplete = true;
      });
      // Auto verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _verifyOTP();
      });
    } else {
      setState(() {
        _isComplete = false;
      });
    }
  }

  void _verifyOTP() {
    // TODO: Implement OTP verification
    // For now, navigate to next screen
    context.push('/account-name');
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientPurple,
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
                  'Almost there!',
                  style: AppTextStyles.displayMedium(),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ve sent a verification code to',
                  style: AppTextStyles.bodyLarge(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: AppTextStyles.bodyLarge(
                    color: AppColors.accentPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                // OTP input fields
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
                        'Enter the code',
                        style: AppTextStyles.headlineSmall(),
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final spacing = 8.0;
                          final fieldWidth = ((availableWidth - (5 * spacing)) / 6).clamp(40.0, 48.0);
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: fieldWidth,
                                child: _OTPInputField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  onChanged: (value) => _onOTPChanged(index, value),
                                  onBackspace: index > 0
                                      ? () => _focusNodes[index - 1].requestFocus()
                                      : null,
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      if (_isComplete) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Verifying...',
                                style: AppTextStyles.bodyMedium(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Resend code
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement resend OTP
                    },
                    child: Text(
                      'Didn\'t receive the code? Resend',
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
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

class _OTPInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBackspace;

  const _OTPInputField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.accentPrimary
              : AppColors.glassBorder.withOpacity(0.5),
          width: focusNode.hasFocus ? 2 : 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.displaySmall(),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            onChanged(value);
          } else if (value.isEmpty && onBackspace != null) {
            onBackspace!();
          }
        },
        onSubmitted: (_) {
          if (controller.text.isEmpty && onBackspace != null) {
            onBackspace!();
          }
        },
      ),
    );
  }
}

