import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/auth_provider.dart';

/// Screen 1 — Splash screen with smart bootstrap.
///
/// Decision tree:
///   authenticated + onboarded  → /world
///   authenticated + not onboarded → /permissions
///   unauthenticated             → /welcome
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Allow splash animation to play (min 1.8s)
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final authStatus = ref.read(authStatusProvider);

    // If auth stream hasn't settled yet, wait for it briefly
    if (authStatus.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      context.go('/welcome');
      return;
    }

    final isOnboardedAsync = ref.read(isOnboardedProvider);
    if (isOnboardedAsync.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }

    final isOnboarded = ref.read(isOnboardedProvider).valueOrNull ?? false;
    if (isOnboarded) {
      context.go('/world');
    } else {
      context.go('/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo icon - center stage
              Image.asset(
                'assets/images/logo-dark.png',
                width: 180, // Slightly larger since it's the sole focus now
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
              const Spacer(flex: 3),
              // Animated loading dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: MimzColors.mossCore,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 300.ms, delay: Duration(milliseconds: i * 200))
                    .shimmer(duration: 1000.ms, delay: 500.ms)
                    .fadeOut(duration: 300.ms, delay: 1000.ms)),
              ),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
