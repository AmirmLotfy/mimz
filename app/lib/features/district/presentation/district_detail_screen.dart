import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../data/models/district.dart';
import '../../world/providers/world_provider.dart';
import 'district_share_sheet.dart';

/// District Detail Screen — shows structures, resources, prestige, and stats.
///
/// Accessible by tapping the district name in WorldHomeScreen's HUD.
class DistrictDetailScreen extends ConsumerWidget {
  const DistrictDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtAsync = ref.watch(districtProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Your District'),
        actions: [
          // Share district — only when loaded
          IconButton(
            onPressed: districtAsync.valueOrNull != null
                ? () => showDistrictShareSheet(context, districtAsync.valueOrNull!)
                : null,
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share district',
          ),
          IconButton(
            onPressed: () => context.go('/play'),
            icon: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.md,
                vertical: MimzSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: MimzColors.persimmonHit,
                borderRadius: BorderRadius.circular(MimzRadius.pill),
              ),
              child: Text(
                'PLAY',
                style: MimzTypography.caption.copyWith(
                  color: MimzColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: districtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load district: $e')),
        data: (district) => _DistrictBody(district: district),
      ),
    );
  }
}

class _DistrictBody extends StatelessWidget {
  final District district;
  const _DistrictBody({required this.district});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MimzSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // District banner header
          _DistrictBanner(district: district)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: MimzSpacing.xl),

          // Stats row
          _StatsRow(district: district)
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: MimzSpacing.xl),

          // Resources section
          const _SectionHeader(label: 'RESOURCES', icon: Icons.inventory_2_outlined),
          const SizedBox(height: MimzSpacing.md),
          _ResourcesCard(resources: district.resources)
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: MimzSpacing.xl),

          // District status section
          const _SectionHeader(label: 'DISTRICT STATUS', icon: Icons.shield_outlined),
          const SizedBox(height: MimzSpacing.md),
          _DistrictStatusCard(district: district)
              .animate(delay: 300.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: MimzSpacing.xl),

          // Structures section
          _SectionHeader(
            label: 'STRUCTURES',
            icon: Icons.domain_outlined,
            trailing: '${district.structures.length} unlocked',
          ),
          const SizedBox(height: MimzSpacing.md),
          if (district.structures.isEmpty)
            _EmptyStructures()
                .animate(delay: 400.ms)
                .fadeIn(duration: 400.ms)
          else
            ...district.structures.asMap().entries.map((entry) =>
              _StructureCard(structure: entry.value)
                  .animate(delay: Duration(milliseconds: 400 + entry.key * 100))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.05),
            ),
          const SizedBox(height: MimzSpacing.xxl),

          // Play CTA
          _PlayCTA(context: context)
              .animate(delay: 500.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: MimzSpacing.xxl),
        ],
      ),
    );
  }
}

