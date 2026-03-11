import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';

/// Screen 1 — Splash screen with Mimz logo and tagline
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/welcome');
    });
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
              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MimzColors.persimmonHit,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MimzColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MimzColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MimzSpacing.xxl),
              Text(
                'PREMIUM EDITORIAL EXPERIENCE',
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
