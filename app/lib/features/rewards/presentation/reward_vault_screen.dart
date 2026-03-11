import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          onPressed: () => Navigator.of(context).pop(),
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
            // Blueprint grid
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
          ],
        ),
      ),
    );
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
            child: Icon(Icons.architecture, color: tierColor, size: 28),
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
