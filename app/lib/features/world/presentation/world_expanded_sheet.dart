import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import 'package:go_router/go_router.dart';
import '../providers/world_provider.dart';
import '../providers/game_state_provider.dart';
import '../../../core/providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/squads/providers/squad_provider.dart';

const _structureCatalog = [
  (name: 'Library', sectorsNeeded: 5, xpNeeded: 500),
  (name: 'Observatory', sectorsNeeded: 10, xpNeeded: 1500),
  (name: 'Archive', sectorsNeeded: 15, xpNeeded: 3000),
  (name: 'Market Hall', sectorsNeeded: 20, xpNeeded: 5000),
  (name: 'Maker Hub', sectorsNeeded: 30, xpNeeded: 8000),
  (name: 'Grand Arena', sectorsNeeded: 40, xpNeeded: 12000),
  (name: 'Innovation Lab', sectorsNeeded: 50, xpNeeded: 20000),
];

/// Screen 14 — World Expanded Sheet (DraggableScrollableSheet overlay)
/// Shows district stats, current mission, district evolution, squad progress, and claim CTA
class WorldExpandedSheet extends ConsumerStatefulWidget {
  const WorldExpandedSheet({super.key});

  @override
  ConsumerState<WorldExpandedSheet> createState() => _WorldExpandedSheetState();
}

