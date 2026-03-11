import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';

/// Vision Quest Success screen
class VisionQuestSuccessScreen extends StatelessWidget {
  const VisionQuestSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/play'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'VISION QUEST',
          style: MimzTypography.caption.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MimzColors.deepInk,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: MimzSpacing.xl),
            // Success check
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: MimzColors.mossCore.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: MimzColors.mossCore,
                size: 36,
              ),
            ).animate().scale(begin: const Offset(0, 0), duration: 500.ms),
            const SizedBox(height: MimzSpacing.lg),
            Text(
              'Discovery Verified',
              style: MimzTypography.displayMedium,
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: MimzSpacing.md),
            Text(
              'Your contribution to the district has been validated. The blueprint is now yours.',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.xxl),
            // Blueprint reward card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.lg),
                border: Border.all(color: MimzColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MimzColors.mossCore.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(MimzRadius.lg),
                        topRight: Radius.circular(MimzRadius.lg),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.account_balance,
                            color: MimzColors.mossCore.withValues(alpha: 0.3),
                            size: 80,
                          ),
                        ),
                        Positioned(
                          bottom: MimzSpacing.md,
                          left: MimzSpacing.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MimzSpacing.md,
                              vertical: MimzSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: MimzColors.dustyGold,
                              borderRadius: BorderRadius.circular(MimzRadius.sm),
                            ),
                            child: Text(
                              'MASTER BLUEPRINT',
                              style: MimzTypography.caption.copyWith(
                                color: MimzColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                            Text(
                              'Solarium Wing',
                              style: MimzTypography.headlineLarge.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+250',
                                  style: MimzTypography.headlineMedium.copyWith(
                                    color: MimzColors.mossCore,
                                  ),
                                ),
                                Text('MATERIALS', style: MimzTypography.caption),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          'Tactile architectural reward',
                          style: MimzTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: MimzSpacing.base),
                        const Divider(color: MimzColors.borderLight),
                        const SizedBox(height: MimzSpacing.md),
                        _ImpactRow(
                          icon: Icons.grid_view,
                          iconColor: MimzColors.mossCore,
                          title: 'District Impact',
                          subtitle: 'Prestige Level Up • Tier 3 Influence',
                        ),
                        const SizedBox(height: MimzSpacing.md),
                        _ImpactRow(
                          icon: Icons.bolt,
                          iconColor: MimzColors.persimmonHit,
                          title: 'Sustainability Bonus',
                          subtitle: '+15% Passive Resource Gen',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: MimzSpacing.xxl),
            MimzButton(
              label: '🏛  Place Structure',
              onPressed: () => context.go('/world'),
            ),
            const SizedBox(height: MimzSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ImpactRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(MimzRadius.sm),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: MimzSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: MimzTypography.headlineSmall),
            Text(subtitle, style: MimzTypography.bodySmall),
          ],
        ),
      ],
    );
  }
}
