import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../core/providers.dart';
import '../../../data/models/squad.dart';
import '../../world/providers/game_state_provider.dart';
import '../providers/squad_provider.dart';

/// Squad Hub screen — wired with providers and dialogs
class SquadHubScreen extends ConsumerStatefulWidget {
  const SquadHubScreen({super.key});

  @override
  ConsumerState<SquadHubScreen> createState() => _SquadHubScreenState();
}

class _SquadHubScreenState extends ConsumerState<SquadHubScreen> {
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final squad = ref.watch(squadProvider);
    final missions = ref.watch(squadMissionsProvider);
    final members = ref.watch(squadMembersProvider);
    final canonicalSummary = ref.watch(canonicalSquadSummaryProvider);
    final squadId = squad.valueOrNull?.id;
    final squadName = squad.valueOrNull?.name;
    final activeMissionCount =
        missions.where((mission) => !mission.isCompleted).length;
    final completedMissionCount =
        missions.where((mission) => mission.isCompleted).length;
    final totalMissionProgress =
        missions.fold<int>(0, (sum, mission) => sum + mission.currentProgress);
    final totalMissionGoal =
        missions.fold<int>(0, (sum, mission) => sum + mission.goalProgress);
    final squadSummaryLine = canonicalSummary == null
        ? 'Join a squad to unlock shared missions, event pressure, and weekly recap momentum.'
        : '${members.length} members • $activeMissionCount active mission${activeMissionCount == 1 ? '' : 's'}';

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(title: const Text('Squad Hub')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: MimzSpacing.base,
          right: MimzSpacing.base,
          top: MimzSpacing.base,
          bottom: MimzSpacing.base + 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: MimzButton(
                    label: 'CREATE',
                    onPressed: _isCreating
                        ? null
                        : () => _showCreateSquadDialog(context),
                    isLoading: _isCreating,
                  ),
                ),
                const SizedBox(width: MimzSpacing.md),
                Expanded(
                  child: MimzButton(
                    label: 'JOIN',
                    onPressed:
                        _isJoining ? null : () => _showJoinSquadDialog(context),
                    variant: MimzButtonVariant.secondary,
                    isLoading: _isJoining,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: MimzSpacing.xl),
            _SquadSummaryCard(
              squadName: squadName,
              summary: squadSummaryLine,
              activeMissionCount: activeMissionCount,
              completedMissionCount: completedMissionCount,
              memberCount: members.length,
              totalMissionProgress: totalMissionProgress,
              totalMissionGoal: totalMissionGoal,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04),
            const SizedBox(height: MimzSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE MISSIONS',
                    style: MimzTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                Row(
                  children: [
                    if (squadId != null)
                      GestureDetector(
                        onTap: () => _showCreateMissionSheet(context, squadId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MimzSpacing.md,
                            vertical: MimzSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: MimzColors.mossCore.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(MimzRadius.md),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  size: 16, color: MimzColors.mossCore),
                              const SizedBox(width: 4),
                              Text(
                                'New Mission',
                                style: MimzTypography.caption.copyWith(
                                  color: MimzColors.mossCore,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: MimzSpacing.md),
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
                          const Icon(Icons.chevron_right,
                              size: 16, color: MimzColors.mossCore),
                        ],
                      ),
                    ),
                  ],
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
                    child: _MissionCard(
                      mission: entry.value,
                      onContribute: squadId != null && !entry.value.isCompleted
                          ? () => _showContributeDialog(
                              context, squadId, entry.value)
                          : null,
                    )
                        .animate(delay: Duration(milliseconds: 200 * entry.key))
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.05),
                  )),
            const SizedBox(height: MimzSpacing.xl),
            Text('SQUAD RANKINGS',
                style: MimzTypography.caption.copyWith(
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
                    )
                        .animate(delay: Duration(milliseconds: 100 * entry.key))
                        .fadeIn(duration: 300.ms),
                  )),
          ],
        ),
      ),
    );
  }

  // ─── Create Squad ───────────────────────────────────────

  void _refreshSquadState() {
    ref.invalidate(gameStateProvider);
    ref.invalidate(squadProvider);
  }

  void _showCreateSquadDialog(BuildContext context) {
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
                hintStyle: MimzTypography.bodyMedium
                    .copyWith(color: MimzColors.textTertiary),
                filled: true,
                fillColor: MimzColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide: const BorderSide(color: MimzColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide:
                      const BorderSide(color: MimzColors.mossCore, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: MimzColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a squad name.')),
                );
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              setState(() => _isCreating = true);
              try {
                final res = await ref.read(apiClientProvider).createSquad(name);
                _refreshSquadState();
                final squad = res['squad'] as Map<String, dynamic>?;
                final created = squad?['name']?.toString() ?? name;
                final joinCode = squad?['joinCode']?.toString();
                if (!context.mounted) return;
                if (joinCode != null && joinCode.isNotEmpty) {
                  _showJoinCodeSheet(context, created, joinCode);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Squad "$created" created!'),
                      backgroundColor: MimzColors.mossCore,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MimzRadius.md),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create squad: $e')),
                );
              } finally {
                if (mounted) setState(() => _isCreating = false);
              }
            },
            child: const Text('Create',
                style: TextStyle(
                  color: MimzColors.mossCore,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  // ─── Join Squad ─────────────────────────────────────────

  void _showJoinSquadDialog(BuildContext context) {
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
                  borderSide:
                      const BorderSide(color: MimzColors.mossCore, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: MimzColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an invite code.')),
                );
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              setState(() => _isJoining = true);
              try {
                await ref.read(apiClientProvider).joinSquad(code);
                _refreshSquadState();
                if (!context.mounted) return;
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
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to join squad: $e')),
                );
              } finally {
                if (mounted) setState(() => _isJoining = false);
              }
            },
            child: const Text('Join',
                style: TextStyle(
                  color: MimzColors.mossCore,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  // ─── Join Code Sheet ────────────────────────────────────

  void _showJoinCodeSheet(
      BuildContext context, String squadName, String joinCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MimzColors.cloudBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          MimzSpacing.xl,
          MimzSpacing.xl,
          MimzSpacing.xl,
          MimzSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded,
                size: 40, color: MimzColors.mossCore),
            const SizedBox(height: MimzSpacing.md),
            Text(
              'Squad "$squadName" created!',
              style: MimzTypography.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              'Share this code so others can join:',
              style: MimzTypography.bodyMedium
                  .copyWith(color: MimzColors.textSecondary),
            ),
            const SizedBox(height: MimzSpacing.base),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: joinCode));
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Join code copied!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: MimzSpacing.base,
                  horizontal: MimzSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.mossCore.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  border: Border.all(
                      color: MimzColors.mossCore.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        joinCode,
                        style: MimzTypography.headlineLarge.copyWith(
                          letterSpacing: 6,
                          fontWeight: FontWeight.w800,
                          color: MimzColors.mossCore,
                        ),
                      ),
                    ),
                    const SizedBox(width: MimzSpacing.md),
                    const Icon(Icons.copy_rounded,
                        size: 20, color: MimzColors.mossCore),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            Text(
              'Tap to copy',
              style: MimzTypography.caption
                  .copyWith(color: MimzColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Create Mission ─────────────────────────────────────

  void _showCreateMissionSheet(BuildContext context, String squadId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: '100');
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MimzColors.cloudBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          MimzSpacing.xl,
          MimzSpacing.xl,
          MimzSpacing.xl,
          MimzSpacing.xxl + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MimzColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: MimzSpacing.xl),
            Text('Create Mission', style: MimzTypography.headlineLarge),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              'Set a goal for your squad to work toward.',
              style: MimzTypography.bodyMedium
                  .copyWith(color: MimzColors.textSecondary),
            ),
            const SizedBox(height: MimzSpacing.xl),
            _SheetTextField(
                controller: titleCtrl, hint: 'Mission title', autofocus: true),
            const SizedBox(height: MimzSpacing.md),
            _SheetTextField(
                controller: descCtrl,
                hint: 'Description (optional)',
                maxLines: 2),
            const SizedBox(height: MimzSpacing.md),
            _SheetTextField(
              controller: goalCtrl,
              hint: 'Goal target (e.g. 100)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: MimzSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: MimzButton(
                label: 'CREATE MISSION',
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final desc = descCtrl.text.trim();
                  final goal = int.tryParse(goalCtrl.text.trim()) ?? 100;
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a mission title.')),
                    );
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  try {
                    await ref.read(apiClientProvider).createSquadMission(
                          squadId,
                          title: title,
                          description: desc.isNotEmpty ? desc : null,
                          goalProgress: goal,
                        );
                    _refreshSquadState();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mission "$title" created!'),
                        backgroundColor: MimzColors.mossCore,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(MimzRadius.md),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create mission: $e')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Contribute Dialog ──────────────────────────────────

  void _showContributeDialog(
      BuildContext context, String squadId, SquadMission mission) {
    final controller = TextEditingController(text: '10');
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MimzColors.cloudBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MimzRadius.xl),
        ),
        title: Text('Contribute', style: MimzTypography.headlineLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add progress to "${mission.title}"',
              style: MimzTypography.bodyMedium
                  .copyWith(color: MimzColors.textSecondary),
            ),
            const SizedBox(height: MimzSpacing.sm),
            Text(
              '${mission.currentProgress} / ${mission.goalProgress}',
              style: MimzTypography.caption
                  .copyWith(color: MimzColors.textTertiary),
            ),
            const SizedBox(height: MimzSpacing.base),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: MimzTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: MimzColors.mossCore,
              ),
              decoration: InputDecoration(
                hintText: '10',
                hintStyle: MimzTypography.headlineLarge.copyWith(
                  color: MimzColors.textTertiary,
                ),
                filled: true,
                fillColor: MimzColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide: const BorderSide(color: MimzColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MimzRadius.md),
                  borderSide:
                      const BorderSide(color: MimzColors.mossCore, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: MimzColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text.trim());
              if (amount == null || amount < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enter a valid amount (1 or more).')),
                );
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).contributeToMission(
                      squadId,
                      missionId: mission.id,
                      amount: amount,
                    );
                _refreshSquadState();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contributed $amount to "${mission.title}"!'),
                    backgroundColor: MimzColors.mossCore,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MimzRadius.md),
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to contribute: $e')),
                );
              }
            },
            child: const Text('Contribute',
                style: TextStyle(
                  color: MimzColors.mossCore,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────

class _SquadSummaryCard extends StatelessWidget {
  final String? squadName;
  final String summary;
  final int activeMissionCount;
  final int completedMissionCount;
  final int memberCount;
  final int totalMissionProgress;
  final int totalMissionGoal;

  const _SquadSummaryCard({
    required this.squadName,
    required this.summary,
    required this.activeMissionCount,
    required this.completedMissionCount,
    required this.memberCount,
    required this.totalMissionProgress,
    required this.totalMissionGoal,
  });

  @override
  Widget build(BuildContext context) {
    final progressRatio = totalMissionGoal > 0
        ? (totalMissionProgress / totalMissionGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.lg),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.xl),
        border: Border.all(color: MimzColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: MimzColors.deepInk.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            squadName?.toUpperCase() ?? 'NO SQUAD YET',
            style: MimzTypography.caption.copyWith(
              color: MimzColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MimzSpacing.sm),
          Text(
            squadName ?? 'Build Your Crew',
            style: MimzTypography.headlineLarge,
          ),
          const SizedBox(height: MimzSpacing.xs),
          Text(
            summary,
            style: MimzTypography.bodyMedium.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
          const SizedBox(height: MimzSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Members',
                  value: '$memberCount',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Active',
                  value: '$activeMissionCount',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Done',
                  value: '$completedMissionCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: MimzSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(MimzRadius.pill),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: MimzColors.mossCore.withValues(alpha: 0.12),
              color: MimzColors.mossCore,
            ),
          ),
          const SizedBox(height: MimzSpacing.sm),
          Text(
            totalMissionGoal > 0
                ? '$totalMissionProgress / $totalMissionGoal shared progress'
                : 'No shared progress logged yet',
            style: MimzTypography.caption.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: MimzTypography.caption.copyWith(
            color: MimzColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: MimzTypography.headlineSmall.copyWith(
            color: MimzColors.mossCore,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool autofocus;
  final TextInputType keyboardType;

  const _SheetTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: MimzTypography.bodyMedium,
      maxLines: maxLines,
      autofocus: autofocus,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            MimzTypography.bodyMedium.copyWith(color: MimzColors.textTertiary),
        filled: true,
        fillColor: MimzColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MimzSpacing.base,
          vertical: MimzSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MimzRadius.md),
          borderSide: const BorderSide(color: MimzColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MimzRadius.md),
          borderSide: const BorderSide(color: MimzColors.mossCore, width: 2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

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
            style: MimzTypography.bodySmall
                .copyWith(color: MimzColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final SquadMission mission;
  final VoidCallback? onContribute;

  const _MissionCard({required this.mission, this.onContribute});

  @override
  Widget build(BuildContext context) {
    final pct = (mission.progress * 100).toInt();
    final isComplete = mission.isCompleted;

    return Container(
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(
          color: isComplete
              ? MimzColors.success.withValues(alpha: 0.4)
              : MimzColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isComplete ? MimzColors.success : MimzColors.mossCore,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: MimzSpacing.sm),
              Expanded(
                child: Text(mission.title, style: MimzTypography.headlineSmall),
              ),
              _StatusBadge(isCompleted: isComplete),
            ],
          ),
          if (mission.description.isNotEmpty) ...[
            const SizedBox(height: MimzSpacing.sm),
            Text(
              mission.description,
              style: MimzTypography.bodySmall
                  .copyWith(color: MimzColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: MimzSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(MimzRadius.sm),
            child: LinearProgressIndicator(
              value: mission.progress,
              backgroundColor: MimzColors.borderLight,
              color: isComplete ? MimzColors.success : MimzColors.mossCore,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: MimzSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${mission.currentProgress} / ${mission.goalProgress}  ·  $pct%',
                  style: MimzTypography.bodySmall
                      .copyWith(color: MimzColors.textSecondary),
                ),
              ),
              if (mission.deadline.isNotEmpty)
                Text(
                  mission.deadline,
                  style: MimzTypography.caption
                      .copyWith(color: MimzColors.textTertiary),
                ),
            ],
          ),
          if (onContribute != null) ...[
            const SizedBox(height: MimzSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContribute,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Contribute'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MimzColors.mossCore,
                  side: const BorderSide(color: MimzColors.mossCore),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MimzRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: MimzSpacing.md),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isCompleted;
  const _StatusBadge({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: MimzSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isCompleted
            ? MimzColors.success.withValues(alpha: 0.12)
            : MimzColors.mossCore.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MimzRadius.sm),
      ),
      child: Text(
        isCompleted ? 'COMPLETED' : 'ACTIVE',
        style: MimzTypography.caption.copyWith(
          color: isCompleted ? MimzColors.success : MimzColors.mossCore,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
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
        color: isFirst
            ? MimzColors.mossCore.withValues(alpha: 0.05)
            : MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(
          color: isFirst
              ? MimzColors.mossCore.withValues(alpha: 0.3)
              : MimzColors.borderLight,
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
          Expanded(
              child: Text(member.name, style: MimzTypography.headlineSmall)),
          Text(member.xp,
              style: MimzTypography.bodySmall.copyWith(
                color: MimzColors.mossCore,
              )),
        ],
      ),
    );
  }
}
