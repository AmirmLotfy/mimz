import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../providers/squad_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Squad Leaderboard screen — ranks members by XP
class SquadLeaderboardScreen extends ConsumerWidget {
  const SquadLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(squadMembersProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    // Sort by XP descending (parse the numeric part)
    final sorted = [...members]..sort((a, b) {
        final aXp = int.tryParse(a.xp.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bXp = int.tryParse(b.xp.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return bXp.compareTo(aXp);
      });

    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        title: const Text('Squad Leaderboard'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MimzSpacing.xl),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [MimzColors.mossCore, MimzColors.mistBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Verdant Alliance',
                  style: MimzTypography.headlineLarge.copyWith(
                    color: MimzColors.white,
                  ),
                ),
                const SizedBox(height: MimzSpacing.sm),
                Text(
                  '${members.length} members · Season 1',
                  style: MimzTypography.bodySmall.copyWith(
                    color: MimzColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Leaderboard list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(MimzSpacing.base),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final member = sorted[index];
                final isCurrentUser = currentUser?.displayName == member.name;
                final medal = index == 0
                    ? '🥇'
                    : index == 1
                        ? '🥈'
                        : index == 2
                            ? '🥉'
                            : '${index + 1}';

                return GestureDetector(
                  onTap: () => HapticFeedback.selectionClick(),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: MimzSpacing.md),
                    padding: const EdgeInsets.all(MimzSpacing.base),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? MimzColors.mossCore.withValues(alpha: 0.08)
                          : MimzColors.white,
                      borderRadius: BorderRadius.circular(MimzRadius.md),
                      border: Border.all(
                        color: isCurrentUser
                            ? MimzColors.mossCore.withValues(alpha: 0.3)
                            : MimzColors.borderLight,
                        width: isCurrentUser ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank / medal
                        SizedBox(
                          width: 40,
                          child: Text(
                            medal,
                            style: const TextStyle(fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: MimzSpacing.md),
                        // Avatar placeholder
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              MimzColors.mossCore.withValues(alpha: 0.15),
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: MimzTypography.headlineSmall.copyWith(
                              color: MimzColors.mossCore,
                            ),
                          ),
                        ),
                        const SizedBox(width: MimzSpacing.md),
                        // Name + XP
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: MimzTypography.headlineSmall,
                                  ),
                                  if (isCurrentUser) ...[
                                    const SizedBox(width: MimzSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: MimzSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: MimzColors.mossCore,
                                        borderRadius:
                                            BorderRadius.circular(MimzRadius.sm),
                                      ),
                                      child: Text(
                                        'YOU',
                                        style: MimzTypography.caption.copyWith(
                                          color: MimzColors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                member.xp,
                                style: MimzTypography.bodySmall.copyWith(
                                  color: MimzColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // XP bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '#${index + 1}',
                              style: MimzTypography.caption.copyWith(
                                color: MimzColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: 80 * index))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.05),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
