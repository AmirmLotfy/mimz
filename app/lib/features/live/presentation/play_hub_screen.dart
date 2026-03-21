import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/world/providers/world_provider.dart';
import '../../../features/world/providers/game_state_provider.dart';
import '../providers/live_providers.dart';

/// Screen 15 — Play Hub with quiz, vision quest, squad mission, daily sprint cards
class PlayHubScreen extends ConsumerStatefulWidget {
  const PlayHubScreen({super.key});

  @override
  ConsumerState<PlayHubScreen> createState() => _PlayHubScreenState();
}

class _PlayHubScreenState extends ConsumerState<PlayHubScreen> {
  bool _prefetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefetched) return;
    _prefetched = true;
    Future.microtask(() async {
      final tokenClient = ref.read(liveTokenClientProvider);
      try {
        await Future.wait<void>([
          tokenClient.fetchToken(sessionType: 'quiz').then((_) {}),
          tokenClient.fetchToken(sessionType: 'sprint').then((_) {}),
        ]);
      } catch (_) {}

      final activeEvent = ref.read(canonicalActiveEventProvider);
      if (activeEvent != null) {
        try {
          await tokenClient.fetchToken(
            sessionType: 'event',
            eventId: activeEvent.id,
          );
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final district = ref.watch(districtProvider).valueOrNull;
    final mission = ref.watch(canonicalMissionProvider);
    final missionSummary = ref.watch(canonicalMissionSummaryProvider);
    final activeEvent = ref.watch(canonicalActiveEventProvider);
    final squadSummary = ref.watch(canonicalSquadSummaryProvider);
    final primaryAction = ref.watch(recommendedPrimaryActionProvider);
    final secondaryAction = ref.watch(recommendedSecondaryActionProvider);
    final heroBanner = ref.watch(worldHeroBannerProvider);

    final streak = user?.streak ?? 0;
    final sectors = district?.sectors ?? user?.sectors ?? 0;
    final featuredActionTypes = <String>{
      if (primaryAction != null) primaryAction.type,
      if (secondaryAction != null) secondaryAction.type,
    };

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: MimzSpacing.base,
            right: MimzSpacing.base,
            top: MimzSpacing.base,
            bottom: MimzSpacing.base + 100, // padding for floating pill
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heroBanner?.title ?? 'Choose your\nchallenge.',
                style: MimzTypography.displayLarge.copyWith(fontSize: 34),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05),
              const SizedBox(height: MimzSpacing.sm),
              Text(
                missionSummary?.summary ??
                    heroBanner?.body ??
                    'Every play grows your district and sharpens your mind.',
                style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
              ),
              const SizedBox(height: MimzSpacing.xl),
              if (primaryAction != null)
                _ChallengeCard(
                  title: primaryAction.title,
                  subtitle: primaryAction.subtitle,
                  detail:
                      '${primaryAction.impactLabel.toUpperCase()} • ${primaryAction.estimatedMinutes} MIN',
                  rewardPreview: primaryAction.rewardPreview,
                  accentColor: MimzColors.persimmonHit,
                  icon: _iconForAction(primaryAction.type),
                  badge: primaryAction.badge,
                  badgeColor: MimzColors.persimmonHit,
                  onTap: () => context.go(primaryAction.route),
                ).animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              if (primaryAction != null) const SizedBox(height: MimzSpacing.md),
              if (secondaryAction != null)
                _ChallengeCard(
                  title: secondaryAction.title,
                  subtitle: secondaryAction.subtitle,
                  detail:
                      '${secondaryAction.impactLabel.toUpperCase()} • ${secondaryAction.estimatedMinutes} MIN',
                  rewardPreview: secondaryAction.rewardPreview,
                  accentColor: MimzColors.dustyGold,
                  icon: _iconForAction(secondaryAction.type),
                  badge: secondaryAction.badge,
                  badgeColor: MimzColors.dustyGold,
                  onTap: () => context.go(secondaryAction.route),
                ).animate(delay: 180.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              if (secondaryAction != null) const SizedBox(height: MimzSpacing.md),
              if (!featuredActionTypes.contains('quiz')) ...[
                _ChallengeCard(
                  title: 'Live Quiz',
                  subtitle: 'Main district round with your live host',
                  detail: streak > 0
                      ? '${streak}x STREAK • $sectors SECTORS'
                      : 'START YOUR STREAK',
                  rewardPreview:
                      'Frontier growth, materials, and district progress.',
                  accentColor: MimzColors.persimmonHit,
                  icon: Icons.mic,
                  badge: 'LIVE',
                  badgeColor: MimzColors.persimmonHit,
                  onTap: () => context.go('/play/quiz'),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: MimzSpacing.md),
              ],
              if (!featuredActionTypes.contains('vision')) ...[
                _ChallengeCard(
                  title: 'Vision Quest',
                  subtitle: 'One focused camera challenge with district rewards',
                  detail: activeEvent != null
                      ? 'EVENT BONUS ACTIVE'
                      : '${(sectors % 5) + 1} TARGETS REMAINING',
                  rewardPreview:
                      'Fast blueprint progress and structure-linked rewards.',
                  accentColor: MimzColors.mistBlue,
                  icon: Icons.camera_alt,
                  badge: 'CAMERA',
                  badgeColor: MimzColors.mistBlue,
                  onTap: () => context.go('/play/vision'),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: MimzSpacing.md),
              ],
              if (!featuredActionTypes.contains('squad')) ...[
                _ChallengeCard(
                  title: 'Squad Mission',
                  subtitle: 'Shared progress that rides on your next session',
                  detail: squadSummary != null && squadSummary.missions.isNotEmpty
                      ? squadSummary.missions.first.title.toUpperCase()
                      : 'EARN BONUS TERRITORY',
                  rewardPreview:
                      'Shared mission momentum and squad leaderboard movement.',
                  accentColor: MimzColors.mossCore,
                  icon: Icons.people,
                  badge: 'TEAM',
                  badgeColor: MimzColors.mossCore,
                  onTap: () => context.go('/squad'),
                ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: MimzSpacing.md),
              ],
              if (!featuredActionTypes.contains('sprint')) ...[
                _ChallengeCard(
                  title: 'Daily Sprint',
                  subtitle: '3 rapid-fire questions to protect your rhythm',
                  detail: missionSummary != null
                      ? '${missionSummary.estimatedMinutes} MIN • ${missionSummary.title.toUpperCase()}'
                      : mission != null && mission.isNotEmpty
                          ? mission.toUpperCase()
                          : '~2 MIN • +${300 + streak * 50} XP',
                  rewardPreview:
                      'Daily bonus, streak protection, and quick influence.',
                  accentColor: MimzColors.dustyGold,
                  icon: Icons.bolt,
                  badge: 'DAILY',
                  badgeColor: MimzColors.dustyGold,
                  onTap: () => context.go('/play/sprint'),
                ).animate(delay: 800.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: MimzSpacing.xxl),
              ] else
                const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForAction(String type) {
  switch (type) {
    case 'sprint':
      return Icons.bolt;
    case 'event':
      return Icons.wifi_tethering;
    case 'vision':
      return Icons.camera_alt;
    case 'reclaim':
      return Icons.shield_outlined;
    case 'squad':
      return Icons.people;
    case 'build':
      return Icons.account_balance;
    case 'quiz':
    default:
      return Icons.mic;
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final String rewardPreview;
  final Color accentColor;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.rewardPreview,
    required this.accentColor,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(MimzSpacing.lg),
        decoration: BoxDecoration(
          color: MimzColors.white,
          borderRadius: BorderRadius.circular(MimzRadius.xl),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
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
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MimzRadius.md),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: MimzSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: MimzTypography.headlineMedium),
                      Text(subtitle, style: MimzTypography.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MimzSpacing.md,
                    vertical: MimzSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MimzRadius.pill),
                  ),
                  child: Text(
                    badge,
                    style: MimzTypography.caption.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MimzSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: MimzSpacing.md,
                horizontal: MimzSpacing.base,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(MimzRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(detail, style: MimzTypography.caption.copyWith(
                          color: accentColor, fontWeight: FontWeight.w600,
                        )),
                      ),
                      Icon(Icons.arrow_forward, color: accentColor, size: 18),
                    ],
                  ),
                  const SizedBox(height: MimzSpacing.xs),
                  Text(
                    rewardPreview,
                    style: MimzTypography.bodySmall.copyWith(
                      color: MimzColors.textSecondary,
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
