import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/world_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Screen 13 — World home screen with map, district boundary, and bottom sheet
class WorldHomeScreen extends ConsumerWidget {
  const WorldHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtAsync = ref.watch(districtProvider);
    final district = districtAsync.valueOrNull;
    final mission = ref.watch(currentMissionProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    final districtName = district?.name ?? user?.districtName ?? 'Verdant Reach';
    final sectorCount = district?.sectors ?? user?.sectors ?? 3;

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: Stack(
        children: [
          // Map background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: MimzColors.cloudBase,
            child: CustomPaint(painter: _WorldMapPainter()),
          ),
          // District boundary
          Center(
            child: CustomPaint(
              size: const Size(260, 340),
              painter: _DistrictBoundaryPainter(),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 800.ms,
              ),
          // Top HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.base,
                vertical: MimzSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        districtName,
                        style: MimzTypography.displayMedium.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                      Text(
                        'SECTOR ${sectorCount.toString().padLeft(2, '0')} • ATLAS STREET',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.mossCore,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MimzColors.mossCore.withValues(alpha: 0.15),
                      border: Border.all(color: MimzColors.mossCore, width: 2),
                    ),
                    child: const Icon(Icons.person, color: MimzColors.mossCore, size: 24),
                  ),
                ],
              ),
            ),
          ),
          // Event chip
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.base,
                  vertical: MimzSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.acidLime,
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_tethering, color: MimzColors.deepInk, size: 16),
                    const SizedBox(width: MimzSpacing.sm),
                    Text(
                      'LIVE EVENT: NEON HARVEST',
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.deepInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: -0.5),
            ),
          ),
          // PLAY button
          Center(
            child: GestureDetector(
              onTap: () => context.go('/play'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.xxl,
                  vertical: MimzSpacing.base,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.mossCore,
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: MimzColors.mossCore.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: MimzColors.white, size: 28),
                    const SizedBox(width: MimzSpacing.sm),
                    Text(
                      'PLAY',
                      style: MimzTypography.buttonText.copyWith(
                        color: MimzColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),
            ),
          ),
          // Map controls
          Positioned(
            right: MimzSpacing.base,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                _MapControlButton(icon: Icons.my_location, onTap: () {}),
                const SizedBox(height: MimzSpacing.sm),
                _MapControlButton(icon: Icons.layers, onTap: () {}),
                const SizedBox(height: MimzSpacing.sm),
                _MapControlButton(icon: Icons.add, onTap: () {}),
                const SizedBox(height: MimzSpacing.sm),
                _MapControlButton(icon: Icons.remove, onTap: () {}),
              ],
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
          ),
          // Bottom sheet — current mission
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: MimzColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(MimzRadius.xl),
                  topRight: Radius.circular(MimzRadius.xl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: MimzColors.deepInk.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: MimzSpacing.md),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MimzColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(MimzSpacing.base),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: MimzColors.mossCore.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(MimzRadius.md),
                          ),
                          child: const Icon(Icons.eco, color: MimzColors.mossCore, size: 22),
                        ),
                        const SizedBox(width: MimzSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT MISSION',
                                style: MimzTypography.caption.copyWith(
                                  color: MimzColors.mossCore,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(mission, style: MimzTypography.headlineSmall),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('450m away', style: MimzTypography.bodySmall),
                            Text(
                              '2/5 Collected',
                              style: MimzTypography.bodySmall.copyWith(
                                color: MimzColors.mossCore,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: MimzColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MimzColors.deepInk.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: MimzColors.deepInk, size: 20),
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.borderLight.withValues(alpha: 0.5)
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

class _DistrictBoundaryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.mossCore
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(40),
    ));
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = MimzColors.mossCore.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
