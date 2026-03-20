import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/rewards_provider.dart';
import '../../../data/models/blueprint.dart';

/// Reward Vault screen — wired with providers
class RewardVaultScreen extends ConsumerWidget {
  const RewardVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprints = ref.watch(blueprintsProvider);
    final stats = ref.watch(vaultStatsProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        title: const Text('Reward Vault'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MimzSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats summary
            Container(
              padding: const EdgeInsets.all(MimzSpacing.base),
              decoration: BoxDecoration(
                color: MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.lg),
                border: Border.all(color: MimzColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _VaultStat(label: 'TOTAL', value: '${stats['total'] ?? 0}', color: MimzColors.deepInk),
                  _VaultStat(label: 'MASTER', value: '${stats['master'] ?? 0}', color: MimzColors.dustyGold),
                  _VaultStat(label: 'RARE', value: '${stats['rare'] ?? 0}', color: MimzColors.mistBlue),
                  _VaultStat(label: 'COMMON', value: '${stats['common'] ?? 0}', color: MimzColors.mossCore),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: MimzSpacing.xl),
            Text('BLUEPRINTS COLLECTED', style: MimzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: MimzSpacing.md),
            // Blueprint grid or empty state
            if (blueprints.isEmpty)
              Container(
                padding: const EdgeInsets.all(MimzSpacing.xl),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MimzColors.white,
                  borderRadius: BorderRadius.circular(MimzRadius.lg),
                  border: Border.all(color: MimzColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 40, color: MimzColors.textTertiary),
                    const SizedBox(height: MimzSpacing.md),
                    Text(
                      'No blueprints yet',
                      style: MimzTypography.headlineSmall,
                    ),
                    const SizedBox(height: MimzSpacing.sm),
                    Text(
                      'Play live rounds to unlock structures and earn blueprints.',
                      style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: MimzSpacing.md,
                  crossAxisSpacing: MimzSpacing.md,
                ),
                itemCount: blueprints.length,
                itemBuilder: (context, index) {
                  return _BlueprintCard(blueprint: blueprints[index])
                      .animate(delay: Duration(milliseconds: 100 * index))
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
                },
              ),
            const SizedBox(height: MimzSpacing.xxl),
            // Reward History section
            _RewardHistorySection(),
          ],
        ),
      ),
    );
  }
}

class _RewardHistorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(rewardHistoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 16, color: MimzColors.textTertiary),
            const SizedBox(width: MimzSpacing.sm),
            Text(
              'REWARD HISTORY',
              style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: MimzSpacing.md),
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(
            'Could not load reward history',
            style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
          ),
          data: (rewards) => rewards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: MimzSpacing.xl),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: 40, color: MimzColors.textTertiary),
                        const SizedBox(height: MimzSpacing.md),
                        Text(
                          'Complete rounds and quests to earn rewards',
                          style: MimzTypography.bodySmall
                              .copyWith(color: MimzColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: rewards.take(10).map((r) => _RewardRow(reward: r)).toList(),
                ),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  final Map<String, dynamic> reward;
  const _RewardRow({required this.reward});

  @override
  Widget build(BuildContext context) {
    final type = reward['type'] as String? ?? 'xp';
    final amount = reward['amount'] as num? ?? 0;
    final source = reward['source'] as String? ?? '';
    final date = DateTime.tryParse(reward['grantedAt'] as String? ?? '');
    final iconData = switch (type) {
      'territory' => Icons.map_outlined,
      'materials' => Icons.inventory_2_outlined,
      'structure' => Icons.domain_outlined,
      'combo' => Icons.local_fire_department_outlined,
      _ => Icons.star_outline,
    };
    final color = switch (type) {
      'territory' => MimzColors.mossCore,
      'materials' => MimzColors.mistBlue,
      'structure' => MimzColors.dustyGold,
      'combo' => MimzColors.persimmonHit,
      _ => MimzColors.mossCore,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.sm),
            ),
            child: Icon(iconData, color: color, size: 18),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatSource(source),
                  style: MimzTypography.headlineSmall,
                ),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            type == 'xp' ? '+${amount.toInt()} XP' :
            type == 'territory' ? '+${amount.toInt()} sectors' :
            '+${amount.toInt()}',
            style: MimzTypography.headlineSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatSource(String source) {
    return switch (source) {
      'grade_answer' => 'Quiz answer',
      'award_territory' => 'Territory earned',
      'grant_materials' => 'Materials granted',
      'apply_combo_bonus' => 'Combo bonus',
      'unlock_structure' => 'Structure unlocked',
      'validate_vision_result' => 'Vision quest',
      _ => source.replaceAll('_', ' '),
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _VaultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _VaultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: MimzTypography.headlineLarge.copyWith(color: color)),
        Text(label, style: MimzTypography.caption),
      ],
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final Blueprint blueprint;
  const _BlueprintCard({required this.blueprint});

  @override
  Widget build(BuildContext context) {
    final tierColor = switch (blueprint.tier) {
      BlueprintTier.master => MimzColors.dustyGold,
      BlueprintTier.rare => MimzColors.mistBlue,
      BlueprintTier.common => MimzColors.mossCore,
    };
    final tierIcon = switch (blueprint.tier) {
      BlueprintTier.master => Icons.star,
      BlueprintTier.rare => Icons.diamond_outlined,
      BlueprintTier.common => Icons.architecture,
    };

    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.md),
            ),
            child: Icon(tierIcon, color: tierColor, size: 28),
          ),
          const SizedBox(height: MimzSpacing.md),
          Text(blueprint.name, style: MimzTypography.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: MimzSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MimzSpacing.md,
              vertical: MimzSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.pill),
            ),
            child: Text(
              blueprint.tier.name.toUpperCase(),
              style: MimzTypography.caption.copyWith(
                color: tierColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: MimzSpacing.sm),
          Text('${blueprint.materials} materials', style: MimzTypography.bodySmall),
        ],
      ),
    );
  }
}
