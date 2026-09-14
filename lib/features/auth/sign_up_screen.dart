import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../shell/main_shell.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) return;

    final profile = UserProfile(
      id: const Uuid().v4(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    await ref.read(userProfileProvider.notifier).updateProfile(profile);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liquidBackgroundGradient,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start your fitness journey',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),

                    GlassTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: 'Alex Miller',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),

                    GlassTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'alex@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    GlassTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),

                    GlassButton(
                      label: 'Create Account',
                      onPressed: _handleSignUp,
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
