import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/live_session_provider.dart';
import '../../../data/models/quiz_state.dart';

/// Round result / victory screen — wired with quiz state
class RoundResultScreen extends ConsumerWidget {
  const RoundResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizStateProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MimzSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: MimzSpacing.xxl),
              // Victory icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: MimzColors.acidLime.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: MimzColors.acidLime, size: 48),
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), end: const Offset(1, 1),
                      curve: Curves.elasticOut, duration: 800.ms)
                  .then()
                  .shimmer(duration: 1200.ms),
              const SizedBox(height: MimzSpacing.xl),
              Text(
                'ROUND\nCOMPLETE',
                style: MimzTypography.displayLarge.copyWith(fontSize: 42),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: MimzSpacing.xxl),
              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MimzSpacing.xl),
                decoration: BoxDecoration(
                  color: MimzColors.white,
                  borderRadius: BorderRadius.circular(MimzRadius.xl),
                  border: Border.all(color: MimzColors.borderLight),
                ),
                child: Column(
                  children: [
                    Text('TOTAL SCORE', style: MimzTypography.caption),
                    Text(
                      _formatScore(quiz.score),
                      style: MimzTypography.displayLarge.copyWith(
                        fontSize: 48,
                        color: MimzColors.mossCore,
                      ),
                    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
                    const SizedBox(height: MimzSpacing.base),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ResultStat(label: 'Streak', value: '${quiz.streak}x',
                            color: MimzColors.persimmonHit),
                        const SizedBox(width: MimzSpacing.xxl),
                        _ResultStat(label: 'Multiplier', value: '${quiz.streak}×',
                            color: MimzColors.dustyGold),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.xl),
              // Territory growth
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MimzSpacing.base),
                decoration: BoxDecoration(
                  color: MimzColors.mossCore.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(MimzRadius.lg),
                  border: Border.all(color: MimzColors.mossCore.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: MimzColors.mossCore),
                    const SizedBox(width: MimzSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TERRITORY GROWTH', style: MimzTypography.caption.copyWith(
                            color: MimzColors.mossCore, fontWeight: FontWeight.w700,
                          )),
                          Text('+1 Sector unlocked', style: MimzTypography.headlineSmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.north_east, color: MimzColors.mossCore, size: 20),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: MimzSpacing.md),
              // Resources harvested
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MimzSpacing.base),
                decoration: BoxDecoration(
                  color: MimzColors.white,
                  borderRadius: BorderRadius.circular(MimzRadius.lg),
                  border: Border.all(color: MimzColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESOURCES HARVESTED', style: MimzTypography.caption),
                    const SizedBox(height: MimzSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ResourceItem(icon: Icons.terrain, label: 'Stone', value: '+120'),
                        _ResourceItem(icon: Icons.fullscreen, label: 'Glass', value: '+45'),
                        _ResourceItem(icon: Icons.park, label: 'Wood', value: '+85'),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: MimzSpacing.xxl),
              MimzButton(
                label: 'CLAIM REWARDS  →',
                onPressed: () {
                  ref.read(quizStateProvider.notifier).reset();
                  context.go('/world');
                },
              ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: MimzSpacing.xl),
            ],
          ),
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

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: MimzTypography.headlineLarge.copyWith(color: color)),
        Text(label, style: MimzTypography.bodySmall),
      ],
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResourceItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: MimzColors.mossCore, size: 24),
        const SizedBox(height: MimzSpacing.sm),
        Text(value, style: MimzTypography.headlineSmall.copyWith(color: MimzColors.mossCore)),
        Text(label, style: MimzTypography.bodySmall),
      ],
    );
  }
}
