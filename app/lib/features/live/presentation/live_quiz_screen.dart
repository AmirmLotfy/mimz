import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/waveform_visualizer.dart';
import '../providers/live_session_provider.dart';
import '../../../data/models/quiz_state.dart';

/// Screen 16 — Live Quiz with dark immersive UI, score, streak, and voice interaction
class LiveQuizScreen extends ConsumerStatefulWidget {
  const LiveQuizScreen({super.key});

  @override
  ConsumerState<LiveQuizScreen> createState() => _LiveQuizScreenState();
}

class _LiveQuizScreenState extends ConsumerState<LiveQuizScreen> {
  bool _isListening = true;

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizStateProvider);

    return Scaffold(
      backgroundColor: MimzColors.nightSurface,
      body: SafeArea(
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
                    onPressed: () => context.go('/play'),
                    icon: const Icon(Icons.close, color: MimzColors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MimzSpacing.base,
                      vertical: MimzSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: MimzColors.persimmonHit.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(MimzRadius.pill),
                      border: Border.all(
                        color: MimzColors.persimmonHit.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: MimzColors.persimmonHit,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: MimzSpacing.sm),
                        Text(
                          'LIVE ROUND',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.persimmonHit,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.people_outline, color: MimzColors.white),
                  ),
                ],
              ),
            ),
            // Score / Streak bar — from provider
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
            // Waveform
            WaveformVisualizer(
              isActive: _isListening,
              color: MimzColors.persimmonHit,
              height: 80,
              barCount: 9,
            ),
            const Spacer(),
            // Question — from provider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
              child: Text(
                quiz.questionText,
                style: MimzTypography.displayMedium.copyWith(
                  color: MimzColors.white,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            Text(
              quiz.status == QuizStatus.listening
                  ? 'LISTENING FOR YOUR ANSWER...'
                  : quiz.status == QuizStatus.correct
                      ? '✅ CORRECT!'
                      : quiz.status == QuizStatus.incorrect
                          ? '❌ NOT QUITE...'
                          : 'WAITING...',
              style: MimzTypography.caption.copyWith(
                color: quiz.status == QuizStatus.correct
                    ? MimzColors.acidLime
                    : MimzColors.persimmonHit,
              ),
            ),
            const Spacer(flex: 2),
            // Hint button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.lg,
                vertical: MimzSpacing.md,
              ),
              decoration: BoxDecoration(
                color: MimzColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(MimzRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb, color: MimzColors.dustyGold, size: 18),
                  const SizedBox(width: MimzSpacing.sm),
                  Text(
                    'USE A HINT',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Bottom toolbar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.base,
                vertical: MimzSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isListening = !_isListening),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? MimzColors.persimmonHit
                            : MimzColors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        color: MimzColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  _ToolbarIcon(Icons.videocam_outlined),
                  _ToolbarIcon(Icons.shield_outlined),
                  _ToolbarIcon(Icons.map_outlined),
                  _ToolbarIcon(Icons.emoji_events_outlined),
                  _ToolbarIcon(Icons.settings),
                  _ToolbarIcon(Icons.more_horiz),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  const _ToolbarIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: MimzColors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: MimzColors.white, size: 20),
    );
  }
}
