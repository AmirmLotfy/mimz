import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/waveform_visualizer.dart';
import '../providers/live_providers.dart';
// Hide liveSessionStateProvider to avoid ambiguous import (it's re-exported from live_providers.dart)
import '../providers/live_session_provider.dart' hide liveSessionStateProvider;
import '../domain/live_connection_phase.dart';
import '../../../data/models/quiz_state.dart';
import '../../../services/sound_service.dart';

/// Screen 16 — Live Quiz with real Gemini Live session
///
/// Wires the full LiveSessionController pipeline:
/// mic → Gemini WebSocket → tool calls → backend → game state
class LiveQuizScreen extends ConsumerStatefulWidget {
  const LiveQuizScreen({super.key});

  @override
  ConsumerState<LiveQuizScreen> createState() => _LiveQuizScreenState();
}

class _LiveQuizScreenState extends ConsumerState<LiveQuizScreen> {
  QuizStatus? _prevStatus;
  bool _sessionSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    // Start the real Gemini Live session when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveSessionControllerProvider).startQuizSession();
    });
  }

  @override
  void dispose() {
    // End session when leaving the screen
    ref.read(liveSessionControllerProvider).endSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizStateProvider);
    final sessionState = ref.watch(liveSessionStateProvider).valueOrNull;
    final phase = sessionState?.phase ?? LiveConnectionPhase.idle;
    final isMicActive = sessionState?.isMicActive ?? false;
    final transcript = sessionState?.modelTranscript ?? '';
    final userTranscript = sessionState?.userTranscript ?? '';

    // Sound hooks — fire on status changes
    if (quiz.status != _prevStatus) {
      final newStatus = quiz.status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newStatus == QuizStatus.correct) {
          SoundService.instance.playCorrectAnswer();
        } else if (newStatus == QuizStatus.incorrect) {
          SoundService.instance.playWrongAnswer();
        }
      });
      _prevStatus = newStatus;
    }
    // Session start sound
    if (phase.isActive && !_sessionSoundPlayed) {
      _sessionSoundPlayed = true;
      SoundService.instance.playSessionStart();
    }

    return Scaffold(
      backgroundColor: MimzColors.nightSurface,
      body: SafeArea(
        child: Stack(
          children: [
            // ─── Main session content ──────────────────────────
            Column(
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
                          context.go('/play');
                        },
                        icon: const Icon(Icons.close, color: MimzColors.white),
                      ),
                      const Spacer(),
                      _SessionStatusChip(phase: phase),
                      const Spacer(),
                      // Placeholder to balance the row
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Score / Streak bar — from quizStateProvider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT SCORE',
                            style: MimzTypography.caption.copyWith(color: MimzColors.white),
                          ),
                          Text(
                            _formatScore(quiz.score),
                            style: MimzTypography.displayLarge.copyWith(
                              color: MimzColors.white,
                              fontSize: 40,
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'STREAK',
                            style: MimzTypography.caption.copyWith(color: MimzColors.white),
                          ),
                          Text(
                            '${quiz.streak}x',
                            style: MimzTypography.displayLarge.copyWith(
                              color: MimzColors.persimmonHit,
                              fontSize: 40,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // Waveform — driven by real mic activity
                WaveformVisualizer(
                  isActive: isMicActive || phase == LiveConnectionPhase.modelSpeaking,
                  color: phase == LiveConnectionPhase.modelSpeaking
                      ? MimzColors.acidLime
                      : MimzColors.persimmonHit,
                  height: 80,
                  barCount: 9,
                ),
                const Spacer(),
                // AI Transcript / Question — real text from Gemini
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
                  child: AnimatedSwitcher(
                    duration: 400.ms,
                    child: Text(
                      key: ValueKey(transcript),
                      transcript.isNotEmpty
                          ? transcript
                          : _phaseHintText(phase),
                      style: MimzTypography.displayMedium.copyWith(
                        color: MimzColors.white,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (userTranscript.isNotEmpty) ...[
                  const SizedBox(height: MimzSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
                    child: Text(
                      'You: $userTranscript',
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: MimzSpacing.base),
                // Status indicator
                Text(
                  _statusLabel(phase, quiz.status),
                  style: MimzTypography.caption.copyWith(
                    color: quiz.status == QuizStatus.correct
                        ? MimzColors.acidLime
                        : MimzColors.persimmonHit,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(flex: 2),
                // Bottom toolbar — only mic toggle is real; others removed
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MimzSpacing.base,
                    vertical: MimzSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mic toggle — toggles mic in real session
                      GestureDetector(
                        onTap: () {
                          final ctrl = ref.read(liveSessionControllerProvider);
                          if (!isMicActive) {
                            ctrl.interruptWithUserSpeech();
                          }
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isMicActive
                                ? MimzColors.persimmonHit
                                : MimzColors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isMicActive ? Icons.mic : Icons.mic_off,
                            color: MimzColors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ─── Connecting overlay (UX-01) ────────────────────
            if (!phase.isActive && !phase.isTerminal && phase != LiveConnectionPhase.idle)
              Positioned.fill(
                child: Container(
                  color: MimzColors.nightSurface.withValues(alpha: 0.92),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: MimzColors.persimmonHit,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: MimzSpacing.xl),
                      Text(
                        'Connecting to Mimz...',
                        style: MimzTypography.headlineMedium.copyWith(
                          color: MimzColors.white,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: MimzSpacing.sm),
                      Text(
                        _phaseHintText(phase),
                        style: MimzTypography.bodySmall.copyWith(
                          color: MimzColors.white.withValues(alpha: 0.5),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _phaseHintText(LiveConnectionPhase phase) {
    switch (phase) {
      case LiveConnectionPhase.fetchingToken:
        return 'Connecting to Gemini...';
      case LiveConnectionPhase.connecting:
      case LiveConnectionPhase.handshaking:
        return 'Starting your round...';
      case LiveConnectionPhase.connected:
        return 'Listening for Mimz...';
      case LiveConnectionPhase.modelSpeaking:
        return 'Mimz is speaking...';
      case LiveConnectionPhase.userSpeaking:
        return 'Go ahead, answer!';
      case LiveConnectionPhase.waitingForToolResult:
        return 'Grading your answer...';
      case LiveConnectionPhase.reconnecting:
        return 'Reconnecting...';
      case LiveConnectionPhase.ended:
        return 'Round ended!';
      case LiveConnectionPhase.failed:
        return 'Connection failed. Try again.';
      case LiveConnectionPhase.idle:
        return 'Starting...';
    }
  }

  String _statusLabel(LiveConnectionPhase phase, QuizStatus quizStatus) {
    if (quizStatus == QuizStatus.correct) return '✅ CORRECT!';
    if (quizStatus == QuizStatus.incorrect) return '❌ NOT QUITE...';
    if (phase == LiveConnectionPhase.userSpeaking ||
        phase == LiveConnectionPhase.connected) {
      return 'LISTENING...';
    }
    if (phase == LiveConnectionPhase.modelSpeaking) return '🔊 MIMZ SPEAKING';
    if (phase == LiveConnectionPhase.waitingForToolResult) return '⏳ GRADING...';
    return 'WAITING...';
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

/// A chip showing the current session connection status
class _SessionStatusChip extends StatelessWidget {
  final LiveConnectionPhase phase;
  const _SessionStatusChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (phase) {
      LiveConnectionPhase.connected ||
      LiveConnectionPhase.modelSpeaking ||
      LiveConnectionPhase.userSpeaking ||
      LiveConnectionPhase.waitingForToolResult =>
        ('LIVE ROUND', MimzColors.persimmonHit),
      LiveConnectionPhase.reconnecting => ('RECONNECTING', MimzColors.dustyGold),
      LiveConnectionPhase.failed => ('FAILED', MimzColors.error),
      LiveConnectionPhase.ended => ('ENDED', MimzColors.textTertiary),
      _ => ('CONNECTING...', MimzColors.mossCore),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.base,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: MimzSpacing.sm),
          Text(
            label,
            style: MimzTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
