import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/live_session_provider.dart';

class VisionQuestSuccessScreen extends ConsumerWidget {
  const VisionQuestSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(visionQuestResultLabelProvider);
    final xp = ref.watch(visionQuestXpProvider);
    final isValid = ref.watch(visionQuestValidProvider);
    final displayLabel = label.isNotEmpty ? label : 'Discovery';

    final resultColor = isValid ? MimzColors.mossCore : MimzColors.dustyGold;
    final resultIcon = isValid ? Icons.verified : Icons.help_outline;
    final tierLabel = xp >= 200 ? 'MASTER' : xp >= 100 ? 'RARE' : 'COMMON';

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: MimzSpacing.xl),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(resultIcon, color: resultColor, size: 36),
            ).animate().scale(begin: const Offset(0, 0), duration: 500.ms),
            const SizedBox(height: MimzSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.md,
                vertical: MimzSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MimzRadius.pill),
                border: Border.all(color: resultColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, color: resultColor, size: 14),
                  const SizedBox(width: MimzSpacing.sm),
                  Text(
                    'IDENTIFIED: ${displayLabel.toUpperCase()}',
                    style: MimzTypography.caption.copyWith(
                      color: resultColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
            const SizedBox(height: MimzSpacing.md),
            Text(
              isValid
                  ? 'Your discovery has been validated and added to your district.'
                  : 'Not quite what we were looking for. Try again with a different subject!',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.xxl),
            if (isValid)
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
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.15),
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
                              color: resultColor.withValues(alpha: 0.3),
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
                                color: resultColor,
                                borderRadius: BorderRadius.circular(MimzRadius.sm),
                              ),
                              child: Text(
                                '$tierLabel BLUEPRINT',
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
                              Expanded(
                                child: Text(
                                  displayLabel,
                                  style: MimzTypography.headlineLarge.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+$xp',
                                    style: MimzTypography.headlineMedium.copyWith(
                                      color: resultColor,
                                    ),
                                  ),
                                  Text('XP EARNED', style: MimzTypography.caption),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: MimzSpacing.base),
                          const Divider(color: MimzColors.borderLight),
                          const SizedBox(height: MimzSpacing.md),
                          _ImpactRow(
                            icon: Icons.grid_view,
                            iconColor: resultColor,
                            title: 'District Impact',
                            subtitle: 'New blueprint added to your collection',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: MimzSpacing.xxl),
            MimzButton(
              label: isValid ? 'RETURN TO WORLD' : 'TRY AGAIN',
              onPressed: () => context.go(isValid ? '/world' : '/play/vision'),
            ),
            const SizedBox(height: MimzSpacing.md),
            MimzButton(
              label: 'View History',
              onPressed: () => context.push('/play/vision/history'),
              variant: MimzButtonVariant.ghost,
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
