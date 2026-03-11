import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/world_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Screen 14 — World Expanded Sheet (DraggableScrollableSheet overlay)
/// Shows district stats, current mission, district evolution, squad progress, and claim CTA
class WorldExpandedSheet extends ConsumerStatefulWidget {
  const WorldExpandedSheet({super.key});

  @override
  ConsumerState<WorldExpandedSheet> createState() => _WorldExpandedSheetState();
}

class _WorldExpandedSheetState extends ConsumerState<WorldExpandedSheet> {
  @override
  Widget build(BuildContext context) {
    final district = ref.watch(districtProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final mission = ref.watch(currentMissionProvider);

    final districtName = district?.name ?? user?.districtName ?? 'Mimz District';
    final sectorCount = district?.sectors ?? user?.sectors ?? 7;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.12,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.12, 0.55, 0.92],
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
              const SizedBox(height: MimzSpacing.lg),
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
                            'SEKTOR ${sectorCount.toString().padLeft(2, '0')} • ARCHIVE HUB',
                            style: MimzTypography.caption.copyWith(
                              color: MimzColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Inhabitant avatars
                    SizedBox(
                      width: 80,
                      height: 36,
                      child: Stack(
                        children: [
                          _AvatarCircle(offset: 0, color: MimzColors.persimmonHit),
                          _AvatarCircle(offset: 20, color: MimzColors.mossCore),
                          Positioned(
                            left: 40,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: MimzColors.surfaceLight,
                                shape: BoxShape.circle,
                                border: Border.all(color: MimzColors.white, width: 2),
                              ),
                              child: Center(
                                child: Text('+12', style: MimzTypography.caption.copyWith(
                                  color: MimzColors.persimmonHit,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                )),
                              ),
                            ),
                          ),
                        ],
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
                                    Text('Speak to the Archive',
                                        style: MimzTypography.headlineMedium),
                                    Text(
                                      'Decipher the terminal at the old clocktower.',
                                      style: MimzTypography.bodySmall.copyWith(
                                        color: MimzColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Mission image placeholder
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
                          const SizedBox(height: MimzSpacing.base),
                          // Countdown timer
                          Row(
                            children: [
                              _TimerBox(value: '02', label: 'HRS'),
                              const SizedBox(width: MimzSpacing.md),
                              _TimerBox(value: '45', label: 'MIN'),
                              const SizedBox(width: MimzSpacing.md),
                              _TimerBox(value: '12', label: 'SEC', isActive: true),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
              // Stat chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Wrap(
                  spacing: MimzSpacing.md,
                  runSpacing: MimzSpacing.md,
                  children: [
                    _StatChip(icon: Icons.people, value: '14.2k', label: 'POP'),
                    _StatChip(icon: Icons.trending_up, value: '+4.2%', label: 'GROWTH',
                        color: MimzColors.mossCore),
                    _StatChip(icon: Icons.diamond, value: 'LVL 08', label: 'PRESTIGE',
                        color: MimzColors.dustyGold),
                  ],
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
              ),
              const SizedBox(height: MimzSpacing.xl),
              // District Evolution
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('District Evolution', style: MimzTypography.headlineMedium),
                    const SizedBox(height: MimzSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: MimzColors.white,
                        borderRadius: BorderRadius.circular(MimzRadius.lg),
                        border: Border.all(color: MimzColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          // Structure image
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: MimzColors.deepInk.withValues(alpha: 0.85),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(MimzRadius.lg),
                                topRight: Radius.circular(MimzRadius.lg),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: MimzColors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock,
                                        color: MimzColors.white, size: 24),
                                  ),
                                ],
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
                                    Text('The Great Library',
                                        style: MimzTypography.headlineSmall),
                                    Text(
                                      'EXPANSION STAGE II',
                                      style: MimzTypography.caption.copyWith(
                                        color: MimzColors.persimmonHit,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: MimzSpacing.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(MimzRadius.sm),
                                  child: LinearProgressIndicator(
                                    value: 0.35,
                                    backgroundColor: MimzColors.borderLight,
                                    color: MimzColors.mistBlue,
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: MimzSpacing.sm),
                                Text(
                                  'LOCKED: Reach Prestige Level 10 to begin restoration.',
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
              // Squad Progress
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
                            '68% Total',
                            style: MimzTypography.bodySmall.copyWith(
                              color: MimzColors.persimmonHit,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MimzSpacing.md),
                      Row(
                        children: [
                          // Squad avatar stack
                          SizedBox(
                            width: 60,
                            height: 28,
                            child: Stack(
                              children: [
                                _SmallAvatar(offset: 0, color: MimzColors.dustyGold),
                                _SmallAvatar(offset: 16, color: MimzColors.mossCore),
                                _SmallAvatar(offset: 32, color: MimzColors.persimmonHit),
                              ],
                            ),
                          ),
                          const SizedBox(width: MimzSpacing.md),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(MimzRadius.sm),
                              child: LinearProgressIndicator(
                                value: 0.68,
                                backgroundColor: MimzColors.borderLight,
                                color: MimzColors.persimmonHit,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              ),
              const SizedBox(height: MimzSpacing.xl),
              // Claim CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: MimzSpacing.lg),
                    decoration: BoxDecoration(
                      color: MimzColors.persimmonHit,
                      borderRadius: BorderRadius.circular(MimzRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: MimzColors.persimmonHit.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: MimzColors.white, size: 22),
                        const SizedBox(width: MimzSpacing.md),
                        Text(
                          'CLAIM PERSIMMON HIT',
                          style: MimzTypography.buttonText.copyWith(
                            color: MimzColors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: MimzSpacing.md),
                        Text(
                          '+150 XP',
                          style: MimzTypography.bodySmall.copyWith(
                            color: MimzColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.95, 0.95), duration: 300.ms),
              ),
              const SizedBox(height: MimzSpacing.md),
              Center(
                child: Text(
                  'NEXT REWARD AVAILABLE IN 14:22:01',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final double offset;
  final Color color;
  const _AvatarCircle({required this.offset, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: MimzColors.white, width: 2),
        ),
        child: Icon(Icons.person, color: color, size: 16),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final double offset;
  final Color color;
  const _SmallAvatar({required this.offset, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: MimzColors.white, width: 1.5),
        ),
      ),
    );
  }
}

class _TimerBox extends StatelessWidget {
  final String value;
  final String label;
  final bool isActive;

  const _TimerBox({
    required this.value,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 44,
          decoration: BoxDecoration(
            color: MimzColors.surfaceLight,
            borderRadius: BorderRadius.circular(MimzRadius.sm),
            border: isActive
                ? Border.all(color: MimzColors.persimmonHit, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              value,
              style: MimzTypography.headlineLarge.copyWith(
                color: isActive ? MimzColors.persimmonHit : MimzColors.deepInk,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: MimzTypography.caption),
      ],
    );
  }
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
