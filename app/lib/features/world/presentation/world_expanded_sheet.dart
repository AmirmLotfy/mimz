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
import '../../../data/models/game_state.dart';
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
    final missionSummary = ref.watch(canonicalMissionSummaryProvider);
    final gameState = ref.watch(gameStateProvider).valueOrNull;
    final structureProgress = ref.watch(structureProgressProvider);
    final structureEffects = ref.watch(structureEffectsProvider);
    final districtHealth = ref.watch(districtHealthSummaryProvider);
    final rankState = ref.watch(rankStateProvider);
    final eventZones = ref.watch(eventZonesProvider);
    final primaryAction = ref.watch(recommendedPrimaryActionProvider);
    final secondaryAction = ref.watch(recommendedSecondaryActionProvider);
    final heroBanner = ref.watch(worldHeroBannerProvider);
    final activeConflicts = ref.watch(activeConflictsProvider);
    final squadMissions = ref.watch(squadMissionsProvider);
    final worldArrivalFeedback = ref.watch(worldArrivalFeedbackProvider);

    final districtName = district?.name ?? user?.districtName ?? 'Mimz District';
    final sectorCount = district?.sectors ?? user?.sectors ?? 7;
    final streakState = gameState?.streakState;
    final prestigeLabel = rankState != null
        ? '${rankState.rankTitle} • R${rankState.rank}'
        : 'Explorer';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      districtName,
                      style: MimzTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: MimzSpacing.xs),
                    Text(
                      '${district?.regionLabel ?? 'Global District Grid'} • $sectorCount sectors',
                      style: MimzTypography.bodySmall.copyWith(
                        color: MimzColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
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
                      Text(
                        heroBanner?.eyebrow ?? 'Today',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.mossCore,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: MimzSpacing.sm),
                      Text(
                        heroBanner?.title ?? mission,
                        style: MimzTypography.headlineMedium,
                      ),
                      const SizedBox(height: MimzSpacing.xs),
                      Text(
                        heroBanner?.body ?? 'One strong session changes your district.',
                        style: MimzTypography.bodySmall.copyWith(
                          color: MimzColors.textSecondary,
                        ),
                      ),
                      if (primaryAction != null) ...[
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
                      const SizedBox(height: MimzSpacing.base),
                      if (primaryAction != null)
                        MimzButton(
                          label: primaryAction.ctaLabel,
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            context.push(primaryAction.route);
                          },
                          variant: MimzButtonVariant.primary,
                        ),
                      if (secondaryAction != null) ...[
                        const SizedBox(height: MimzSpacing.sm),
                        GestureDetector(
                          onTap: () => context.push(secondaryAction.route),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: MimzSpacing.base,
                              vertical: MimzSpacing.base,
                            ),
                            decoration: BoxDecoration(
                              color: MimzColors.surfaceLight,
                              borderRadius: BorderRadius.circular(MimzRadius.md),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        secondaryAction.title,
                                        style: MimzTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${secondaryAction.impactLabel} • ${secondaryAction.estimatedMinutes} min',
                                        style: MimzTypography.caption.copyWith(
                                          color: MimzColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward,
                                    color: MimzColors.deepInk, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (missionSummary != null) ...[
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
                                'Mission Focus • ${missionSummary.estimatedMinutes} min',
                                style: MimzTypography.caption.copyWith(
                                  color: MimzColors.mossCore,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                missionSummary.summary,
                                style: MimzTypography.bodySmall.copyWith(
                                  color: MimzColors.textSecondary,
                                ),
                              ),
                              if (missionSummary.rewardPreview.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  missionSummary.rewardPreview,
                                  style: MimzTypography.caption.copyWith(
                                    color: MimzColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MimzSpacing.md),
              // Daily streak nudge when they have a streak and haven't played today
              if ((streakState?.dailyStreak ?? user?.dailyStreak ?? 0) > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: _StreakNudge(
                    dailyStreak: streakState?.dailyStreak ?? user?.dailyStreak ?? 0,
                    lastActivityDate: streakState?.lastActivityDate ?? user?.lastActivityDate,
                  ),
                ),
                const SizedBox(height: MimzSpacing.md),
              ],
              if (worldArrivalFeedback != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                  child: Container(
                    padding: const EdgeInsets.all(MimzSpacing.base),
                    decoration: BoxDecoration(
                      color: MimzColors.deepInk.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(MimzRadius.lg),
                      border: Border.all(
                        color: MimzColors.acidLime.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Gains',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.acidLime,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: MimzSpacing.sm),
                        Text(
                          worldArrivalFeedback.sectorsGained > 0
                              ? '${worldArrivalFeedback.districtName} gained +${worldArrivalFeedback.sectorsGained} sector${worldArrivalFeedback.sectorsGained == 1 ? '' : 's'}.'
                              : '${worldArrivalFeedback.districtName} absorbed your latest run.',
                          style: MimzTypography.bodyMedium.copyWith(
                            color: MimzColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: MimzSpacing.xs),
                        Text(
                          [
                            'Score ${worldArrivalFeedback.score}',
                            'now ${worldArrivalFeedback.newTotalSectors} sectors',
                            if (worldArrivalFeedback.materials.stone > 0)
                              '+${worldArrivalFeedback.materials.stone} stone',
                            if (worldArrivalFeedback.materials.glass > 0)
                              '+${worldArrivalFeedback.materials.glass} glass',
                            if (worldArrivalFeedback.materials.wood > 0)
                              '+${worldArrivalFeedback.materials.wood} wood',
                          ].join(' • '),
                          style: MimzTypography.bodySmall.copyWith(
                            color: MimzColors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MimzSpacing.md),
              ],
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('District Health',
                                    style: MimzTypography.headlineMedium),
                                const SizedBox(height: MimzSpacing.xs),
                                Text(
                                  districtHealth?.headline ?? 'District stable',
                                  style: MimzTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  districtHealth?.summary ??
                                      'Keep playing to grow your district.',
                                  style: MimzTypography.bodySmall.copyWith(
                                    color: MimzColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                              district?.decayState.toUpperCase() ?? 'STABLE',
                              style: MimzTypography.caption.copyWith(
                                color: MimzColors.mossCore,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MimzSpacing.base),
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
                        districtHealth != null && districtHealth.nextExpansionIn > 0
                            ? '${districtHealth.nextExpansionIn} influence to next expansion'
                            : 'Next strong result can expand your district',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.textSecondary,
                        ),
                      ),
                      if (district != null && district.decayState != 'stable') ...[
                        const SizedBox(height: MimzSpacing.base),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MimzButton(
                            label: 'RECLAIM FRONTIER',
                            onPressed: _reclaimFrontier,
                            variant: MimzButtonVariant.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Wrap(
                  spacing: MimzSpacing.md,
                  runSpacing: MimzSpacing.md,
                  children: [
                    _StatChip(
                      icon: Icons.workspace_premium,
                      value: prestigeLabel,
                      label: 'RANK',
                      color: MimzColors.dustyGold,
                    ),
                    _StatChip(
                      icon: Icons.public,
                      value: '$sectorCount sectors',
                      label: 'DISTRICT',
                      color: MimzColors.mistBlue,
                    ),
                    _StatChip(
                      icon: Icons.local_fire_department,
                      value: '${streakState?.dailyStreak ?? user?.dailyStreak ?? 0} days',
                      label: 'DAILY',
                      color: MimzColors.persimmonHit,
                    ),
                    _StatChip(
                      icon: Icons.bolt,
                      value: '${streakState?.bestStreak ?? user?.streak ?? 0}',
                      label: 'BEST STREAK',
                      color: MimzColors.mossCore,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Today\'s objective',
                                style: MimzTypography.headlineSmall),
                            const SizedBox(height: MimzSpacing.xs),
                            Text(
                              mission,
                              style: MimzTypography.bodySmall.copyWith(
                                color: MimzColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: MimzSpacing.base),
                      Text(
                        '${structureCount} built',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.mossCore,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
              if (eventZones.isNotEmpty || activeConflicts.isNotEmpty) ...[
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
                        Text('Active World',
                            style: MimzTypography.headlineSmall),
                        const SizedBox(height: MimzSpacing.xs),
                        Text(
                          'Live zone pressure, reward lanes, and frontier risks affecting your district right now.',
                          style: MimzTypography.bodySmall.copyWith(
                            color: MimzColors.textSecondary,
                          ),
                        ),
                        if (eventZones.isNotEmpty) ...[
                          const SizedBox(height: MimzSpacing.base),
                          ...eventZones.take(3).map(
                            (zone) => Padding(
                              padding: const EdgeInsets.only(bottom: MimzSpacing.sm),
                              child: _ZoneImpactCard(zone: zone),
                            ),
                          ),
                        ],
                        if (activeConflicts.isNotEmpty) ...[
                          const SizedBox(height: MimzSpacing.sm),
                          ...activeConflicts.take(2).map(
                            (conflict) => Padding(
                              padding: const EdgeInsets.only(bottom: MimzSpacing.sm),
                              child: _ConflictImpactCard(conflict: conflict),
                            ),
                          ),
                        ],
                        const SizedBox(height: MimzSpacing.xs),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.push('/events'),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Open full world activity'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MimzSpacing.lg),
              ],
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

class _ZoneImpactCard extends StatelessWidget {
  final EventZoneModel zone;

  const _ZoneImpactCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    final isLive = zone.status == 'live';
    final accent = isLive ? MimzColors.dustyGold : MimzColors.mistBlue;

    return GestureDetector(
      onTap: () => context.push('/events'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MimzSpacing.md),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(MimzRadius.sm),
              ),
              child: Icon(
                isLive ? Icons.wifi_tethering : Icons.public,
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(width: MimzSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          zone.title,
                          style: MimzTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MimzSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(MimzRadius.pill),
                        ),
                        child: Text(
                          isLive ? 'LIVE ZONE' : 'UPCOMING ZONE',
                          style: MimzTypography.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Region • ${zone.regionLabel}',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    zone.districtEffect.isNotEmpty
                        ? 'District effect • ${zone.districtEffect}'
                        : 'District effect • World pressure is shifting around this zone.',
                    style: MimzTypography.bodySmall.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reward lane • x${zone.rewardMultiplier.toStringAsFixed(zone.rewardMultiplier % 1 == 0 ? 0 : 1)}',
                    style: MimzTypography.caption.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictImpactCard extends StatelessWidget {
  final ConflictStateModel conflict;

  const _ConflictImpactCard({required this.conflict});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/district/detail'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MimzSpacing.md),
        decoration: BoxDecoration(
          color: MimzColors.persimmonHit.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(
            color: MimzColors.persimmonHit.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: MimzColors.persimmonHit.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(MimzRadius.sm),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: MimzColors.persimmonHit,
                size: 18,
              ),
            ),
            const SizedBox(width: MimzSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conflict.headline ?? 'Frontier conflict',
                    style: MimzTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conflict.summary ??
                        'A rival pressure point is affecting your frontier.',
                    style: MimzTypography.bodySmall.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${conflict.cellsAtStake} cells at stake',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.persimmonHit,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
