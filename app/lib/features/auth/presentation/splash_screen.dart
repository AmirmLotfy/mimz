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

    // Authenticated — check if onboarding complete
    final isOnboarded = ref.read(isOnboardedProvider);
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
              const Spacer(flex: 3),
              // Logo icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: MimzColors.deepInk,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: MimzColors.deepInk.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: MimzColors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: MimzColors.persimmonHit,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
              const SizedBox(height: MimzSpacing.xl),
              Text('Mimz', style: MimzTypography.displayLarge)
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms),
              const Spacer(flex: 4),
              Text(
                'Learn live. Build your district.',
                style: MimzTypography.bodyLarge.copyWith(
                  color: MimzColors.textSecondary,
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: MimzSpacing.lg),
              // Animated loading dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: MimzColors.mossCore,
                    shape: BoxShape.circle,
                  ),
                ).animate(delay: Duration(milliseconds: 600 + i * 150))
                    .fadeIn(duration: 300.ms)
                    .shimmer(duration: 1000.ms)
                    .fadeOut(duration: 500.ms, delay: 1000.ms)),
              ),
              const SizedBox(height: MimzSpacing.xxl),
              Text(
                'LEARN LIVE. BUILD YOUR DISTRICT.',
                style: MimzTypography.caption,
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
