import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../data/models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../shell/main_shell.dart';
import 'sign_up_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailFields = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithMock(String provider) async {
    final email = provider == 'Apple' ? 'user@icloud.com' : 'user@gmail.com';
    final name = provider == 'Apple' ? 'Apple User' : 'Google User';

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

  Future<void> _submitEmailLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final profile = UserProfile(
      id: const Uuid().v4(),
      name: email.split('@').first,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainShell()),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (_showEmailFields) ...[
                    GlassTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'name@example.com',
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
                    const SizedBox(height: 24),
                    GlassButton(
                      label: 'Sign In',
                      onPressed: _submitEmailLogin,
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Continue with Apple
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      borderRadius: 16,
                      onTap: () => _signInWithMock('Apple'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, size: 22, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Continue with Apple',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Continue with Google
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      borderRadius: 16,
                      onTap: () => _signInWithMock('Google'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Continue with Google',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email Login Button
                    GlassButton(
                      label: 'Email Login',
                      variant: GlassButtonVariant.secondary,
                      onPressed: () => setState(() => _showEmailFields = true),
                    ),
                  ],

                  const Spacer(),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
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
        ],
      ),
    );
  }
}
