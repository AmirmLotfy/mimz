import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design_system/tokens.dart';
import '../../../data/models/district.dart';
import '../../../data/models/game_state.dart';
import '../providers/profile_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/notifications/providers/notifications_provider.dart';
import '../../../features/squads/providers/squad_provider.dart';
import '../../../services/haptics_service.dart';
import '../../../core/providers.dart';
import '../services/profile_storage_service.dart';
import '../../world/providers/game_state_provider.dart';

/// Profile / Me screen — wired with providers and navigation
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _removePhoto() async {
    Navigator.pop(context); // close bottom sheet
    ref.read(hapticsServiceProvider).heavyImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo'),
        content:
            const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: MimzColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isUploadingPhoto = true);
      try {
        final user = ref.read(currentUserProvider).valueOrNull;
        await ref.read(apiClientProvider).patch('/profile', {
          'profileImageUrl': null,
          'storagePath': null,
        });
        if (user != null && user.storagePath != null) {
          await ProfileStorageService.deleteImage(user.storagePath!);
        }
        if (user != null) {
          ref.read(currentUserProvider.notifier).updateUser(
                user.copyWith(profileImageUrl: null, storagePath: null),
              );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove photo: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _changePhoto(bool fromCamera, {bool closeSheet = true}) async {
    if (closeSheet && Navigator.canPop(context)) {
      Navigator.pop(context); // close bottom sheet
    }
    setState(() => _isUploadingPhoto = true);
    try {
      final result =
          await ProfileStorageService.pickAndUpload(fromCamera: fromCamera);
      if (result != null) {
        final user = ref.read(currentUserProvider).valueOrNull;
        await ref.read(apiClientProvider).patch('/profile', {
          'profileImageUrl': result.url,
          'storagePath': result.storagePath,
        });
        if (user != null) {
          ref.read(currentUserProvider.notifier).updateUser(
                user.copyWith(
                    profileImageUrl: result.url,
                    storagePath: result.storagePath),
              );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _changePhoto(fromCamera, closeSheet: false),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  String _buildSquadSubtitle(WidgetRef ref) {
    final squadAsync = ref.watch(squadProvider);
    return squadAsync.when(
      data: (squad) => squad != null
          ? '${squad.name} • ${squad.members.length} members'
          : 'No squad yet — join one!',
      loading: () => 'Loading...',
      error: (_, __) => 'Tap to join a squad',
    );
  }

  static const _monthAbbrevs = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatMemberSince(DateTime date) =>
      '${_monthAbbrevs[date.month - 1]} ${date.year}';

  int _nextStreakMilestone(int dailyStreak) {
    const milestones = [3, 7, 14, 21, 30, 45, 60];
    for (final milestone in milestones) {
      if (dailyStreak < milestone) return milestone;
    }
    return dailyStreak + 15;
  }

  Widget _buildStreakCalendar(
    List<StreakHistoryEntryModel> history,
    String riskState,
    int dailyStreak,
    int bestStreak,
    int streakProtection,
  ) {
    final recentHistory =
        history.length > 14 ? history.sublist(history.length - 14) : history;
    final nextMilestone = _nextStreakMilestone(dailyStreak);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: MimzSpacing.base,
        horizontal: MimzSpacing.md,
      ),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Streaks & Rhythm', style: MimzTypography.headlineSmall),
              const Spacer(),
              Text(
                riskState == 'secured'
                    ? 'Secured'
                    : riskState == 'at_risk'
                        ? 'At Risk'
                        : 'Cold',
                style: MimzTypography.caption.copyWith(
                  color: riskState == 'secured'
                      ? MimzColors.mossCore
                      : riskState == 'at_risk'
                          ? MimzColors.persimmonHit
                          : MimzColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: MimzSpacing.xs),
          Text(
            riskState == 'secured'
                ? 'Your daily return rhythm is locked in and district protection is active.'
                : riskState == 'at_risk'
                    ? 'One fast session keeps your district safe and your streak alive.'
                    : 'A quick return session starts the rhythm again.',
            style: MimzTypography.bodySmall.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
          const SizedBox(height: MimzSpacing.base),
          Wrap(
            spacing: MimzSpacing.sm,
            runSpacing: MimzSpacing.sm,
            children: recentHistory.map((entry) {
              final date = DateTime.tryParse('${entry.date}T00:00:00') ??
                  DateTime.now();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: entry.active
                          ? MimzColors.mossCore
                          : MimzColors.borderLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: MimzSpacing.base),
          Wrap(
            spacing: MimzSpacing.sm,
            runSpacing: MimzSpacing.sm,
            children: [
              _EffectChip(label: 'Current $dailyStreak days'),
              _EffectChip(label: 'Best $bestStreak days'),
              _EffectChip(label: 'Next $nextMilestone-day reward'),
              if (streakProtection > 0)
                _EffectChip(label: '+$streakProtection shield'),
            ],
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    ref.read(hapticsServiceProvider).mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(MimzRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: MimzSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MimzColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: MimzSpacing.base),
            Text('Change Profile Photo', style: MimzTypography.headlineSmall),
            const SizedBox(height: MimzSpacing.base),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: MimzColors.mossCore),
              title: const Text('Take a photo'),
              onTap: () => _changePhoto(true),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: MimzColors.mossCore),
              title: const Text('Choose from library'),
              onTap: () => _changePhoto(false),
            ),
            if (ref.read(currentUserProvider).valueOrNull?.profileImageUrl !=
                null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: MimzColors.error),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: MimzColors.error),
                ),
                onTap: _removePhoto,
              ),
            const SizedBox(height: MimzSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final gameState = ref.watch(gameStateProvider).valueOrNull;
    final structureEffects = ref.watch(structureEffectsProvider);
    final structureProgress = ref.watch(structureProgressProvider);
    final leaderboardSnippets = ref.watch(leaderboardSnippetsProvider);
    final rankState = ref.watch(rankStateProvider);
    final districtHealth = ref.watch(districtHealthSummaryProvider);
    final primaryAction = ref.watch(recommendedPrimaryActionProvider);
    final squad = ref.watch(canonicalSquadProvider);
    final isLoading = userAsync.isLoading;
    final district = gameState?.district;
    final streakState = gameState?.streakState;
    final topTopics = [...?district?.topicAffinities]
      ..sort((a, b) => b.masteryScore.compareTo(a.masteryScore));
    final stats = {
      'Prestige': '${district?.totalPrestige ?? district?.prestigeLevel ?? 1}',
      'District Size': '${district?.sectors ?? user?.sectors ?? 0}',
      'Daily Streak': '${streakState?.dailyStreak ?? user?.dailyStreak ?? 0}',
      'Best Streak': '${streakState?.bestStreak ?? user?.streak ?? 0}',
    };

    if (userAsync.hasError) {
      return Scaffold(
        backgroundColor: MimzColors.cloudBase,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(MimzSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: MimzColors.error,
                  ),
                  const SizedBox(height: MimzSpacing.md),
                  Text(
                    'Could not load your profile.',
                    style: MimzTypography.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MimzSpacing.sm),
                  Text(
                    'Sign in again or check your connection.',
                    style: MimzTypography.bodyMedium
                        .copyWith(color: MimzColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MimzSpacing.xl),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(currentUserProvider.notifier).fetchUser(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: MimzSpacing.md),
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(isOnboardedProvider.notifier)
                          .resetOnboarding();
                      await ref.read(authServiceProvider).signOut();
                      if (mounted) context.go('/welcome');
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Sign out'),
                    style:
                        TextButton.styleFrom(foregroundColor: MimzColors.error),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: MimzColors.cloudBase,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: MimzSpacing.md),
                Text(
                  'Loading your profile…',
                  style: MimzTypography.bodyMedium
                      .copyWith(color: MimzColors.textSecondary),
                ),
                const SizedBox(height: MimzSpacing.xl),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(isOnboardedProvider.notifier)
                        .resetOnboarding();
                    await ref.read(authServiceProvider).signOut();
                    if (mounted) context.go('/welcome');
                  },
                  child: const Text(
                    'Sign out',
                    style: TextStyle(color: MimzColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: MimzSpacing.xl,
            right: MimzSpacing.xl,
            top: MimzSpacing.xl,
            bottom: MimzSpacing.xl + 100, // padding for floating pill
          ),
          child: Column(
            children: [
              // Tappable Avatar
              if (isLoading)
                const _SkeletonBox(width: 96, height: 96, radius: 48)
              else
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MimzColors.mossCore.withValues(alpha: 0.15),
                        ),
                        child: ClipOval(
                          child: _isUploadingPhoto
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : user.profileImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: user.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 96,
                                      height: 96,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName[0]
                                                  .toUpperCase()
                                              : 'M',
                                          style: MimzTypography.headlineLarge
                                              .copyWith(
                                                  color: MimzColors.mossCore),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : 'M',
                                        style: MimzTypography.headlineLarge
                                            .copyWith(
                                                color: MimzColors.mossCore),
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: MimzColors.mossCore,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: MimzColors.cloudBase, width: 2),
                          ),
                          child: const Icon(Icons.edit,
                              color: MimzColors.white, size: 12),
                        ),
                      ),
                      if ((rankState?.rank ?? 0) > 0)
                        Positioned(
                          top: -2,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MimzColors.dustyGold,
                              borderRadius:
                                  BorderRadius.circular(MimzRadius.pill),
                              border: Border.all(
                                  color: MimzColors.cloudBase, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.military_tech,
                                    color: MimzColors.white, size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  '${rankState?.rank ?? 1}',
                                  style: MimzTypography.caption.copyWith(
                                    color: MimzColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    .animate()
                    .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
              const SizedBox(height: MimzSpacing.md),
              if (isLoading) ...[
                const _SkeletonBox(width: 160, height: 20, radius: 4),
                const SizedBox(height: MimzSpacing.sm),
                const _SkeletonBox(width: 100, height: 14, radius: 4),
              ] else ...[
                Text(user.displayName, style: MimzTypography.headlineLarge),
                Text(
                  rankState != null
                      ? '${rankState.rankTitle} • ${user.handle}'
                      : user.handle,
                  style: MimzTypography.bodySmall,
                ),
                const SizedBox(height: MimzSpacing.xs),
                Text(
                  '${district?.regionLabel ?? 'Global District Grid'} • Member since ${_formatMemberSince(user.createdAt)}',
                  style: MimzTypography.caption,
                ),
              ],
              if (!isLoading) ...[
                const SizedBox(height: MimzSpacing.xl),
                _ProfileIdentityCard(
                  districtName: district?.name.isNotEmpty == true
                      ? district!.name
                      : user.districtName,
                  handle: user.handle,
                  regionLabel: district?.regionLabel ?? 'Global District Grid',
                  rankTitle: rankState?.rankTitle ?? 'Explorer',
                  rank: rankState?.rank ?? 1,
                  nextRankXp: rankState?.nextRankXp ?? 0,
                  prestigeTier: rankState?.prestigeTier ?? 'bronze',
                  squadName: squad?.name,
                  nextStructureName: structureProgress?.nextStructureName,
                  unlockedStructures: structureProgress?.unlockedCount ?? 0,
                  totalStructures: structureProgress?.totalAvailable ?? 0,
                  readyToBuild: structureProgress?.readyToBuild ?? false,
                ),
              ],
              const SizedBox(height: MimzSpacing.xxl),
              // Stats row
              if (isLoading)
                Row(
                  children: List.generate(
                      3,
                      (i) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: i < 2 ? MimzSpacing.md : 0),
                              child: const _SkeletonBox(
                                  width: double.infinity,
                                  height: 72,
                                  radius: MimzRadius.md),
                            ),
                          )),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...stats.entries.toList().asMap().entries.expand((entry) {
                        final isStreak = entry.value.key == 'Daily Streak' &&
                            (int.tryParse(entry.value.value) ?? 0) > 0;
                        final widgets = <Widget>[
                          _StatCard(
                            value: entry.value.value,
                            label: entry.value.key,
                            leadingIcon: isStreak
                                ? const Icon(Icons.local_fire_department,
                                    color: MimzColors.persimmonHit, size: 18)
                                : null,
                          ),
                        ];
                        if (entry.key < stats.length - 1) {
                          widgets.add(const SizedBox(width: MimzSpacing.md));
                        }
                        return widgets;
                      }),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              if (!isLoading) ...[
                const SizedBox(height: MimzSpacing.base),
                const _ProfileSectionLabel(
                  title: 'Rhythm',
                  subtitle: 'Your return habit, protection, and next streak target.',
                ),
                const SizedBox(height: MimzSpacing.md),
                _buildStreakCalendar(
                  streakState?.streakHistory ?? const [],
                  streakState?.streakRiskState ?? 'cold',
                  streakState?.dailyStreak ?? user.dailyStreak,
                  streakState?.bestStreak ?? user.streak,
                  structureEffects?.streakProtection ?? 0,
                ),
                if (streakState != null || structureEffects != null) ...[
                  const SizedBox(height: MimzSpacing.xl),
                  const _ProfileSectionLabel(
                    title: 'District Pulse',
                    subtitle:
                        'What your district is feeling now, and the fastest way to push it forward.',
                  ),
                  const SizedBox(height: MimzSpacing.md),
                  _DistrictPulseCard(
                    liveStreak: streakState?.liveStreak ?? user.streak,
                    dailyStreak: streakState?.dailyStreak ?? user.dailyStreak,
                    bestStreak: streakState?.bestStreak ?? user.streak,
                    streakRiskState:
                        streakState?.streakRiskState ?? 'cold',
                    districtHealth: districtHealth,
                    recommendedAction: primaryAction,
                    structureEffects: structureEffects,
                  ),
                ],
                if (topTopics.isNotEmpty) ...[
                  const SizedBox(height: MimzSpacing.xl),
                  const _ProfileSectionLabel(
                    title: 'Mastery',
                    subtitle:
                        'Your strongest knowledge lanes, win rate, and topic momentum.',
                  ),
                  const SizedBox(height: MimzSpacing.md),
                  _TopicMasteryCard(topTopics: topTopics.take(3).toList()),
                ],
                if (leaderboardSnippets.isNotEmpty) ...[
                  const SizedBox(height: MimzSpacing.xl),
                  const _ProfileSectionLabel(
                    title: 'Status',
                    subtitle:
                        'Where your district is placing right now across live boards.',
                  ),
                  const SizedBox(height: MimzSpacing.md),
                  _LeaderboardHighlightsCard(
                      snippets: leaderboardSnippets.take(3).toList()),
                ],
              ],
              const SizedBox(height: MimzSpacing.xxl),
              // Menu items — all wired to routes
              _MenuItem(
                icon: Icons.map,
                title: 'My District',
                subtitle: '${user.districtName} • ${user.sectors} sectors',
                onTap: () => context.go('/world'),
              ),
              _MenuItem(
                icon: Icons.inventory_2,
                title: 'Reward Vault',
                subtitle: '${user.sectors} sectors earned',
                onTap: () => context.push('/rewards'),
              ),
              _MenuItem(
                icon: Icons.people,
                title: 'My Squad',
                subtitle: _buildSquadSubtitle(ref),
                onTap: () => context.go('/squad'),
              ),
              // Badges / Achievements section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: MimzSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Achievements', style: MimzTypography.headlineMedium),
                    const SizedBox(height: MimzSpacing.md),
                    Consumer(builder: (_, ref, __) {
                      final badgesAsync = ref.watch(badgesProvider);
                      return badgesAsync.when(
                        loading: () => const SizedBox(
                          height: 60,
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, __) => Text(
                          'Could not load achievements',
                          style: MimzTypography.bodySmall
                              .copyWith(color: MimzColors.textTertiary),
                        ),
                        data: (badges) {
                          if (badges.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(MimzSpacing.base),
                              decoration: BoxDecoration(
                                color: MimzColors.surfaceLight,
                                borderRadius:
                                    BorderRadius.circular(MimzRadius.md),
                              ),
                              child: Text(
                                'Play rounds to earn achievements!',
                                style: MimzTypography.bodySmall
                                    .copyWith(color: MimzColors.textSecondary),
                              ),
                            );
                          }
                          return Wrap(
                            spacing: MimzSpacing.md,
                            runSpacing: MimzSpacing.md,
                            children: badges
                                .map((b) => _BadgeChip(badge: b))
                                .toList(),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: MimzSpacing.lg),
              _MenuItem(
                icon: Icons.person_search,
                title: 'Discover Players',
                subtitle: 'Find and compare with others',
                onTap: () => context.push('/social/discover'),
              ),
              _MenuItem(
                icon: Icons.bar_chart,
                title: 'Leaderboard',
                subtitle: 'View rankings',
                onTap: () => context.push('/leaderboard'),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Messages, alerts, and system logs',
                badgeCount: ref.watch(unreadNotificationsCountProvider),
                onTap: () => context.push('/notifications'),
              ),
              _MenuItem(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Account, privacy, notifications',
                onTap: () => context.push('/settings'),
              ),
              _MenuItem(
                icon: Icons.help,
                title: 'Help',
                subtitle: 'FAQ, support, feedback',
                onTap: () => context.push('/settings/help'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Widget? leadingIcon;

  const _StatCard({required this.value, required this.label, this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: MimzSpacing.base,
        horizontal: MimzSpacing.md,
      ),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 4)
              ],
              Text(value, style: MimzTypography.headlineMedium),
            ],
          ),
          Text(label, style: MimzTypography.caption),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ProfileSectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: MimzTypography.headlineMedium),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: MimzTypography.bodySmall.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  final String districtName;
  final String handle;
  final String regionLabel;
  final String rankTitle;
  final int rank;
  final int nextRankXp;
  final String prestigeTier;
  final String? squadName;
  final String? nextStructureName;
  final int unlockedStructures;
  final int totalStructures;
  final bool readyToBuild;

  const _ProfileIdentityCard({
    required this.districtName,
    required this.handle,
    required this.regionLabel,
    required this.rankTitle,
    required this.rank,
    required this.nextRankXp,
    required this.prestigeTier,
    this.squadName,
    this.nextStructureName,
    this.unlockedStructures = 0,
    this.totalStructures = 0,
    this.readyToBuild = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: MimzColors.deepInk.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                    Text(
                      'Identity',
                      style: MimzTypography.caption.copyWith(
                        color: MimzColors.mossCore,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(districtName, style: MimzTypography.headlineMedium),
                    const SizedBox(height: 2),
                    Text(
                      '$rankTitle • $handle',
                      style: MimzTypography.bodySmall.copyWith(
                        color: MimzColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MimzSpacing.sm,
                  vertical: MimzSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: MimzColors.dustyGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Text(
                  'RANK $rank',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.dustyGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MimzSpacing.base),
          Wrap(
            spacing: MimzSpacing.sm,
            runSpacing: MimzSpacing.sm,
            children: [
              _EffectChip(label: regionLabel),
              _EffectChip(label: 'Tier ${prestigeTier.toUpperCase()}'),
              _EffectChip(label: squadName ?? 'Solo district'),
            ],
          ),
          const SizedBox(height: MimzSpacing.base),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MimzSpacing.md),
            decoration: BoxDecoration(
              color: MimzColors.surfaceLight,
              borderRadius: BorderRadius.circular(MimzRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextRankXp > 0
                      ? 'Next rank in $nextRankXp XP'
                      : 'Rank threshold secured',
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MimzSpacing.sm),
                Text(
                  readyToBuild
                      ? '${nextStructureName ?? 'Structure'} is ready to build now.'
                      : totalStructures > 0
                          ? '$unlockedStructures of $totalStructures structures unlocked.'
                          : 'Keep playing to unlock district structures.',
                  style: MimzTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistrictPulseCard extends StatelessWidget {
  final int liveStreak;
  final int dailyStreak;
  final int bestStreak;
  final String streakRiskState;
  final DistrictHealthSummaryModel? districtHealth;
  final RecommendedActionModel? recommendedAction;
  final StructureEffectsModel? structureEffects;

  const _DistrictPulseCard({
    required this.liveStreak,
    required this.dailyStreak,
    required this.bestStreak,
    required this.streakRiskState,
    required this.districtHealth,
    required this.recommendedAction,
    required this.structureEffects,
  });

  @override
  Widget build(BuildContext context) {
    final effects = structureEffects;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('District Pulse', style: MimzTypography.headlineMedium),
          const SizedBox(height: MimzSpacing.xs),
          Text(
            districtHealth?.headline ??
                (streakRiskState == 'secured'
                    ? 'Your streak is protected today and your district bonuses are active.'
                    : streakRiskState == 'at_risk'
                        ? 'One quick session keeps your district rhythm alive today.'
                        : 'Start a fresh rhythm and wake your district up.'),
            style: MimzTypography.bodySmall.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
          if (districtHealth != null) ...[
            const SizedBox(height: MimzSpacing.xs),
            Text(
              districtHealth!.summary,
              style: MimzTypography.caption.copyWith(
                color: MimzColors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: MimzSpacing.base),
          Row(
            children: [
              Expanded(child: _MiniMetric(label: 'Live', value: '$liveStreak')),
              Expanded(
                  child: _MiniMetric(label: 'Daily', value: '$dailyStreak')),
              Expanded(child: _MiniMetric(label: 'Best', value: '$bestStreak')),
            ],
          ),
          if (effects != null) ...[
            const SizedBox(height: MimzSpacing.base),
            Wrap(
              spacing: MimzSpacing.sm,
              runSpacing: MimzSpacing.sm,
              children: [
                _EffectChip(
                  label: 'XP x${effects.xpMultiplier.toStringAsFixed(2)}',
                ),
                _EffectChip(
                  label:
                      'Influence x${effects.influenceMultiplier.toStringAsFixed(2)}',
                ),
                _EffectChip(
                  label:
                      'Materials x${effects.materialMultiplier.toStringAsFixed(2)}',
                ),
                if (effects.decayReduction > 0)
                  _EffectChip(
                    label: 'Decay -${(effects.decayReduction * 100).round()}%',
                  ),
                if (effects.streakProtection > 0)
                  _EffectChip(
                    label: '+${effects.streakProtection} streak shield',
                  ),
              ],
            ),
          ],
          if (recommendedAction != null) ...[
            const SizedBox(height: MimzSpacing.base),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MimzSpacing.md),
              decoration: BoxDecoration(
                color: MimzColors.surfaceLight,
                borderRadius: BorderRadius.circular(MimzRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Next',
                    style: MimzTypography.caption.copyWith(
                      color: MimzColors.mossCore,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendedAction!.title,
                    style: MimzTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recommendedAction!.impactLabel} • ${recommendedAction!.rewardPreview}',
                    style: MimzTypography.bodySmall.copyWith(
                      color: MimzColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicMasteryCard extends StatelessWidget {
  final List<DistrictTopicAffinity> topTopics;

  const _TopicMasteryCard({
    required this.topTopics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Topic Mastery', style: MimzTypography.headlineMedium),
          const SizedBox(height: MimzSpacing.xs),
          Text(
            'Your strongest knowledge lanes right now.',
            style: MimzTypography.bodySmall.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
          const SizedBox(height: MimzSpacing.base),
          ...topTopics.map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: MimzSpacing.sm),
              child: _TopicAffinityRow(topic: topic),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicAffinityRow extends StatelessWidget {
  final DistrictTopicAffinity topic;

  const _TopicAffinityRow({
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (topic.winRate * 100).round();
    final masteryProgress = (topic.masteryScore / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(MimzSpacing.md),
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
                Text(topic.topic, style: MimzTypography.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '${topic.correct}/${topic.answered} correct • $percent% win rate',
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MimzSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                  child: LinearProgressIndicator(
                    value: masteryProgress,
                    minHeight: 8,
                    backgroundColor: MimzColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      MimzColors.mossCore,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MimzSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                topic.masteryScore.toStringAsFixed(0),
                style: MimzTypography.headlineSmall.copyWith(
                  color: MimzColors.mossCore,
                ),
              ),
              Text(
                topic.streak > 0 ? '${topic.streak} streak' : 'stable',
                style: MimzTypography.caption.copyWith(
                  color: MimzColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardHighlightsCard extends StatelessWidget {
  final List<LeaderboardSummaryModel> snippets;

  const _LeaderboardHighlightsCard({
    required this.snippets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.lg),
        border: Border.all(color: MimzColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Rankings', style: MimzTypography.headlineMedium),
          const SizedBox(height: MimzSpacing.xs),
          Text(
            'Top momentum across your active boards.',
            style: MimzTypography.bodySmall.copyWith(
              color: MimzColors.textSecondary,
            ),
          ),
          const SizedBox(height: MimzSpacing.base),
          ...snippets.map(
            (snippet) => Padding(
              padding: const EdgeInsets.only(bottom: MimzSpacing.sm),
              child: _LeaderboardSnippetRow(snippet: snippet),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSnippetRow extends StatelessWidget {
  final LeaderboardSummaryModel snippet;

  const _LeaderboardSnippetRow({
    required this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    final topEntry = snippet.entries.isNotEmpty ? snippet.entries.first : null;
    final leaderName =
        topEntry?['displayName']?.toString() ?? 'No leaderboard activity yet';
    final leaderScore = (topEntry?['score'] as num?)?.toInt();

    return Container(
      padding: const EdgeInsets.all(MimzSpacing.md),
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
                Text(snippet.title, style: MimzTypography.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  leaderName,
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (leaderScore != null)
            Text(
              '$leaderScore',
              style: MimzTypography.headlineSmall.copyWith(
                color: MimzColors.mossCore,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: MimzTypography.headlineLarge.copyWith(
            color: MimzColors.mossCore,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: MimzTypography.caption.copyWith(
            color: MimzColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _EffectChip extends StatelessWidget {
  final String label;

  const _EffectChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MimzSpacing.md,
        vertical: MimzSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: MimzColors.mossCore.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MimzRadius.pill),
        border: Border.all(
          color: MimzColors.mossCore.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: MimzTypography.caption.copyWith(
          color: MimzColors.mossCore,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuItem extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? badgeCount;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(hapticsServiceProvider).selection();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
        padding: const EdgeInsets.all(MimzSpacing.base),
        decoration: BoxDecoration(
          color: MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.md),
          border: Border.all(color: MimzColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MimzColors.mossCore.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MimzRadius.sm),
              ),
              child: Icon(icon, color: MimzColors.mossCore, size: 20),
            ),
            const SizedBox(width: MimzSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MimzTypography.headlineSmall),
                  Text(subtitle, style: MimzTypography.bodySmall),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MimzColors.persimmonHit,
                  borderRadius: BorderRadius.circular(MimzRadius.pill),
                ),
                child: Text(
                  '$badgeCount',
                  style: MimzTypography.caption.copyWith(
                    color: MimzColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            const SizedBox(width: MimzSpacing.sm),
            const Icon(Icons.chevron_right, color: MimzColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeInfo badge;
  const _BadgeChip({required this.badge});

  Color get _rarityColor {
    switch (badge.rarity) {
      case 'legendary':
        return MimzColors.dustyGold;
      case 'rare':
        return MimzColors.mistBlue;
      default:
        return MimzColors.mossCore;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MimzSpacing.md,
          vertical: MimzSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: _rarityColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(MimzRadius.pill),
          border: Border.all(color: _rarityColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: _rarityColor),
            const SizedBox(width: 4),
            Text(
              badge.name,
              style: MimzTypography.caption.copyWith(
                color: _rarityColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated skeleton placeholder used while async data loads.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MimzColors.borderLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}
