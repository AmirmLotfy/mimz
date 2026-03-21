import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/waveform_visualizer.dart';
import '../application/live_session_controller.dart';
import '../providers/live_providers.dart';
// Hide liveSessionStateProvider to avoid ambiguous import (it's re-exported from live_providers.dart)
import '../providers/live_session_provider.dart';
import '../domain/live_connection_phase.dart';
import '../domain/live_event.dart';
import '../domain/live_session_state.dart';
import '../../../data/models/quiz_state.dart';
import '../../../services/sound_service.dart';
import '../../world/providers/world_provider.dart';

/// Screen 16 — Live Quiz with real Gemini Live session
///
/// Wires the full LiveSessionController pipeline:
/// mic → Gemini WebSocket → tool calls → backend → game state
class LiveQuizScreen extends ConsumerStatefulWidget {
  final bool sprintMode;
  final String? eventId;
  final String? eventTitle;
  const LiveQuizScreen({
    super.key,
    this.sprintMode = false,
    this.eventId,
    this.eventTitle,
  });

  @override
  ConsumerState<LiveQuizScreen> createState() => _LiveQuizScreenState();
}

class _LiveQuizScreenState extends ConsumerState<LiveQuizScreen> {
  QuizStatus? _prevStatus;
  bool _sessionSoundPlayed = false;
  bool _modelHasSpoken = false;
  LiveSessionController? _controller;

