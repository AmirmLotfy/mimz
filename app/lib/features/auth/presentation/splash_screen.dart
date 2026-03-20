import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers.dart';

/// Screen 1 — Splash screen with smart bootstrap.
///
/// Decision tree:
///   authenticated + onboarded  → /world
///   authenticated + not onboarded → /onboarding/profile-setup
///   unauthenticated             → /welcome
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  String? _bootstrapError;
  late final AnimationController _hexRingController;

  @override
  void initState() {
    super.initState();
    _hexRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _bootstrap();
  }

  @override
  void dispose() {
    _hexRingController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final healthFuture = ref.read(apiClientProvider).checkHealth();
    final animFuture = Future.delayed(const Duration(milliseconds: 1000));

    await animFuture;
    if (!mounted) return;

    final authStatus = ref.read(authStatusProvider);
    if (authStatus.isLoading) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
    }

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      context.go('/welcome');
      return;
    }

    final backendReachable = await healthFuture;
    if (!backendReachable) {
      setState(() =>
          _bootstrapError = 'Backend is temporarily unavailable. Please retry.');
      return;
    }

    await ref.read(currentUserProvider.notifier).fetchUser();
    if (!mounted) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser.hasError) {
      final message = bootstrapFailureMessage(currentUser.error);
      if (message == 'Sign-in expired. Please sign in again.') {
        await ref.read(isOnboardedProvider.notifier).resetOnboarding();
        await ref.read(authServiceProvider).signOut();
        if (mounted) context.go('/welcome');
        return;
      }
      setState(() => _bootstrapError = message);
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
      context.go('/onboarding/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapError != null) {
      return Scaffold(
        backgroundColor: MimzColors.cloudBase,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: MimzColors.error),
                  const SizedBox(height: MimzSpacing.md),
                  Text(
                    _bootstrapError!,
                    style: MimzTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MimzSpacing.xl),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _bootstrapError = null);
                      _bootstrap();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: MimzSpacing.md),
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(isOnboardedProvider.notifier)
                          .resetOnboarding();
                      await ref.read(authServiceProvider).signOut();
                      if (!context.mounted) return;
                      context.go('/welcome');
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Sign out'),
                    style: TextButton.styleFrom(
                      foregroundColor: MimzColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HexBackgroundPainter()),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/logo-dark.png',
                    width: 180,
                    fit: BoxFit.contain,
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: MimzSpacing.base),
                  Text(
                    'Learn live. Build your district.',
                    style: MimzTypography.bodyMedium.copyWith(
                      color: MimzColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _hexRingController,
                      builder: (context, _) => CustomPaint(
                        painter:
                            _HexRingPainter(progress: _hexRingController.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: MimzSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawHex(canvas, Offset(size.width * 0.15, size.height * 0.10), 60, 0.04);
    _drawHex(canvas, Offset(size.width * 0.85, size.height * 0.08), 45, 0.03);
    _drawHex(canvas, Offset(size.width * 0.72, size.height * 0.32), 55, 0.05);
    _drawHex(canvas, Offset(size.width * 0.08, size.height * 0.55), 70, 0.04);
    _drawHex(canvas, Offset(size.width * 0.92, size.height * 0.62), 50, 0.06);
    _drawHex(canvas, Offset(size.width * 0.28, size.height * 0.82), 65, 0.03);
    _drawHex(canvas, Offset(size.width * 0.78, size.height * 0.88), 40, 0.05);
  }

  void _drawHex(Canvas canvas, Offset center, double radius, double alpha) {
    final paint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_hexPath(center, radius), paint);
  }

  static Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexRingPainter extends CustomPainter {
  final double progress;

  _HexRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final metrics = path.computeMetrics().first;
    final extractedPath = metrics.extractPath(0, metrics.length * progress);

    final paint = Paint()
      ..color = MimzColors.mossCore
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractedPath, paint);
  }

  @override
  bool shouldRepaint(_HexRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