class _DistrictBanner extends StatelessWidget {
  final District district;
  const _DistrictBanner({required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MimzColors.mossCore, MimzColors.mossCore.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(MimzRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MimzColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_city, color: MimzColors.white, size: 26),
              ),
              const SizedBox(width: MimzSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      district.name,
                      style: MimzTypography.displayMedium.copyWith(
                        color: MimzColors.white,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      '${district.sectors} sectors • ${district.area}',
                      style: MimzTypography.bodySmall.copyWith(
                        color: MimzColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Prestige badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.md,
                  vertical: MimzSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.dustyGold,
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Text(
                  'P${district.prestigeLevel}',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MimzSpacing.md),
          // Canonical district summary
          Row(
            children: [
              const Icon(Icons.public, color: MimzColors.acidLime, size: 16),
              const SizedBox(width: MimzSpacing.sm),
              Text(
                district.regionLabel,
                style: MimzTypography.caption.copyWith(
                  color: MimzColors.acidLime,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${district.influence}/${district.influenceThreshold} influence',
                style: MimzTypography.caption.copyWith(
                  color: MimzColors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final District district;
  const _StatsRow({required this.district});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: 'Territory',
          value: '${district.sectors}',
          icon: Icons.grid_view,
          color: MimzColors.mossCore,
        ),
        const SizedBox(width: MimzSpacing.sm),
        _StatChip(
          label: 'Frontier',
          value: '${district.frontierCount}',
          icon: Icons.explore,
          color: district.reclaimableFrontierCount > 0
              ? MimzColors.persimmonHit
              : MimzColors.mistBlue,
        ),
        const SizedBox(width: MimzSpacing.sm),
        _StatChip(
          label: 'Prestige',
          value: '${district.totalPrestige}',
          icon: Icons.military_tech,
          color: MimzColors.dustyGold,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(MimzSpacing.base),
        decoration: BoxDecoration(
          color: MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              value,
              style: MimzTypography.headlineLarge.copyWith(color: color),
            ),
            Text(label, style: MimzTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? trailing;
  const _SectionHeader({required this.label, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MimzColors.textTertiary, size: 16),
        const SizedBox(width: MimzSpacing.sm),
        Text(label, style: MimzTypography.caption.copyWith(fontWeight: FontWeight.w700)),
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing!, style: MimzTypography.caption.copyWith(color: MimzColors.mossCore)),
        ],
      ],
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  final Resources resources;
  const _ResourcesCard({required this.resources});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        children: [
          _ResourceBar(label: 'Stone', value: resources.stone, max: 2000,
              icon: Icons.terrain, color: MimzColors.textSecondary),
          const SizedBox(height: MimzSpacing.md),
          _ResourceBar(label: 'Glass', value: resources.glass, max: 1000,
              icon: Icons.fullscreen, color: MimzColors.mistBlue),
          const SizedBox(height: MimzSpacing.md),
          _ResourceBar(label: 'Wood', value: resources.wood, max: 1500,
              icon: Icons.park, color: MimzColors.mossCore),
        ],
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final IconData icon;
  final Color color;
  const _ResourceBar({
    required this.label,
    required this.value,
    required this.max,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: MimzSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: MimzTypography.bodySmall),
                  Text('$value', style: MimzTypography.bodySmall.copyWith(
                    color: color, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: MimzColors.borderLight,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DistrictStatusCard extends StatelessWidget {
  final District district;
  const _DistrictStatusCard({required this.district});

  @override
  Widget build(BuildContext context) {
    final decayLabel = switch (district.decayState) {
      'reclaimable' => 'Reclaimable',
      'vulnerable' => 'Vulnerable',
      'cooling' => 'Cooling',
      _ => 'Stable',
    };
    final decayColor = switch (district.decayState) {
      'reclaimable' => MimzColors.persimmonHit,
      'vulnerable' => MimzColors.persimmonHit,
      'cooling' => MimzColors.dustyGold,
      _ => MimzColors.mossCore,
    };

    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: decayColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: decayColor, size: 22),
                  const SizedBox(width: MimzSpacing.sm),
                  Text(
                    'Frontier $decayLabel',
                    style: MimzTypography.headlineSmall.copyWith(color: decayColor),
                  ),
                ],
              ),
              Text(
                '${district.coreCount} core • ${district.innerCount} inner • ${district.frontierCount} frontier',
                style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: MimzSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: district.influenceProgress,
              minHeight: 8,
              backgroundColor: MimzColors.borderLight,
              valueColor: AlwaysStoppedAnimation(decayColor),
            ),
          ),
          const SizedBox(height: MimzSpacing.sm),
          Text(
            district.influenceThreshold > district.influence
                ? '${district.influenceThreshold - district.influence} influence until the next expansion'
                : 'Your district is ready to expand on the next strong result',
            style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
          ),
          const SizedBox(height: MimzSpacing.base),
          Wrap(
            spacing: MimzSpacing.sm,
            runSpacing: MimzSpacing.sm,
            children: [
              _StatusTag(
                icon: Icons.warning_amber_rounded,
                label: '${district.vulnerableFrontierCount} vulnerable',
                color: district.vulnerableFrontierCount > 0
                    ? MimzColors.persimmonHit
                    : MimzColors.textTertiary,
              ),
              _StatusTag(
                icon: Icons.refresh,
                label: '${district.reclaimableFrontierCount} reclaimable',
                color: district.reclaimableFrontierCount > 0
                    ? MimzColors.dustyGold
                    : MimzColors.textTertiary,
              ),
              _StatusTag(
                icon: Icons.military_tech_outlined,
                label: 'Prestige ${district.prestigeLevel}',
                color: MimzColors.mossCore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: MimzTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StructureCard extends StatelessWidget {
  final Structure structure;
  const _StructureCard({required this.structure});

  static Color _tierColor(String tier) {
    return switch (tier) {
      'master' => MimzColors.dustyGold,
      'rare' => MimzColors.mistBlue,
      _ => MimzColors.mossCore,
    };
  }

  static IconData _tierIcon(String tier) {
    return switch (tier) {
      'master' => Icons.star,
      'rare' => Icons.diamond_outlined,
      _ => Icons.architecture,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(structure.tier);
    return Container(
      margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.sm),
            ),
            child: Icon(_tierIcon(structure.tier), color: color, size: 20),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(structure.name, style: MimzTypography.headlineSmall),
                Text(
                  structure.tier.toUpperCase(),
                  style: MimzTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MimzSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MimzRadius.pill),
            ),
            child: const Icon(Icons.check_circle_outline, size: 16, color: MimzColors.mossCore),
          ),
        ],
      ),
    );
  }
}

class _EmptyStructures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.xl),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.domain_disabled_outlined, size: 48, color: MimzColors.textTertiary),
          const SizedBox(height: MimzSpacing.md),
          Text('No structures yet', style: MimzTypography.headlineSmall),
          const SizedBox(height: MimzSpacing.sm),
          Text(
            'Use Vision Quest to discover and unlock unique structures for your district.',
            style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MimzSpacing.lg),
          GestureDetector(
            onTap: () => context.go('/play/vision'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.xl,
                vertical: MimzSpacing.md,
              ),
              decoration: BoxDecoration(
                color: MimzColors.mistBlue,
                borderRadius: BorderRadius.circular(MimzRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, color: MimzColors.white, size: 16),
                  const SizedBox(width: MimzSpacing.sm),
                  Text(
                    'START VISION QUEST',
                    style: MimzTypography.buttonText.copyWith(
                      color: MimzColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayCTA extends StatelessWidget {
  final BuildContext context;
  const _PlayCTA({required this.context});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/play'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MimzSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MimzColors.persimmonHit, Color(0xFFE05020)],
          ),
          borderRadius: BorderRadius.circular(MimzRadius.xl),
          boxShadow: [
            BoxShadow(
              color: MimzColors.persimmonHit.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: MimzColors.white, size: 24),
            const SizedBox(width: MimzSpacing.md),
            Text(
              'PLAY A ROUND TO GROW',
              style: MimzTypography.buttonText.copyWith(color: MimzColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
