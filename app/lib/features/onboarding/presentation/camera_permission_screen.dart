import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../services/haptics_service.dart';
import '../providers/onboarding_provider.dart';

/// Screen 7 — Camera permission
class CameraPermissionScreen extends ConsumerStatefulWidget {
  const CameraPermissionScreen({super.key});

  @override
  ConsumerState<CameraPermissionScreen> createState() => _CameraPermissionScreenState();
}

class _CameraPermissionScreenState extends ConsumerState<CameraPermissionScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndAdvance();
  }

  void _checkAndAdvance() async {
    await ref.read(permissionsProvider.notifier).refresh();
    if (mounted && ref.read(permissionsProvider).camera) {
      context.go('/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes and advance if granted
    ref.listen(permissionsProvider, (prev, next) {
      if (next.camera) {
        context.go('/permissions');
      }
    });

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Vision Quest'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MimzSpacing.xl),
          child: Column(
          children: [
            const Spacer(),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MimzColors.persimmonHit.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: MimzColors.persimmonHit,
                size: 36,
              ),
            ),
            const SizedBox(height: MimzSpacing.xl),
            Text(
              'Unlock Your Vision',
              style: MimzTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.md),
            Text(
              'To begin your Vision Quest and discover hidden rewards, we need access to your camera. Point, scan, and reveal.',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Camera preview card
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: MimzColors.nightSurface,
                borderRadius: BorderRadius.circular(MimzRadius.lg),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.videocam_outlined,
                      color: MimzColors.white.withValues(alpha: 0.3),
                      size: 64,
                    ),
                  ),
                  // Corner brackets
                  const Positioned(
                    top: 16,
                    left: 16,
                    child: _CornerBracket(isTopLeft: true),
                  ),
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: _CornerBracket(isTopRight: true),
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 16,
                    child: _CornerBracket(isBottomLeft: true),
                  ),
                  const Positioned(
                    bottom: 16,
                    right: 16,
                    child: _CornerBracket(isBottomRight: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            // Camera description
            Container(
              padding: const EdgeInsets.all(MimzSpacing.base),
              decoration: BoxDecoration(
                color: MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.md),
                border: Border.all(color: MimzColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Camera Viewfinder',
                            style: MimzTypography.headlineSmall),
                        Text(
                          'Align discoveries within the frame',
                          style: MimzTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      ref.read(hapticsServiceProvider).mediumImpact();
                      final status = await Permission.camera.request();
                      if (status.isGranted || status.isLimited) {
                        ref.read(hapticsServiceProvider).success();
                        await ref.read(permissionsProvider.notifier).grantCamera();
                      } else if (mounted) {
                        ref.read(hapticsServiceProvider).error();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Camera permission denied. Vision Quest requires camera access.',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MimzColors.persimmonHit,
                      foregroundColor: MimzColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MimzRadius.sm),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Enable'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            MimzButton(
              label: 'Start Exploration',
              variant: MimzButtonVariant.accent,
              onPressed: () async {
                ref.read(hapticsServiceProvider).mediumImpact();
                final status = await Permission.camera.request();
                if (status.isPermanentlyDenied) {
                  ref.read(hapticsServiceProvider).error();
                  await openAppSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Camera is permanently denied. Enable it in Settings.',
                        ),
                      ),
                    );
                  }
                  return;
                }
                if (status.isGranted || status.isLimited) {
                  ref.read(hapticsServiceProvider).success();
                  await ref.read(permissionsProvider.notifier).grantCamera();
                } else if (mounted) {
                  ref.read(hapticsServiceProvider).error();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Camera permission denied. You can grant it later in app settings.',
                      ),
                    ),
                  );
                }
                if (context.mounted) context.go('/permissions');
              },
            ),
            const SizedBox(height: MimzSpacing.md),
            MimzButton(
              label: 'Maybe later',
              variant: MimzButtonVariant.ghost,
              onPressed: () => context.go('/permissions'),
            ),
            const SizedBox(height: MimzSpacing.base),
          ],
          ),
        ),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  const _CornerBracket({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _BracketPainter(
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool isTopLeft, isTopRight, isBottomLeft, isBottomRight;

  _BracketPainter({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.persimmonHit
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (isTopLeft) {
      canvas.drawLine(Offset(0, size.height), Offset.zero, paint);
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    } else if (isTopRight) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
    } else if (isBottomLeft) {
      canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    } else if (isBottomRight) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