class _WorldExpandedSheetState extends ConsumerState<WorldExpandedSheet> {
  Future<void> _reclaimFrontier() async {
    try {
      await ref.read(apiClientProvider).reclaimFrontier();
      await ref.read(districtProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frontier stabilized. Your district is warming back up.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reclaim frontier right now. Try again in a moment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final district = ref.watch(districtProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final mission = ref.watch(currentMissionProvider).valueOrNull ?? 'Build your district';
    final structureProgress = ref.watch(structureProgressProvider);
    final structureEffects = ref.watch(structureEffectsProvider);
    final activeConflicts = ref.watch(activeConflictsProvider);
    final squadMissions = ref.watch(squadMissionsProvider);

    final districtName = district?.name ?? user?.districtName ?? 'Mimz District';
    final sectorCount = district?.sectors ?? user?.sectors ?? 7;
    final population = district?.populationFormatted ?? '850';
    final growthRate = district?.growthRate.toStringAsFixed(1) ?? '1.0';
    final prestigeLevel = district?.totalPrestige ?? (user?.xp != null
        ? _prestigeFromXp(user?.xp ?? 0)
        : 1);
    final stoneCount = district?.resources.stone ?? 0;
    final glassCount = district?.resources.glass ?? 0;
    final woodCount = district?.resources.wood ?? 0;

    // Next structure to unlock
    final structureCount = district?.structures.length ?? 0;
    final nextStructure = _getNextStructure(structureCount);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.18,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.18, 0.55, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: MimzColors.cloudBase,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(MimzRadius.xl),
              topRight: Radius.circular(MimzRadius.xl),
            ),
            boxShadow: [
              BoxShadow(
                color: MimzColors.deepInk.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: MimzSpacing.md),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MimzColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: MimzSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        districtName,
                        style: MimzTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        context.push('/play');
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: MimzColors.mossCore,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: MimzColors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
              // PLAY Button integrated into the sheet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: MimzButton(
                  label: 'PLAY',
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    context.push('/play');
                  },
                  variant: MimzButtonVariant.primary,
                ),
              ),
              const SizedBox(height: MimzSpacing.md),
              // Daily streak nudge when they have a streak and haven't played today
              if (user != null && user.dailyStreak > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: _StreakNudge(
                    dailyStreak: user.dailyStreak,
                    lastActivityDate: user.lastActivityDate,
                  ),
                ),
                const SizedBox(height: MimzSpacing.md),
              ],
              // District header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(districtName, style: MimzTypography.displayMedium),
                          Text(
                            'SEKTOR ${sectorCount.toString().padLeft(2, '0')} • ${district?.area ?? '1.0 sq km'}',
                            style: MimzTypography.caption.copyWith(
                              color: MimzColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Structure count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MimzSpacing.md,
                        vertical: MimzSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: MimzColors.mossCore.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(MimzRadius.pill),
                      ),
                      child: Text(
                        '$structureCount structures',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.mossCore,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.xl),
              // Current Mission card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Mission', style: MimzTypography.headlineMedium),
                    const SizedBox(height: MimzSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(MimzSpacing.base),
                      decoration: BoxDecoration(
                        color: MimzColors.white,
                        borderRadius: BorderRadius.circular(MimzRadius.lg),
                        border: Border.all(color: MimzColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: MimzSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: MimzColors.persimmonHit,
                                        borderRadius: BorderRadius.circular(MimzRadius.sm),
                                      ),
                                      child: Text(
                                        'PRIORITY OBJECTIVE',
                                        style: MimzTypography.caption.copyWith(
                                          color: MimzColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: MimzSpacing.md),
                                    Text(mission,
                                        style: MimzTypography.headlineMedium),
                                    Text(
                                      'Complete challenges to grow your district.',
                                      style: MimzTypography.bodySmall.copyWith(
                                        color: MimzColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: MimzColors.deepInk.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(MimzRadius.md),
                                ),
                                child: const Icon(Icons.auto_stories,
                                    color: MimzColors.dustyGold, size: 32),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
              // Real stat chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Wrap(
                  spacing: MimzSpacing.md,
                  runSpacing: MimzSpacing.md,
                  children: [
                    _StatChip(icon: Icons.people, value: population, label: 'POP'),
                    _StatChip(icon: Icons.trending_up, value: '+$growthRate%', label: 'GROWTH',
                        color: MimzColors.mossCore),
                    _StatChip(icon: Icons.diamond, value: 'LVL ${prestigeLevel.toString().padLeft(2, '0')}',
                        label: 'PRESTIGE', color: MimzColors.dustyGold),
                  ],
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
              ),
              const SizedBox(height: MimzSpacing.lg),
              if (district != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Wrap(
                    spacing: MimzSpacing.md,
                    runSpacing: MimzSpacing.md,
                    children: [
                      _StatChip(
                        icon: Icons.hexagon_outlined,
                        value: '${district.coreCount}/${district.innerCount}/${district.frontierCount}',
                        label: 'CORE/INNER/EDGE',
                        color: MimzColors.deepInk,
                      ),
                      _StatChip(
                        icon: Icons.public,
                        value: district.regionLabel,
                        label: 'REGION',
                        color: MimzColors.mistBlue,
                      ),
                      _StatChip(
                        icon: Icons.thermostat,
                        value: district.decayState.toUpperCase(),
                        label: 'DECAY',
                        color: district.decayState == 'stable'
                            ? MimzColors.mossCore
                            : MimzColors.persimmonHit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MimzSpacing.lg),
              ],
              if (structureProgress != null || activeConflicts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Container(
                    padding: const EdgeInsets.all(MimzSpacing.base),
                    decoration: BoxDecoration(
                      color: MimzColors.white,
                      borderRadius: BorderRadius.circular(MimzRadius.lg),
                      border: Border.all(color: MimzColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('District Outlook', style: MimzTypography.headlineSmall),
                        const SizedBox(height: MimzSpacing.sm),
                        if (structureProgress != null)
                          Text(
                            structureProgress.readyToBuild
                                ? '${structureProgress.nextStructureName ?? 'Structure'} is ready to build.'
                                : structureProgress.nextStructureName != null
                                    ? 'Next structure: ${structureProgress.nextStructureName}. ${structureProgress.unlockedCount}/${structureProgress.totalAvailable} unlocked.'
                                    : '${structureProgress.unlockedCount}/${structureProgress.totalAvailable} structures unlocked.',
                            style: MimzTypography.bodySmall.copyWith(
                              color: MimzColors.textSecondary,
                            ),
                          ),
                        if (structureEffects != null) ...[
                          const SizedBox(height: MimzSpacing.sm),
                          Text(
                            'Bonuses: x${structureEffects.xpMultiplier.toStringAsFixed(2)} XP • x${structureEffects.materialMultiplier.toStringAsFixed(2)} materials • x${structureEffects.influenceMultiplier.toStringAsFixed(2)} influence',
                            style: MimzTypography.caption.copyWith(
                              color: MimzColors.mossCore,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (activeConflicts.isNotEmpty) ...[
                          const SizedBox(height: MimzSpacing.sm),
                          Text(
                            '${activeConflicts.length} active frontier conflict${activeConflicts.length > 1 ? 's' : ''}.',
                            style: MimzTypography.bodySmall.copyWith(
                              color: MimzColors.persimmonHit,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MimzSpacing.lg),
              ],
              // Influence meter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Container(
                  padding: const EdgeInsets.all(MimzSpacing.base),
                  decoration: BoxDecoration(
                    color: MimzColors.white,
                    borderRadius: BorderRadius.circular(MimzRadius.lg),
                    border: Border.all(color: MimzColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, size: 18, color: MimzColors.mistBlue),
                              const SizedBox(width: MimzSpacing.sm),
                              Text('Influence', style: MimzTypography.headlineSmall),
                            ],
                          ),
                          Text(
                            '${district?.influence ?? 0} / ${district?.influenceThreshold ?? 500}',
                            style: MimzTypography.bodySmall.copyWith(
                              color: MimzColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MimzSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(MimzRadius.sm),
                        child: LinearProgressIndicator(
                          value: district?.influenceProgress ?? 0.0,
                          backgroundColor: MimzColors.borderLight,
                          color: MimzColors.mistBlue,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: MimzSpacing.sm),
                      Text(
                        district != null && district.influenceProgress >= 1.0
                            ? 'Ready to expand!'
                            : '${((district?.influenceThreshold ?? 500) - (district?.influence ?? 0)).clamp(0, 99999)} more to next expansion',
                        style: MimzTypography.bodySmall.copyWith(
                          color: district != null && district.influenceProgress >= 1.0
                              ? MimzColors.mossCore
                              : MimzColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 180.ms).fadeIn(duration: 400.ms),
              ),
              if (district != null && district.decayState != 'stable') ...[
                const SizedBox(height: MimzSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Container(
                    padding: const EdgeInsets.all(MimzSpacing.base),
                    decoration: BoxDecoration(
                      color: MimzColors.white,
                      borderRadius: BorderRadius.circular(MimzRadius.lg),
                      border: Border.all(color: MimzColors.persimmonHit.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Frontier Status', style: MimzTypography.headlineSmall),
                              const SizedBox(height: MimzSpacing.xs),
                              Text(
                                district.reclaimableFrontierCount > 0
                                    ? '${district.reclaimableFrontierCount} frontier cells are reclaimable.'
                                    : '${district.vulnerableFrontierCount} frontier cells are vulnerable.',
                                style: MimzTypography.bodySmall.copyWith(
                                  color: MimzColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: MimzSpacing.base),
                        MimzButton(
                          label: 'RECLAIM',
                          onPressed: _reclaimFrontier,
                          variant: MimzButtonVariant.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: MimzSpacing.lg),
              // Resources bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Container(
                  padding: const EdgeInsets.all(MimzSpacing.base),
                  decoration: BoxDecoration(
                    color: MimzColors.white,
                    borderRadius: BorderRadius.circular(MimzRadius.lg),
                    border: Border.all(color: MimzColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ResourceChip(icon: Icons.terrain, value: '$stoneCount', label: 'Stone'),
                      _ResourceChip(icon: Icons.fullscreen, value: '$glassCount', label: 'Glass'),
                      _ResourceChip(icon: Icons.park, value: '$woodCount', label: 'Wood'),
                    ],
                  ),
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
              ),
              const SizedBox(height: MimzSpacing.xl),
              // District Evolution — next structure
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Structure', style: MimzTypography.headlineMedium),
                    const SizedBox(height: MimzSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: MimzColors.white,
                        borderRadius: BorderRadius.circular(MimzRadius.lg),
                        border: Border.all(color: MimzColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: MimzColors.deepInk.withValues(alpha: 0.85),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(MimzRadius.lg),
                                topRight: Radius.circular(MimzRadius.lg),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: MimzColors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  nextStructure.unlocked ? Icons.check : Icons.lock,
                                  color: MimzColors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(MimzSpacing.base),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(nextStructure.name,
                                        style: MimzTypography.headlineSmall),
                                    Text(
                                      nextStructure.unlocked ? 'UNLOCKED' : 'LOCKED',
                                      style: MimzTypography.caption.copyWith(
                                        color: nextStructure.unlocked
                                            ? MimzColors.mossCore
                                            : MimzColors.persimmonHit,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: MimzSpacing.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(MimzRadius.sm),
                                  child: LinearProgressIndicator(
                                    value: nextStructure.progress,
                                    backgroundColor: MimzColors.borderLight,
                                    color: MimzColors.mistBlue,
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: MimzSpacing.sm),
                                Text(
                                  nextStructure.requirementText,
                                  style: MimzTypography.bodySmall.copyWith(
                                    color: MimzColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.xl),
              // Squad Progress — wired to provider
              if (squadMissions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Container(
                    padding: const EdgeInsets.all(MimzSpacing.base),
                    decoration: BoxDecoration(
                      color: MimzColors.white,
                      borderRadius: BorderRadius.circular(MimzRadius.lg),
                      border: Border.all(color: MimzColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Squad Progress', style: MimzTypography.headlineSmall),
                            Text(
                              '${(squadMissions.first.progress * 100).toInt()}% Total',
                              style: MimzTypography.bodySmall.copyWith(
                                color: MimzColors.persimmonHit,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MimzSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(MimzRadius.sm),
                          child: LinearProgressIndicator(
                            value: squadMissions.first.progress,
                            backgroundColor: MimzColors.borderLight,
                            color: MimzColors.persimmonHit,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: MimzSpacing.sm),
                        Text(
                          squadMissions.first.title,
                          style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
                        ),
                      ],
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                ),
              const SizedBox(height: MimzSpacing.xxl + 100), // padding for floating pill
            ],
          ),
        );
      },
    );
  }

  int _prestigeFromXp(int xp) {
    if (xp >= 50000) return 10;
    if (xp >= 30000) return 8;
    if (xp >= 15000) return 6;
    if (xp >= 8000) return 4;
    if (xp >= 3000) return 2;
    return 1;
  }

  _NextStructureInfo _getNextStructure(int currentCount) {
    if (currentCount >= _structureCatalog.length) {
      return const _NextStructureInfo('All Structures Built', 0, 0, true, 1.0);
    }

    final next = _structureCatalog[currentCount];
    final user = ref.read(currentUserProvider).valueOrNull;
    final userSectors = user?.sectors ?? 0;
    final progress = (userSectors / next.sectorsNeeded).clamp(0.0, 1.0);
    final unlocked = progress >= 1.0;

    return _NextStructureInfo(
      next.name,
      next.sectorsNeeded,
      next.xpNeeded,
      unlocked,
      progress,
    );
  }
}

class _NextStructureInfo {
  final String name;
  final int requiredSectors;
  final int requiredXp;
  final bool unlocked;
  final double progress;

  const _NextStructureInfo(this.name, this.requiredSectors, this.requiredXp, this.unlocked, this.progress);

  String get requirementText => unlocked
      ? 'Ready to build!'
      : 'Requires $requiredSectors sectors and ${requiredXp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XP';
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.color = MimzColors.deepInk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.base,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: MimzSpacing.sm),
          Text(
            '$value ',
            style: MimzTypography.headlineSmall.copyWith(
              color: color,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: MimzTypography.caption.copyWith(
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows daily streak and nudge to play 1 round to keep it when relevant.
class _StreakNudge extends StatelessWidget {
  final int dailyStreak;
  final String? lastActivityDate;

  const _StreakNudge({required this.dailyStreak, this.lastActivityDate});

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final playedToday = lastActivityDate == _today();
    return GestureDetector(
      onTap: () => context.push('/play'),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MimzSpacing.base,
          vertical: MimzSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: MimzColors.dustyGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(color: MimzColors.dustyGold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, color: MimzColors.persimmonHit, size: 22),
            const SizedBox(width: MimzSpacing.sm),
            Expanded(
              child: Text(
                playedToday
                    ? '$dailyStreak day streak'
                    : 'Play 1 round to keep your $dailyStreak day streak',
                style: MimzTypography.bodySmall.copyWith(
                  color: MimzColors.deepInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ResourceChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: MimzColors.mossCore, size: 20),
        const SizedBox(height: 4),
        Text(value, style: MimzTypography.headlineSmall.copyWith(
          color: MimzColors.mossCore, fontSize: 14,
        )),
        Text(label, style: MimzTypography.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
