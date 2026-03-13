import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/waveform_visualizer.dart';
import '../../../features/live/providers/live_providers.dart';
import '../../../features/live/domain/live_connection_phase.dart';

/// Screen 8 — Live onboarding with real Gemini voice AI conversation.
///
/// Starts an onboarding session where Mimz asks the user about their
/// interests and district name via voice. The AI then calls save_user_profile
/// to persist the profile before the user continues to /onboarding/summary.
class LiveOnboardingScreen extends ConsumerStatefulWidget {
  const LiveOnboardingScreen({super.key});

  @override
  ConsumerState<LiveOnboardingScreen> createState() => _LiveOnboardingScreenState();
}

class _LiveOnboardingScreenState extends ConsumerState<LiveOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveSessionControllerProvider).startOnboardingSession();
    });
  }

  @override
  void dispose() {
    ref.read(liveSessionControllerProvider).endSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(liveSessionStateProvider).valueOrNull;
    final phase = sessionState?.phase ?? LiveConnectionPhase.idle;
    final transcript = sessionState?.modelTranscript ?? '';
    final isMicActive = sessionState?.isMicActive ?? false;

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
          // Grid overlay
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
                        onPressed: () {
                          ref.read(liveSessionControllerProvider).endSession();
                          context.go('/onboarding/summary');
                        },
                        icon: const Icon(Icons.close, color: MimzColors.white),
                      ),
                      const Spacer(),
                      // Live status chip
                      _OnboardingStatusChip(phase: phase),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // AI speech transcript — driven by real Gemini response
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
                  child: AnimatedSwitcher(
                    duration: 400.ms,
                    child: Text(
                      key: ValueKey(transcript),
                      transcript.isNotEmpty
                          ? transcript
                          : _phaseHint(phase),
                      style: MimzTypography.displayMedium.copyWith(
                        color: MimzColors.white,
                        fontSize: 26,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: MimzSpacing.base),
                Text(
                  'Speak naturally — Mimz is listening.',
                  style: MimzTypography.bodyMedium.copyWith(
                    color: MimzColors.persimmonHit,
                  ),
                ),
                const Spacer(flex: 1),
                // Waveform — driven by real session phase
                WaveformVisualizer(
                  isActive: isMicActive || phase == LiveConnectionPhase.modelSpeaking,
                  color: MimzColors.persimmonHit,
                  height: 100,
                  barCount: 9,
                ),
                const Spacer(flex: 2),
                // Control buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.huge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mic toggle — real barge-in
                      GestureDetector(
                        onTap: () {
                          ref.read(liveSessionControllerProvider).interruptWithUserSpeech();
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isMicActive
                                ? MimzColors.persimmonHit
                                : MimzColors.persimmonHit.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: MimzColors.persimmonHit.withValues(alpha: 0.3),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isMicActive ? Icons.mic : Icons.mic_none,
                            color: MimzColors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MimzSpacing.xxl),
                // Skip / Continue button — available once connected
                if (phase.isActive || phase.isTerminal)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(liveSessionControllerProvider).endSession();
                        context.go('/onboarding/summary');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: MimzSpacing.md),
                        decoration: BoxDecoration(
                          color: MimzColors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(MimzRadius.md),
                          border: Border.all(
                            color: MimzColors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Continue  →',
                            style: MimzTypography.buttonText.copyWith(
                              color: MimzColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 5000.ms, duration: 500.ms),
                const SizedBox(height: MimzSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _phaseHint(LiveConnectionPhase phase) {
    switch (phase) {
      case LiveConnectionPhase.fetchingToken:
      case LiveConnectionPhase.connecting:
      case LiveConnectionPhase.handshaking:
        return 'Connecting to Mimz...';
      case LiveConnectionPhase.connected:
        return 'Say hello to get started!';
      case LiveConnectionPhase.modelSpeaking:
        return 'Listen closely...';
      case LiveConnectionPhase.userSpeaking:
        return 'Keep going...';
      case LiveConnectionPhase.waitingForToolResult:
        return 'Saving your profile...';
      case LiveConnectionPhase.reconnecting:
        return 'Reconnecting...';
      case LiveConnectionPhase.ended:
        return 'All done! Tap Continue.';
      case LiveConnectionPhase.failed:
        return 'Connection issue. Tap Continue to skip.';
      default:
        return 'Starting up...';
    }
  }
}

class _OnboardingStatusChip extends StatelessWidget {
  final LiveConnectionPhase phase;
  const _OnboardingStatusChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (phase) {
      LiveConnectionPhase.connected ||
      LiveConnectionPhase.modelSpeaking ||
      LiveConnectionPhase.userSpeaking ||
      LiveConnectionPhase.waitingForToolResult =>
        ('MIMZ LIVE', MimzColors.persimmonHit),
      LiveConnectionPhase.reconnecting => ('RECONNECTING', MimzColors.dustyGold),
      LiveConnectionPhase.failed => ('OFFLINE', MimzColors.error),
      LiveConnectionPhase.ended => ('COMPLETE', MimzColors.mossCore),
      _ => ('CONNECTING...', MimzColors.white.withValues(alpha: 0.5)),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (phase.isActive)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms),
        const SizedBox(width: 6),
        Text(
          label,
          style: MimzTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
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
