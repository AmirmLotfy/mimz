import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../providers/squad_provider.dart';

/// Squad Hub screen — wired with providers and dialogs
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
                    onPressed: () => _showCreateSquadDialog(context, ref),
                  ),
                ),
                const SizedBox(width: MimzSpacing.md),
                Expanded(
                  child: MimzButton(
                    label: 'JOIN SQUAD',
                    onPressed: () => _showJoinSquadDialog(context, ref),
                    variant: MimzButtonVariant.secondary,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: MimzSpacing.xxl),
            // Active missions header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE MISSIONS', style: MimzTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                GestureDetector(
                  onTap: () => context.push('/squad/leaderboard'),
                  child: Row(
                    children: [
                      Text(
                        'Leaderboard',
                        style: MimzTypography.caption.copyWith(
                          color: MimzColors.mossCore,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: MimzColors.mossCore),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.md),
            if (missions.isEmpty)
              const _EmptyState(
                icon: Icons.flag_outlined,
                title: 'No active missions',
                subtitle: 'Join or create a squad to start missions together.',
              )
            else
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
            if (members.isEmpty)
              const _EmptyState(
                icon: Icons.people_outline,
                title: 'No members yet',
                subtitle: 'Invite others to join your squad.',
              )
            else
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

  void _showCreateSquadDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MimzColors.cloudBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MimzRadius.xl),
        ),
        title: Text('Create Squad', style: MimzTypography.headlineLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Give your squad a name to get started.',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            TextField(
              controller: controller,
              style: MimzTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'e.g. Verdant Pioneers',
                hintStyle: MimzTypography.bodyMedium.copyWith(color: MimzColors.textTertiary),
                filled: true,
                fillColor: MimzColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide: const BorderSide(color: MimzColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide: const BorderSide(color: MimzColors.mossCore, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: MimzColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Squad "${controller.text.isNotEmpty ? controller.text : 'New Squad'}" created!'),
                  backgroundColor: MimzColors.mossCore,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MimzRadius.md),
                  ),
                ),
              );
            },
            child: const Text('Create', style: TextStyle(
              color: MimzColors.mossCore,
              fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
    );
  }

  void _showJoinSquadDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MimzColors.cloudBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MimzRadius.xl),
        ),
        title: Text('Join Squad', style: MimzTypography.headlineLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a squad invite code to join.',
              style: MimzTypography.bodyMedium.copyWith(
                color: MimzColors.textSecondary,
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            TextField(
              controller: controller,
              style: MimzTypography.bodyMedium.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'ABCDEF',
                hintStyle: MimzTypography.bodyMedium.copyWith(
                  color: MimzColors.textTertiary,
                  letterSpacing: 4,
                ),
                filled: true,
                fillColor: MimzColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide: const BorderSide(color: MimzColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide: const BorderSide(color: MimzColors.mossCore, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: MimzColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Joined squad successfully!'),
                  backgroundColor: MimzColors.mossCore,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MimzRadius.md),
                  ),
                ),
              );
            },
            child: const Text('Join', style: TextStyle(
              color: MimzColors.mossCore,
              fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

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
          Icon(icon, color: MimzColors.textTertiary, size: 40),
          const SizedBox(height: MimzSpacing.md),
          Text(title, style: MimzTypography.headlineSmall),
          const SizedBox(height: MimzSpacing.sm),
          Text(
            subtitle,
            style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
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
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: MimzColors.mossCore,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: MimzSpacing.sm),
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
