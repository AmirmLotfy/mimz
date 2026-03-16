import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';

/// Screen 2 — Welcome screen with editorial headline and Get Started CTA
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        child: Stack(
          children: [
            // Map grid background
            Positioned.fill(
              child: CustomPaint(painter: _MapGridPainter()),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 1),
                  // Logo
                  Image.asset(
                    'assets/images/logo-dark.png',
                    width: 140,
                    fit: BoxFit.contain,
                  ).animate().fadeIn(duration: 400.ms),
                  const Spacer(flex: 1),
                  Text(
                    'YOUR',
                    style: MimzTypography.displayLarge.copyWith(
                      color: MimzColors.deepInk.withValues(alpha: 0.3),
                      fontSize: 48,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  Text(
                    'NEIGHBORHOOD\nIS YOUR\nSCHOOL.',
                    style: MimzTypography.displayLarge.copyWith(fontSize: 48),
                  ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideX(begin: -0.05),
                  const SizedBox(height: MimzSpacing.xl),
                  Text(
                    'Explore the world around you. Answer live challenges.\nGrow your district on the map.',
                    style: MimzTypography.bodyLarge.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                  const Spacer(flex: 3),
                  // CTA buttons
                  GestureDetector(
                    onTap: () => context.go('/auth'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: MimzSpacing.base),
                      decoration: BoxDecoration(
                        color: MimzColors.mossCore,
                        borderRadius: BorderRadius.circular(MimzRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          'GET STARTED',
                          style: MimzTypography.buttonText.copyWith(
                            color: MimzColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: MimzSpacing.md),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/auth'),
                      child: Text(
                        'I already have an account',
                        style: MimzTypography.bodyMedium.copyWith(
                          color: MimzColors.mossCore,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: MimzSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.borderLight.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
