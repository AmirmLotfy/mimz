import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../services/sound_service.dart';
import '../providers/live_session_provider.dart';

import '../../../features/world/providers/world_provider.dart';
import '../../../features/world/providers/game_state_provider.dart';

/// Round result / victory screen — wired with real reward calculation
class RoundResultScreen extends ConsumerStatefulWidget {
  const RoundResultScreen({super.key});

  @override
  ConsumerState<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends ConsumerState<RoundResultScreen> {
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    SoundService.instance.playXpAward();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizStateProvider);
    final rewards = ref.watch(roundRewardsProvider);
    final primaryAction = ref.watch(recommendedPrimaryActionProvider);
    final structureProgress = ref.watch(structureProgressProvider);

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
              // Score card — real data
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
                        _ResultStat(label: 'XP Earned', value: '+${rewards.xpEarned}',
                            color: MimzColors.dustyGold),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              if (rewards.dailyBonusXp > 0 ||
                  rewards.squadContribution > 0 ||
                  rewards.eventId != null) ...[
                const SizedBox(height: MimzSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: MimzSpacing.sm,
                  runSpacing: MimzSpacing.sm,
                  children: [
                    if (rewards.dailyBonusXp > 0)
                      _SummaryPill(
                        label:
                            'Daily Sprint Bonus +${rewards.dailyBonusXp} XP • +${rewards.dailyBonusInfluence} influence',
                        color: MimzColors.dustyGold,
                      ),
                    if (rewards.squadContribution > 0)
                      _SummaryPill(
                        label:
                            'Squad mission +${rewards.squadContribution} progress',
                        color: MimzColors.mossCore,
                      ),
                    if (rewards.eventId != null)
                      _SummaryPill(
                        label: 'Event progress recorded',
                        color: MimzColors.mistBlue,
                      ),
                  ],
                ).animate(delay: 520.ms).fadeIn(duration: 350.ms),
              ],
              const SizedBox(height: MimzSpacing.xl),
              // Territory growth — real calculated sectors
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
                          Text(
                            '+${rewards.sectorsEarned} Sector${rewards.sectorsEarned > 1 ? 's' : ''} unlocked',
                            style: MimzTypography.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.north_east, color: MimzColors.mossCore, size: 20),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms)
                  .then(delay: 200.ms)
                  .shimmer(duration: 800.ms, color: MimzColors.acidLime.withValues(alpha: 0.3)),
              const SizedBox(height: MimzSpacing.md),
              // Resources — real calculated values
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
                        _ResourceItem(
                          icon: Icons.terrain,
                          label: 'Stone',
                          value: '+${rewards.materialsEarned.stone}',
                        ),
                        _ResourceItem(
                          icon: Icons.fullscreen,
                          label: 'Glass',
                          value: '+${rewards.materialsEarned.glass}',
                        ),
                        _ResourceItem(
                          icon: Icons.park,
                          label: 'Wood',
                          value: '+${rewards.materialsEarned.wood}',
                        ),
                      ],
                    ),
                    if (rewards.streakBonus > 0) ...[
                      const SizedBox(height: MimzSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: MimzSpacing.sm,
                          horizontal: MimzSpacing.base,
                        ),
                        decoration: BoxDecoration(
                          color: MimzColors.dustyGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(MimzRadius.sm),
                        ),
                        child: Text(
                          '🔥 STREAK BONUS: +${rewards.streakBonus} XP',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.dustyGold,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
              if (primaryAction != null || structureProgress != null) ...[
                const SizedBox(height: MimzSpacing.md),
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
                      Text('WHAT NEXT', style: MimzTypography.caption),
                      const SizedBox(height: MimzSpacing.sm),
                      if (primaryAction != null)
                        Text(
                          primaryAction.title,
                          style: MimzTypography.headlineSmall,
                        ),
                      if (primaryAction != null) ...[
                        const SizedBox(height: MimzSpacing.xs),
                        Text(
                          primaryAction.reasonWhyNow.isNotEmpty
                              ? primaryAction.reasonWhyNow
                              : primaryAction.subtitle,
                          style: MimzTypography.bodySmall.copyWith(
                            color: MimzColors.textSecondary,
                          ),
                        ),
                      if (primaryAction.rewardPreview.isNotEmpty) ...[
                        const SizedBox(height: MimzSpacing.base),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(MimzSpacing.sm),
                          decoration: BoxDecoration(
                            color: MimzColors.surfaceLight,
                            borderRadius: BorderRadius.circular(MimzRadius.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${primaryAction.impactLabel} • ${primaryAction.estimatedMinutes} min',
                                style: MimzTypography.caption.copyWith(
                                  color: MimzColors.mossCore,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                primaryAction.rewardPreview,
                                style: MimzTypography.bodySmall.copyWith(
                                  color: MimzColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ],
                      if (structureProgress != null &&
                          structureProgress.nextStructureName != null) ...[
                        const SizedBox(height: MimzSpacing.base),
                        Text(
                          structureProgress.readyToBuild
                              ? '${structureProgress.nextStructureName} is ready to build.'
                              : 'Progress is pushing toward ${structureProgress.nextStructureName}.',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.mossCore,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate(delay: 650.ms).fadeIn(duration: 350.ms),
              ],
              const SizedBox(height: MimzSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MimzSpacing.base),
                decoration: BoxDecoration(
                  color: MimzColors.deepInk.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(MimzRadius.lg),
                  border: Border.all(
                    color: MimzColors.acidLime.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ON RETURN TO WORLD',
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.acidLime,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: MimzSpacing.sm),
                    Text(
                      rewards.sectorsEarned > 0
                          ? 'Your map will pulse and bloom with +${rewards.sectorsEarned} new sector${rewards.sectorsEarned == 1 ? '' : 's'}.'
                          : 'Your district will absorb this result immediately.',
                      style: MimzTypography.bodyMedium.copyWith(
                        color: MimzColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: MimzSpacing.xs),
                    Text(
                      [
                        'Score ${_formatScore(quiz.score)}',
                        if (rewards.materialsEarned.stone > 0)
                          '+${rewards.materialsEarned.stone} stone',
                        if (rewards.materialsEarned.glass > 0)
                          '+${rewards.materialsEarned.glass} glass',
                        if (rewards.materialsEarned.wood > 0)
                          '+${rewards.materialsEarned.wood} wood',
                      ].join(' • '),
                      style: MimzTypography.bodySmall.copyWith(
                        color: MimzColors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 690.ms).fadeIn(duration: 320.ms),
              const SizedBox(height: MimzSpacing.xxl),
              MimzButton(
                label: _claiming ? 'SYNCING...' : 'RETURN TO WORLD  →',
                onPressed: _claiming ? null : () => _claimRewards(context, ref, rewards),
              ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: MimzSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimRewards(BuildContext context, WidgetRef ref, RoundRewards rewards) async {
    setState(() => _claiming = true);
    HapticFeedback.heavyImpact();
    SoundService.instance.playXpAward();

    try {
      final quiz = ref.read(quizStateProvider);
      await ref.read(districtProvider.notifier).claimRewards(
        score: quiz.score,
        streak: quiz.streak,
        sectorsEarned: rewards.sectorsEarned,
        materialsEarned: rewards.materialsEarned,
      );
      // Force a backend re-fetch so the world screen shows confirmed state,
      // bypassing the 30s debounce.
      ref.invalidate(gameStateProvider);
      await ref.read(districtProvider.notifier).refresh();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
      setState(() => _claiming = false);
      return;
    }

    ref.read(quizStateProvider.notifier).reset();

    if (context.mounted) {
      context.go('/world');
    }
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

class _SummaryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.base,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: MimzTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