  @override
  void initState() {
    super.initState();
    // Start the real Gemini Live session when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller = ref.read(liveSessionControllerProvider);
      if (widget.eventId != null) {
        _controller?.startEventSession(
          eventId: widget.eventId!,
          eventTitle: widget.eventTitle ?? 'Event Challenge',
        );
      } else if (widget.sprintMode) {
        _controller?.startSprintSession();
      } else {
        _controller?.startQuizSession();
      }
    });
  }

  @override
  void dispose() {
    // End session when leaving (do not use ref after dispose)
    _controller?.endSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod's ref.listen must be called from within build.
    // Register unconditionally so Riverpod's inherited dependency tracking
    // stays stable across rebuilds.
    ref.listen(liveSessionStateProvider, (previous, next) {
      final oldPayload = previous?.valueOrNull?.lastRewardPayload;
      final newPayload = next.valueOrNull?.lastRewardPayload;
      final wasRoundComplete = previous?.valueOrNull?.isRoundComplete ?? false;
      final isRoundComplete = next.valueOrNull?.isRoundComplete ?? false;

      if (newPayload != null && newPayload != oldPayload) {
        if (newPayload.containsKey('sectorsAdded') ||
            newPayload.containsKey('sectorsGained')) {
          ref.read(districtProvider.notifier).syncBackendReward(newPayload);
        }

        if (newPayload.containsKey('isCorrect')) {
          final isCorrect = newPayload['isCorrect'] as bool? ?? false;
          final points = (newPayload['pointsAwarded'] as num?)?.toInt() ?? 100;
          ref
              .read(quizStateProvider.notifier)
              .scoreAnswer(correct: isCorrect, points: points);
        }
      }

      // Navigate to result screen when end_round completes.
      // Wait briefly so Gemini's farewell audio can finish playing.
      if (!wasRoundComplete && isRoundComplete && mounted) {
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          _controller?.endSession();
          context.go(
            widget.sprintMode ? '/play/sprint/result' : '/play/quiz/result',
          );
        });
      }
    });

    final quiz = ref.watch(quizStateProvider);
    final sessionState = ref.watch(liveSessionStateProvider).valueOrNull;
    final phase = sessionState?.phase ?? LiveConnectionPhase.idle;
    final isMicActive = sessionState?.isMicActive ?? false;
    final transcript = sessionState?.modelTranscript ?? '';
    final userTranscript = sessionState?.userTranscript ?? '';
    final currentPrompt = sessionState?.currentPrompt ?? '';
    final activeToolName = sessionState?.activeToolName;
    final questionCount = sessionState?.questionCount ?? 0;
    final roundDifficulty =
        sessionState?.roundDifficultyPreference ?? 'dynamic';
    final silencePromptCount = sessionState?.silencePromptCount ?? 0;
    final currentQuestionNumber = questionCount > 0
        ? ((sessionState?.currentQuestionIndex ?? 0) + 1)
            .clamp(1, questionCount)
        : 0;
    final roundTopic = sessionState?.roundTopic;
    final showStartupOverlay = _shouldShowStartupOverlay(
      phase,
      transcript,
      currentPrompt,
      _modelHasSpoken,
      activeToolName,
    );
    final startupCopy = _startupOverlayCopy(
      phase,
      activeToolName,
      currentPrompt: currentPrompt,
      questionCount: questionCount,
    );

    // Sound hooks — fire on status changes
    if (quiz.status != _prevStatus) {
      final newStatus = quiz.status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newStatus == QuizStatus.correct) {
          SoundService.instance.playCorrectAnswer();
          if (quiz.streak >= 3) {
            SoundService.instance.playStreak();
          }
        } else if (newStatus == QuizStatus.incorrect) {
          SoundService.instance.playWrongAnswer();
        }
      });
      _prevStatus = newStatus;
    }
    // Track whether the model has spoken at least once (for phase hint text)
    if (phase == LiveConnectionPhase.modelSpeaking) {
      _modelHasSpoken = true;
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
                      _SessionStatusChip(
                        phase: phase,
                        isSprint: widget.sprintMode,
                      ),
                      const Spacer(),
                      // Placeholder to balance the row
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Score / Streak bar — from quizStateProvider
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT SCORE',
                            style: MimzTypography.caption
                                .copyWith(color: MimzColors.white),
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
                            style: MimzTypography.caption
                                .copyWith(color: MimzColors.white),
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
                const SizedBox(height: MimzSpacing.md),
                // Momentum meter
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MOMENTUM',
                            style: MimzTypography.caption.copyWith(
                              color: MimzColors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            quiz.streak >= 10 ? 'MAX' : '${quiz.streak}/10',
                            style: MimzTypography.caption.copyWith(
                              color: quiz.streak >= 5
                                  ? MimzColors.acidLime
                                  : MimzColors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (quiz.streak / 10).clamp(0.0, 1.0),
                          backgroundColor:
                              MimzColors.white.withValues(alpha: 0.1),
                          color: quiz.streak >= 7
                              ? MimzColors.acidLime
                              : quiz.streak >= 4
                                  ? MimzColors.dustyGold
                                  : MimzColors.mistBlue,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                if (roundTopic != null || questionCount > 0)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: MimzSpacing.sm,
                      runSpacing: MimzSpacing.sm,
                      children: [
                        if (roundTopic != null)
                          _RoundMetaChip(
                              label: roundTopic.toUpperCase(),
                              accent: MimzColors.mistBlue),
                        if (questionCount > 0)
                          _RoundMetaChip(
                            label: 'Q$currentQuestionNumber/$questionCount',
                            accent: MimzColors.acidLime,
                          ),
                      ],
                    ),
                  ),
                if (roundTopic != null || questionCount > 0)
                  const SizedBox(height: MimzSpacing.base),
                // Waveform — driven by real mic amplitude
                WaveformVisualizer(
                  isActive:
                      isMicActive || phase == LiveConnectionPhase.modelSpeaking,
                  color: phase == LiveConnectionPhase.modelSpeaking
                      ? MimzColors.acidLime
                      : MimzColors.persimmonHit,
                  height: 80,
                  barCount: 9,
                  // Pass real mic amplitude when user is speaking.
                  // Falls back to sine wave animation when model is speaking.
                  amplitude:
                      isMicActive ? (sessionState?.audioAmplitude) : null,
                ),
                const Spacer(),
                // AI Transcript / Question — real text from Gemini
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
                  child: AnimatedSwitcher(
                    duration: 400.ms,
                    child: Container(
                      key: ValueKey(transcript.isNotEmpty ? transcript : currentPrompt),
                      padding: const EdgeInsets.all(MimzSpacing.lg),
                      decoration: BoxDecoration(
                        color: MimzColors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(MimzRadius.xl),
                        border: Border.all(
                          color: MimzColors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        transcript.isNotEmpty
                            ? transcript
                            : currentPrompt.isNotEmpty
                                ? currentPrompt
                                : _phaseHintText(
                                    phase, _modelHasSpoken, activeToolName),
                        style: MimzTypography.displayMedium.copyWith(
                          color: MimzColors.white,
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                if (userTranscript.isNotEmpty) ...[
                  const SizedBox(height: MimzSpacing.sm),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
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
                  _statusLabel(phase, quiz.status, activeToolName),
                  style: MimzTypography.caption.copyWith(
                    color: quiz.status == QuizStatus.correct
                        ? MimzColors.acidLime
                        : MimzColors.persimmonHit,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: MimzSpacing.sm),
                _LiveGuidanceCard(
                  phase: phase,
                  silencePromptCount: silencePromptCount,
                  roundReady: sessionState?.currentRoundId != null,
                ),
                const Spacer(flex: 2),
                // Hint / Repeat / Difficulty action bar
                _buildActionBar(
                  phase,
                  sessionState?.currentRoundId != null,
                  roundDifficulty,
                ),
                const SizedBox(height: MimzSpacing.sm),
                // Bottom toolbar — mic button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MimzSpacing.base,
                    vertical: MimzSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MicButton(phase: phase, isMicActive: isMicActive),
                    ],
                  ),
                ),
              ],
            ),

            // ─── Connecting overlay (UX-01) ────────────────────
            if (showStartupOverlay)
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
                        startupCopy.$1,
                        style: MimzTypography.headlineMedium.copyWith(
                          color: MimzColors.white,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: MimzSpacing.sm),
                      Text(
                        startupCopy.$2,
                        style: MimzTypography.bodySmall.copyWith(
                          color: MimzColors.white.withValues(alpha: 0.5),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),

            // ─── Failed overlay with retry (UX-07) ─────────────────
            // Differentiate auth/profile failure from connection lost for clearer CTAs.
            if (phase == LiveConnectionPhase.failed)
              Positioned.fill(
                child: _FailedSessionOverlay(
                  sessionState: sessionState,
                  onRetry: () => ref
                      .read(liveSessionControllerProvider)
                      .retrySession(hardReset: false),
                  onReset: () => ref
                      .read(liveSessionControllerProvider)
                      .retrySession(hardReset: true),
                  onBackToWorld: () {
                    ref.read(liveSessionControllerProvider).endSession();
                    context.go('/world');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _phaseHintText(
    LiveConnectionPhase phase,
    bool modelHasSpoken,
    String? activeToolName,
  ) {
    switch (phase) {
      case LiveConnectionPhase.connecting:
        return 'Starting your round...';
      case LiveConnectionPhase.waitingForOpeningPrompt:
        return modelHasSpoken
            ? 'Your turn — speak your answer!'
            : 'Starting round...';
      case LiveConnectionPhase.modelSpeaking:
        return 'Mimz is asking...';
      case LiveConnectionPhase.listeningForAnswer:
        return 'Listening to you...';
      case LiveConnectionPhase.grading:
        if (activeToolName == 'request_round_hint') {
          return 'Pulling a hint...';
        }
        if (activeToolName == 'request_round_repeat') {
          return 'Repeating the question...';
        }
        if (activeToolName == 'change_round_difficulty') {
          return 'Tuning the next questions...';
        }
        return 'Checking your answer...';
      case LiveConnectionPhase.roundComplete:
        return 'Round complete!';
      case LiveConnectionPhase.reconnecting:
        return 'Reconnecting...';
      case LiveConnectionPhase.ended:
        return 'Round complete!';
      case LiveConnectionPhase.failed:
        return 'Connection failed. Try again.';
      case LiveConnectionPhase.idle:
        return 'Starting...';
    }
  }

  bool _shouldShowStartupOverlay(
    LiveConnectionPhase phase,
    String transcript,
    String currentPrompt,
    bool modelHasSpoken,
    String? activeToolName,
  ) {
    if (phase == LiveConnectionPhase.connecting ||
        phase == LiveConnectionPhase.reconnecting) {
      return true;
    }
    if (phase == LiveConnectionPhase.failed ||
        phase == LiveConnectionPhase.ended ||
        phase == LiveConnectionPhase.roundComplete ||
        phase == LiveConnectionPhase.idle) {
      return false;
    }
    if (phase == LiveConnectionPhase.grading &&
        activeToolName == 'start_live_round' &&
        !modelHasSpoken) {
      return true;
    }
    return phase == LiveConnectionPhase.waitingForOpeningPrompt &&
        transcript.isEmpty &&
        currentPrompt.isEmpty &&
        !modelHasSpoken;
  }

  (String, String) _startupOverlayCopy(
    LiveConnectionPhase phase,
    String? activeToolName, {
    required String currentPrompt,
    required int questionCount,
  }) {
    switch (phase) {
      case LiveConnectionPhase.connecting:
        return (
          'Connecting voice',
          'Securing your live link to Mimz.',
        );
      case LiveConnectionPhase.reconnecting:
        return (
          'Restoring your round',
          'Reconnecting once and keeping your progress intact.',
        );
      case LiveConnectionPhase.grading:
        if (activeToolName == 'start_live_round') {
          return (
            'Preparing your round',
            questionCount > 0
                ? 'Locking in question 1 of $questionCount.'
                : 'Building the first question for your district.',
          );
        }
        return (
          'Checking your round',
          'Confirming the next step with the backend.',
        );
      case LiveConnectionPhase.waitingForOpeningPrompt:
        if (currentPrompt.isNotEmpty) {
          return (
            'Fetching first question',
            'Your opening prompt is almost ready.',
          );
        }
        return (
          'Preparing your round',
          'Choosing the best opening question for right now.',
        );
      default:
        return (
          'Preparing your round',
          'Getting Mimz ready.',
        );
    }
  }

  String _statusLabel(
    LiveConnectionPhase phase,
    QuizStatus quizStatus,
    String? activeToolName,
  ) {
    if (quizStatus == QuizStatus.correct) return '✅ CORRECT!';
    if (quizStatus == QuizStatus.incorrect) return 'Not quite';
    if (phase == LiveConnectionPhase.listeningForAnswer) return 'Your turn';
    if (phase == LiveConnectionPhase.waitingForOpeningPrompt) return 'Preparing round';
    if (phase == LiveConnectionPhase.modelSpeaking) return 'Mimz is speaking';
    if (phase == LiveConnectionPhase.grading) {
      if (activeToolName == 'request_round_hint') return 'Getting hint';
      if (activeToolName == 'request_round_repeat') return 'Repeating';
      if (activeToolName == 'change_round_difficulty') return 'Updating difficulty';
      return 'Checking';
    }
    if (phase == LiveConnectionPhase.roundComplete) return 'Round complete';
    return '';
  }

  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Widget _buildActionBar(
    LiveConnectionPhase phase,
    bool roundReady,
    String roundDifficulty,
  ) {
    final controller = ref.read(liveSessionControllerProvider);
    final isActive = phase.isActive &&
        phase != LiveConnectionPhase.roundComplete &&
        roundReady;
    final hintsLeft =
        LiveSessionController.maxHintsPerRound - controller.hintCount;
    final repeatsLeft =
        LiveSessionController.maxRepeatsPerRound - controller.repeatCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: MimzSpacing.md,
        runSpacing: MimzSpacing.sm,
        children: [
          _ActionChip(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            remaining: hintsLeft,
            enabled: isActive && hintsLeft > 0,
            onTap: () => controller.requestHint(),
          ),
          _ActionChip(
            icon: Icons.refresh,
            label: 'Repeat',
            remaining: repeatsLeft,
            enabled: isActive && repeatsLeft > 0,
            onTap: () => controller.requestRepeat(),
          ),
          _DifficultyChip(
            label: 'Easy',
            selected: roundDifficulty == 'easy',
            enabled: isActive,
            onTap: () => controller.requestDifficultyChange('easy'),
          ),
          _DifficultyChip(
            label: 'Adaptive',
            selected: roundDifficulty == 'dynamic',
            enabled: isActive,
            onTap: () => controller.requestDifficultyChange('dynamic'),
          ),
          _DifficultyChip(
            label: 'Hard',
            selected: roundDifficulty == 'hard',
            enabled: isActive,
            onTap: () => controller.requestDifficultyChange('hard'),
          ),
        ],
      ),
    );
  }
}

class _LiveGuidanceCard extends StatelessWidget {
  final LiveConnectionPhase phase;
  final int silencePromptCount;
  final bool roundReady;

  const _LiveGuidanceCard({
    required this.phase,
    required this.silencePromptCount,
    required this.roundReady,
  });

  @override
  Widget build(BuildContext context) {
    String? text;
    Color accent = MimzColors.mistBlue;

    if (!roundReady) {
      text = 'Locking in your live round and first question.';
      accent = MimzColors.mistBlue;
    } else if (phase == LiveConnectionPhase.listeningForAnswer) {
      if (silencePromptCount >= 2) {
        text = 'Say your answer now, or say hint or repeat.';
        accent = MimzColors.dustyGold;
      } else if (silencePromptCount == 1) {
        text = 'Need a nudge? You can answer now, ask for a hint, or say repeat.';
        accent = MimzColors.dustyGold;
      } else {
        text = 'Answer out loud. You can also say hint or repeat.';
      }
    } else if (phase == LiveConnectionPhase.waitingForOpeningPrompt) {
      if (silencePromptCount > 0) {
        text = 'Mimz is re-prompting. Answer when you are ready.';
        accent = MimzColors.dustyGold;
      } else {
        text = 'Mimz is lining up the next spoken turn.';
      }
    } else if (phase == LiveConnectionPhase.grading) {
      text = 'Backend is checking this turn before the next question.';
    }

    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: MimzSpacing.xxl),
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.md,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: MimzColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: accent, size: 15),
          const SizedBox(width: MimzSpacing.sm),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: MimzTypography.caption.copyWith(
                color: MimzColors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }
}

class _RoundMetaChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _RoundMetaChip({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.md,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: MimzTypography.caption.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? remaining;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.remaining,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.35;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MimzSpacing.md,
            vertical: MimzSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: MimzColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(MimzRadius.pill),
            border: Border.all(
              color: MimzColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: MimzColors.white, size: 16),
              const SizedBox(width: MimzSpacing.xs),
              Text(
                label,
                style: MimzTypography.caption.copyWith(
                  color: MimzColors.white,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(width: MimzSpacing.xs),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: MimzColors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$remaining',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.35;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: MimzSpacing.md,
            vertical: MimzSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? MimzColors.persimmonHit.withValues(alpha: 0.18)
                : MimzColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(MimzRadius.pill),
            border: Border.all(
              color: selected
                  ? MimzColors.persimmonHit
                  : MimzColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: MimzTypography.caption.copyWith(
              color: selected ? MimzColors.persimmonHit : MimzColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mic button that correctly handles all live session phases:
/// - modelSpeaking: red pulsing ring + tap → barge-in interrupt
/// - listeningForAnswer: active green mic + listening state
/// - waitingForOpeningPrompt/grading: passive / disabled
/// - inactive:       mic_off, dimmed
class _MicButton extends ConsumerWidget {
  final LiveConnectionPhase phase;
  final bool isMicActive;

  const _MicButton({required this.phase, required this.isMicActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isModelSpeaking = phase == LiveConnectionPhase.modelSpeaking;
    final isListening = phase == LiveConnectionPhase.listeningForAnswer;
    final isActive = phase.isActive;

    final Color bgColor;
    final Color iconColor;
    final IconData icon;

    if (isListening) {
      bgColor = MimzColors.mossCore;
      iconColor = MimzColors.white;
      icon = Icons.mic;
    } else if (isModelSpeaking) {
      bgColor = MimzColors.persimmonHit.withValues(alpha: 0.2);
      iconColor = MimzColors.persimmonHit;
      icon = Icons.front_hand_outlined;
    } else if (isActive && isMicActive) {
      bgColor = MimzColors.white.withValues(alpha: 0.15);
      iconColor = MimzColors.white;
      icon = Icons.mic;
    } else {
      bgColor = MimzColors.white.withValues(alpha: 0.07);
      iconColor = MimzColors.white.withValues(alpha: 0.4);
      icon = Icons.mic_off;
    }

    Widget button = GestureDetector(
      onTap: isModelSpeaking
          ? () =>
              ref.read(liveSessionControllerProvider).interruptWithUserSpeech()
          : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: isModelSpeaking
              ? Border.all(color: MimzColors.persimmonHit, width: 2)
              : null,
        ),
        child: Icon(icon, color: iconColor, size: 30),
      ),
    );

    // Pulsing ring around the button when model is speaking (tap to interrupt hint)
    if (isModelSpeaking) {
      button = button
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.12, 1.12),
            duration: 700.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.12, 1.12),
            end: const Offset(1, 1),
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: MimzSpacing.sm),
        Text(
          isModelSpeaking
              ? 'Tap to interrupt'
              : isListening
                  ? 'Listening...'
                  : isActive && isMicActive
                      ? 'Mic on'
                      : '',
          style: MimzTypography.caption.copyWith(
            color: MimzColors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// A chip showing the current session connection status
class _SessionStatusChip extends StatelessWidget {
  final LiveConnectionPhase phase;
  final bool isSprint;
  const _SessionStatusChip({required this.phase, this.isSprint = false});

  @override
  Widget build(BuildContext context) {
    final activeLabel = isSprint ? 'DAILY SPRINT' : 'LIVE ROUND';
    final activeColor =
        isSprint ? MimzColors.dustyGold : MimzColors.persimmonHit;
    final (String label, Color color) = switch (phase) {
      LiveConnectionPhase.waitingForOpeningPrompt ||
      LiveConnectionPhase.modelSpeaking ||
      LiveConnectionPhase.listeningForAnswer ||
      LiveConnectionPhase.grading =>
        (activeLabel, activeColor),
      LiveConnectionPhase.roundComplete => ('ROUND COMPLETE', MimzColors.acidLime),
      LiveConnectionPhase.reconnecting => (
          'RECONNECTING',
          MimzColors.dustyGold
        ),
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

/// Overlay shown when live session fails. Differentiates auth/profile vs connection lost.
class _FailedSessionOverlay extends StatelessWidget {
  final LiveSessionState? sessionState;
  final VoidCallback onRetry;
  final VoidCallback onReset;
  final VoidCallback onBackToWorld;

  const _FailedSessionOverlay({
    required this.sessionState,
    required this.onRetry,
    required this.onReset,
    required this.onBackToWorld,
  });

  /// Title and primary button label based on error type.
  static (String title, String primaryButton, IconData icon) _failureStyle(
    LiveError? error,
  ) {
    if (error == null) {
      return (
        'Connection Lost',
        'Retry Session',
        Icons.signal_wifi_statusbar_connected_no_internet_4,
      );
    }
    // Auth/profile precondition or 401 — suggest sign in or retry profile load
    if (error.code == LiveErrorCode.tokenFetchFailed &&
        error.recovery == LiveErrorRecovery.fatal) {
      final isAuth = error.message.toLowerCase().contains('sign in') ||
          error.message.toLowerCase().contains('load your profile');
      return (
        isAuth ? 'Sign in or load profile' : 'Couldn\'t start session',
        isAuth ? 'Retry' : 'Retry Session',
        Icons.person_off_outlined,
      );
    }
    if (error.recovery == LiveErrorRecovery.openSettings ||
        error.code == LiveErrorCode.permissionDenied) {
      return (
        'Permission needed',
        'Open Settings',
        Icons.settings_suggest_outlined,
      );
    }
    // Server unavailable (503) or config — keep message, generic title
    if (error.code == LiveErrorCode.modelUnavailable) {
      return (
        'Live unavailable',
        'Retry Session',
        Icons.cloud_off_outlined,
      );
    }
    return (
      'Connection Lost',
      'Retry Session',
      Icons.signal_wifi_statusbar_connected_no_internet_4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = sessionState?.error;
    final (title, primaryButton, icon) = _failureStyle(error);
    final bodyText =
        sessionState?.error?.message ?? 'Session failed. Tap to retry.';
    final showOpenSettings =
        sessionState?.error?.recovery == LiveErrorRecovery.openSettings;
    final phaseLabel = _phaseLabel(sessionState?.phase);
    final reconnectAttempts = sessionState?.reconnectAttempts ?? 0;
    final currentRoundId = sessionState?.currentRoundId;
    final canResumeRound = currentRoundId != null && currentRoundId.isNotEmpty;
    final currentQuestionIndex = sessionState?.currentQuestionIndex ?? 0;
    final questionCount = sessionState?.questionCount ?? 0;
    final sessionTrace = sessionState?.correlationId;
    final errorDetail = sessionState?.error?.detail;
    final primaryLabel =
        showOpenSettings ? 'Open Settings' : (canResumeRound ? 'Resume Round' : primaryButton);

    return Container(
      color: MimzColors.nightSurface.withValues(alpha: 0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: MimzColors.error, size: 52)
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: MimzSpacing.xl),
          Text(
            title,
            style: MimzTypography.headlineLarge.copyWith(
              color: MimzColors.white,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: MimzSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
            child: Text(
              bodyText,
              style: MimzTypography.bodySmall.copyWith(
                color: MimzColors.white.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
          const SizedBox(height: MimzSpacing.base),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
            padding: const EdgeInsets.all(MimzSpacing.base),
            decoration: BoxDecoration(
              color: MimzColors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(MimzRadius.lg),
              border: Border.all(
                color: MimzColors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSION REPORT',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: MimzSpacing.sm),
                _FailureMetaRow(
                  label: 'State',
                  value: phaseLabel,
                ),
                _FailureMetaRow(
                  label: 'Reconnects',
                  value: '$reconnectAttempts',
                ),
                if (canResumeRound)
                  _FailureMetaRow(
                    label: 'Round',
                    value: questionCount > 0
                        ? 'Saved at question ${currentQuestionIndex.clamp(0, questionCount - 1) + 1}/$questionCount'
                        : 'Saved and ready to resume',
                  ),
                if (sessionTrace != null && sessionTrace.isNotEmpty)
                  _FailureMetaRow(
                    label: 'Trace',
                    value: sessionTrace,
                  ),
                if (errorDetail != null && errorDetail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: MimzSpacing.sm),
                    child: Text(
                      errorDetail,
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 220.ms, duration: 300.ms),
          const SizedBox(height: MimzSpacing.xxl),
          if (showOpenSettings)
            GestureDetector(
              onTap: () => openAppSettings(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.xxl,
                  vertical: MimzSpacing.base,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.persimmonHit,
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Text(
                  primaryLabel,
                  style: MimzTypography.headlineMedium.copyWith(
                    color: MimzColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2),
          if (!showOpenSettings)
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.xxl,
                  vertical: MimzSpacing.base,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.persimmonHit,
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Text(
                  primaryLabel,
                  style: MimzTypography.headlineMedium.copyWith(
                    color: MimzColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2),
          const SizedBox(height: MimzSpacing.md),
          if (!showOpenSettings) ...[
            TextButton(
              onPressed: onReset,
              child: Text(canResumeRound ? 'Start Fresh Instead' : 'Reset Session'),
            ),
          ],
          TextButton(
            onPressed: onBackToWorld,
            child: const Text('Back to World'),
          ),
        ],
      ),
    );
  }

  static String _phaseLabel(LiveConnectionPhase? phase) {
    switch (phase) {
      case LiveConnectionPhase.connecting:
        return 'Connecting voice';
      case LiveConnectionPhase.waitingForOpeningPrompt:
        return 'Preparing round';
      case LiveConnectionPhase.modelSpeaking:
        return 'Mimz speaking';
      case LiveConnectionPhase.listeningForAnswer:
        return 'Listening';
      case LiveConnectionPhase.grading:
        return 'Checking';
      case LiveConnectionPhase.roundComplete:
        return 'Round complete';
      case LiveConnectionPhase.reconnecting:
        return 'Reconnecting';
      case LiveConnectionPhase.failed:
        return 'Failed';
      case LiveConnectionPhase.ended:
        return 'Ended';
      case LiveConnectionPhase.idle:
      case null:
        return 'Idle';
    }
  }
}

class _FailureMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _FailureMetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label.toUpperCase(),
              style: MimzTypography.caption.copyWith(
                color: MimzColors.white.withValues(alpha: 0.42),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MimzTypography.caption.copyWith(
                color: MimzColors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
