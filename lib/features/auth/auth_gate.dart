import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../providers/app_providers.dart';
import '../shell/main_shell.dart';
import '../splash/splash_screen.dart';

enum AuthGateStatus { checking, authenticated, unauthenticated }

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AuthGateStatus _status = AuthGateStatus.checking;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    setState(() {
      _status = AuthGateStatus.checking;
    });

    await ApiConfig.loadCustomBaseUrl();

    try {
      final token = await ApiClient.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _status = AuthGateStatus.unauthenticated);
        return;
      }

      // Validate session with backend /api/auth/me
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (user != null) {
        // Pre-warm active user state
        ref.invalidate(userProfileProvider);
        if (mounted) setState(() => _status = AuthGateStatus.authenticated);
      } else {
        await ApiClient.instance.clearTokens();
        if (mounted) setState(() => _status = AuthGateStatus.unauthenticated);
      }
    } catch (err) {
      // If network error occurred but valid token was saved, allow retry
      final token = await ApiClient.instance.getAccessToken();
      if (token != null && token.isNotEmpty) {
        if (mounted) {
          setState(() {
            _status = AuthGateStatus.unauthenticated;
          });
        }
      } else {
        if (mounted) setState(() => _status = AuthGateStatus.unauthenticated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AuthGateStatus.checking:
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.liquidBackgroundGradient,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.fitness_center_rounded,
                          size: 48,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Restoring session...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case AuthGateStatus.authenticated:
        return const MainShell();

      case AuthGateStatus.unauthenticated:
        return const SplashScreen();
    }
  }
}
