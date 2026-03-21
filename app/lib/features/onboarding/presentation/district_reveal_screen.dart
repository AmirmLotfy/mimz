import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers.dart';

/// First district reveal — emotional peak after naming/emblem.
/// Shows the user's district on the map, then CTA to enter world.
class DistrictRevealScreen extends ConsumerWidget {
  const DistrictRevealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final raw = user?.districtName.trim();
    final districtName = (raw != null && raw.isNotEmpty) ? raw : 'Your District';

    return Scaffold(
      backgroundColor: MimzColors.nightSurface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Map-style background
          CustomPaint(
            painter: _RevealMapPainter(),
            size: Size.infinite,
          ),
          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MimzColors.nightSurface.withValues(alpha: 0.7),
                  MimzColors.nightSurface,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: MimzSpacing.xxl),
                  Text(
                    'Welcome to',
                    style: MimzTypography.bodyLarge.copyWith(
                      color: MimzColors.white.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: MimzSpacing.sm),
                  Text(
                    districtName,
                    style: MimzTypography.displayLarge.copyWith(
                      color: MimzColors.white,
                      fontSize: 32,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: MimzSpacing.lg),
                  Text(
                    'Your territory in the Mimz world.\nPlay rounds, grow it, make it yours.',
                    style: MimzTypography.bodySmall.copyWith(
                      color: MimzColors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await ref.read(isOnboardedProvider.notifier).markOnboarded();
                      try {
                        await ref.read(apiClientProvider).updateProfile({
                          'onboardingCompleted': true,
                          'onboardingStage': 'completed',
                        });
                      } catch (_) {}
                      final currentUser = ref.read(currentUserProvider).valueOrNull;
                      if (currentUser != null) {
                        ref.read(currentUserProvider.notifier).updateUser(
                          currentUser.copyWith(
                            onboardingCompleted: true,
                            onboardingStage: 'completed',
                          ),
                        );
                      }
                      if (context.mounted) context.go('/world');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: MimzSpacing.base,
                      ),
                      decoration: BoxDecoration(
                        color: MimzColors.persimmonHit,
                        borderRadius:
                            BorderRadius.circular(MimzRadius.pill),
                      ),
                      child: Text(
                        'Enter your world',
                        style: MimzTypography.headlineMedium.copyWith(
                          color: MimzColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
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

class _RevealMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;

    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Central "district" hex hint
    final center = Offset(size.width / 2, size.height * 0.4);
    final hexPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawHex(canvas, center, 48, hexPaint);
  }

  void _drawHex(Canvas canvas, Offset center, double radius, Paint paint) {
    const sides = 6;
    final path = Path();
    for (var i = 0; i <= sides; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
