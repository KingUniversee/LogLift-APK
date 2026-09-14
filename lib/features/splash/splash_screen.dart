import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../auth/login_screen.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background ambient gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liquidBackgroundGradient,
            ),
          ),
          // Fluid ambient glow orbs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 10),

                  // Center Logo & Hero
                  Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 36,
                        borderColor: AppColors.borderGlassHighlight,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 44,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Workout Log',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Build Better Habits\nTrack Your Progress',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),

                  // Buttons
                  Column(
                    children: [
                      GlassButton(
                        label: 'Get Started',
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainShell()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        label: 'Sign In',
                        variant: GlassButtonVariant.secondary,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
                    ],
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
