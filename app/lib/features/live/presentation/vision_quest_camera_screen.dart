import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../../design_system/tokens.dart';
import '../application/live_session_controller.dart';
import '../data/live_camera_stream_service.dart';
import '../providers/live_session_provider.dart';
import '../providers/live_providers.dart';

/// Vision Quest Camera — full-screen camera with target overlay
class VisionQuestCameraScreen extends ConsumerStatefulWidget {
  const VisionQuestCameraScreen({super.key});

  @override
  ConsumerState<VisionQuestCameraScreen> createState() => _VisionQuestCameraScreenState();
}

class _VisionQuestCameraScreenState extends ConsumerState<VisionQuestCameraScreen> {
  final _cameraService = LiveCameraStreamService();
  LiveSessionController? _liveController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  ProviderSubscription? _targetSub;

  Future<void> _initCamera() async {
    try {
      await _cameraService.initialize();
      _liveController = ref.read(liveSessionControllerProvider);
      await _liveController?.startVisionQuestSession();

      // Listen for start_vision_quest tool response to get dynamic target
      _targetSub = ref.listenManual(liveSessionStateProvider, (prev, next) {
        final payload = next.valueOrNull?.lastRewardPayload;
        final prevPayload = prev?.valueOrNull?.lastRewardPayload;
        if (payload != null && payload != prevPayload && payload.containsKey('targetPrompt')) {
          final target = payload['targetPrompt'] as String?;
          if (target != null && target.isNotEmpty) {
            ref.read(visionQuestTargetProvider.notifier).state = target;
          }
        }
      });

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init failed: $e');
    }
  }

  @override
  void dispose() {
    _targetSub?.close();
    _liveController?.endSession();
    _cameraService.dispose();
    super.dispose();
  }

  ProviderSubscription? _validationSub;

  Future<void> _captureAndSend() async {
    if (_isProcessing || !_isCameraInitialized) return;
    setState(() => _isProcessing = true);

    final frame = await _cameraService.captureOneShot();
    if (frame != null) {
      final LiveSessionController controller =
          _liveController ?? ref.read(liveSessionControllerProvider);
      controller.sendVisionFrame(frame);

      // Wait for validate_vision_result tool response before navigating
      _validationSub?.close();
      _validationSub = ref.listenManual(liveSessionStateProvider, (prev, next) {
        final payload = next.valueOrNull?.lastRewardPayload;
        final prevPayload = prev?.valueOrNull?.lastRewardPayload;
        if (payload != null && payload != prevPayload && payload.containsKey('objectIdentified')) {
          _validationSub?.close();
          final label = payload['objectIdentified'] as String? ?? 'Discovery';
          final xp = (payload['xpAwarded'] as num?)?.toInt() ?? 0;
          final isValid = payload['isValid'] as bool? ?? false;
          ref.read(visionQuestResultLabelProvider.notifier).state = label;
          ref.read(visionQuestXpProvider.notifier).state = xp;
          ref.read(visionQuestValidProvider.notifier).state = isValid;
          if (mounted) context.go('/play/vision/success');
        }
      });
    } else {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.nightSurface,
      body: Stack(
        children: [
          // Camera preview or placeholder
          if (_isCameraInitialized && _cameraService.controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraService.controller!.value.previewSize?.height ?? 1,
                  height: _cameraService.controller!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraService.controller!),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              color: MimzColors.mapShadow,
              child: Center(
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: MimzColors.acidLime)
                  : Icon(
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
                  Consumer(builder: (_, ref, __) {
                    final target = ref.watch(visionQuestTargetProvider);
                    return Text(
                      target,
                      style: MimzTypography.displaySmall.copyWith(
                        color: MimzColors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }),
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
                        onTap: _captureAndSend,
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
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: MimzColors.acidLime)
                                : null,
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
    canvas.drawLine(const Offset(0, cornerLen), Offset.zero, paint);
    canvas.drawLine(Offset.zero, const Offset(cornerLen, 0), paint);

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
