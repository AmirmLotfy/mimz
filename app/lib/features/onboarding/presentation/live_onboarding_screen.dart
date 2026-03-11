import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/waveform_visualizer.dart';

/// Screen 8 — Live onboarding with voice AI conversation
class LiveOnboardingScreen extends StatefulWidget {
  const LiveOnboardingScreen({super.key});

  @override
  State<LiveOnboardingScreen> createState() => _LiveOnboardingScreenState();
}

class _LiveOnboardingScreenState extends State<LiveOnboardingScreen> {
  bool _isListening = true;
  String _currentPrompt = '"What\'s the best coffee near me?"';
  String _statusText = 'Listening...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.nightSurface,
      body: Stack(
        children: [
          // Dark map background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MimzColors.mapShadow,
                  MimzColors.nightSurface.withValues(alpha: 0.95),
                  MimzColors.nightSurface,
                ],
              ),
            ),
          ),
          // Grid overlay on map
          CustomPaint(
            size: Size.infinite,
            painter: _DarkGridPainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MimzSpacing.base,
                    vertical: MimzSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/onboarding/summary'),
                        icon: const Icon(Icons.close, color: MimzColors.white),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            'MIMZ LIVE',
                            style: MimzTypography.caption.copyWith(
                              color: MimzColors.persimmonHit,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: MimzColors.persimmonHit,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _statusText,
                                style: MimzTypography.bodySmall.copyWith(
                                  color: MimzColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings, color: MimzColors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // Current AI speech
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
                  child: Text(
                    _currentPrompt,
                    style: MimzTypography.displayMedium.copyWith(
                      color: MimzColors.white,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: MimzSpacing.base),
                Text(
                  'Speak naturally, Mimz is here to help.',
                  style: MimzTypography.bodyMedium.copyWith(
                    color: MimzColors.persimmonHit,
                  ),
                ),
                const Spacer(flex: 1),
                // Waveform
                WaveformVisualizer(
                  isActive: _isListening,
                  color: MimzColors.persimmonHit,
                  height: 100,
                  barCount: 9,
                ),
                const Spacer(flex: 2),
                // Control buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.huge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: MimzColors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_off,
                          color: MimzColors.white,
                          size: 24,
                        ),
                      ),
                      // Main pause/play button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isListening = !_isListening;
                            _statusText = _isListening ? 'Listening...' : 'Paused';
                          });
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: MimzColors.persimmonHit,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x40F26A3D),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.pause : Icons.play_arrow,
                            color: MimzColors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      // Volume button
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: MimzColors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: MimzColors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MimzSpacing.xxl),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MimzSpacing.base,
                    vertical: MimzSpacing.md,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  decoration: BoxDecoration(
                    color: MimzColors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(MimzRadius.md),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: MimzColors.persimmonHit.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(MimzRadius.sm),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: MimzColors.persimmonHit,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: MimzSpacing.md),
                      Text(
                        'CURRENTLY SEARCHING',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MimzSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MimzColors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 50.0;
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
