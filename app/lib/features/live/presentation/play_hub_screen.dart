import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../design_system/components/mimz_button.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Screen 15 — Play Hub with quiz, vision quest, squad mission, daily sprint cards
class PlayHubScreen extends ConsumerWidget {
  const PlayHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MimzSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your\nchallenge.',
                style: MimzTypography.displayLarge.copyWith(fontSize: 34),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05),
              const SizedBox(height: MimzSpacing.sm),
              Text(
                'Every play grows your district and sharpens your mind.',
                style: MimzTypography.bodyMedium.copyWith(color: MimzColors.textSecondary),
              ),
              const SizedBox(height: MimzSpacing.xl),
              // LIVE QUIZ CARD — Persimmon
              _ChallengeCard(
                title: 'Live Quiz',
                subtitle: 'Voice-powered trivia with AI host',
                detail: 'ROUND 7 • ${user?.streak ?? 8}x STREAK',
                accentColor: MimzColors.persimmonHit,
                icon: Icons.mic,
                badge: 'LIVE',
                badgeColor: MimzColors.persimmonHit,
                onTap: () => context.go('/play/quiz'),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.md),
              // VISION QUEST CARD — Mist Blue
              _ChallengeCard(
                title: 'Vision Quest',
                subtitle: 'Point your camera, discover the world',
                detail: '3 TARGETS REMAINING',
                accentColor: MimzColors.mistBlue,
                icon: Icons.camera_alt,
                badge: 'CAMERA',
                badgeColor: MimzColors.mistBlue,
                onTap: () => context.go('/play/vision'),
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.md),
              // SQUAD MISSION — Moss
              _ChallengeCard(
                title: 'Squad Mission',
                subtitle: 'Team up and tackle bigger challenges',
                detail: '4 MEMBERS • 65% COMPLETE',
                accentColor: MimzColors.mossCore,
                icon: Icons.people,
                badge: 'TEAM',
                badgeColor: MimzColors.mossCore,
                onTap: () => context.go('/squad'),
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.md),
              // DAILY SPRINT — Dusty Gold
              _ChallengeCard(
                title: 'Daily Sprint',
                subtitle: '5 quick questions to keep your streak',
                detail: '2:30 ESTIMATED • +500 XP',
                accentColor: MimzColors.dustyGold,
                icon: Icons.bolt,
                badge: 'DAILY',
                badgeColor: MimzColors.dustyGold,
                onTap: () => context.go('/play/quiz'),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: MimzSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final Color accentColor;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.title,
    required this.subtitle,
    required this.detail,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(detail, style: MimzTypography.caption.copyWith(
                    color: accentColor, fontWeight: FontWeight.w600,
                  )),
                  Icon(Icons.arrow_forward, color: accentColor, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
