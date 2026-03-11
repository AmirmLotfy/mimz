import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';

/// Vision Quest Camera — full-screen camera with target overlay
class VisionQuestCameraScreen extends StatelessWidget {
  const VisionQuestCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.nightSurface,
      body: Stack(
        children: [
          // Camera preview placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: MimzColors.mapShadow,
            child: Center(
              child: Icon(
                Icons.videocam,
                color: MimzColors.white.withValues(alpha: 0.1),
                size: 120,
              ),
            ),
          ),
          // Viewfinder corners
          Positioned(
            top: 120,
            left: 40,
            right: 40,
            bottom: 300,
            child: CustomPaint(
              painter: _ViewfinderPainter(),
            ),
          ),
          // Crosshair
          Center(
            child: Icon(
              Icons.add,
              color: MimzColors.white.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(MimzSpacing.base),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/play'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MimzColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: MimzColors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MimzSpacing.base,
                      vertical: MimzSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: MimzColors.mossCore,
                      borderRadius: BorderRadius.circular(MimzRadius.pill),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.center_focus_strong,
                            color: MimzColors.white, size: 16),
                        const SizedBox(width: MimzSpacing.sm),
                        Text(
                          'VISION QUEST',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: MimzColors.acidLime,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom target prompt
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                MimzSpacing.xl,
                MimzSpacing.xl,
                MimzSpacing.xl,
                MimzSpacing.huge,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    MimzColors.nightSurface.withValues(alpha: 0.9),
                    MimzColors.nightSurface,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT TARGET',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: MimzSpacing.sm),
                  Text(
                    'Show something related to architecture or design.',
                    style: MimzTypography.displaySmall.copyWith(
                      color: MimzColors.white,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MimzSpacing.xxl),
                  // Camera controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: MimzColors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library,
                            color: MimzColors.white, size: 24),
                      ),
                      // Capture button
                      GestureDetector(
                        onTap: () => context.go('/play/vision/success'),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MimzColors.acidLime,
                              width: 4,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: MimzColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: MimzColors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt,
                            color: MimzColors.white, size: 24),
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

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const cornerLen = 28.0;

    // Top-left
    canvas.drawLine(Offset(0, cornerLen), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(cornerLen, 0), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - cornerLen, 0),
        Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width, cornerLen), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - cornerLen),
        Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height),
        Offset(cornerLen, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height - cornerLen),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
