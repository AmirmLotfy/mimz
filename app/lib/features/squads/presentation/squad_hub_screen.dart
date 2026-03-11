import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/squad_provider.dart';

/// Squad Hub screen — wired with providers
class SquadHubScreen extends ConsumerWidget {
  const SquadHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(squadMissionsProvider);
    final members = ref.watch(squadMembersProvider);

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(title: const Text('Squad Hub')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MimzSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create / Join buttons
            Row(
              children: [
                Expanded(
                  child: MimzButton(
                    label: 'CREATE SQUAD',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: MimzSpacing.md),
                Expanded(
                  child: MimzButton(
                    label: 'JOIN SQUAD',
                    onPressed: () {},
                    variant: MimzButtonVariant.secondary,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: MimzSpacing.xxl),
            // Active missions
            Text('ACTIVE MISSIONS', style: MimzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: MimzSpacing.md),
            ...missions.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: MimzSpacing.md),
              child: _MissionCard(mission: entry.value)
                  .animate(delay: Duration(milliseconds: 200 * entry.key))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.05),
            )),
            const SizedBox(height: MimzSpacing.xl),
            // Leaderboard
            Text('SQUAD RANKINGS', style: MimzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: MimzSpacing.md),
            ...members.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: MimzSpacing.sm),
              child: _MemberTile(
                member: entry.value,
                isFirst: entry.key == 0,
              ).animate(delay: Duration(milliseconds: 100 * entry.key))
                  .fadeIn(duration: 300.ms),
            )),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final dynamic mission;
  const _MissionCard({required this.mission});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(mission.title, style: MimzTypography.headlineSmall),
              ),
              Text(mission.deadline, style: MimzTypography.bodySmall),
            ],
          ),
          const SizedBox(height: MimzSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(MimzRadius.sm),
            child: LinearProgressIndicator(
              value: mission.progress,
              backgroundColor: MimzColors.borderLight,
              color: MimzColors.mossCore,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: MimzSpacing.sm),
          Text(
            '${(mission.progress * 100).toInt()}% complete • ${mission.members} members',
            style: MimzTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final dynamic member;
  final bool isFirst;

  const _MemberTile({required this.member, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: isFirst ? MimzColors.mossCore.withValues(alpha: 0.05) : MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(
          color: isFirst ? MimzColors.mossCore.withValues(alpha: 0.3) : MimzColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isFirst ? MimzColors.dustyGold : MimzColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${member.rank}',
                style: MimzTypography.caption.copyWith(
                  color: isFirst ? MimzColors.white : MimzColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(child: Text(member.name, style: MimzTypography.headlineSmall)),
          Text(member.xp, style: MimzTypography.bodySmall.copyWith(
            color: MimzColors.mossCore,
          )),
        ],
      ),
    );
  }
}
