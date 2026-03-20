import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../design_system/tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';

/// Leaderboard screen with podium, tabs, and ranked player list
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: leaderboardScopes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AsyncValue<List<LeaderboardEntryModel>> _providerForTab(int tab) {
    return ref.watch(leaderboardProvider(leaderboardScopes[tab]));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      backgroundColor: MimzColors.cloudBase,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Leaderboard'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: MimzSpacing.base,
              vertical: MimzSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: MimzColors.surfaceLight,
              borderRadius: BorderRadius.circular(MimzRadius.md),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: MimzColors.white,
                borderRadius: BorderRadius.circular(MimzRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: MimzColors.deepInk.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: MimzColors.deepInk,
              unselectedLabelColor: MimzColors.textSecondary,
              labelStyle: MimzTypography.labelLarge.copyWith(fontSize: 13),
              dividerColor: Colors.transparent,
              onTap: (_) => setState(() {}),
              tabs: leaderboardScopes.map((scope) => Tab(text: scope.label)).toList(),
            ),
          ),
          Expanded(
            child: _buildTabContent(currentUser),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(dynamic currentUser) {
    final dataAsync = _providerForTab(_tabController.index);
    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: MimzColors.mossCore)),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (entries) {
        if (entries.isEmpty) {
          final scope = leaderboardScopes[_tabController.index].scope;
          final label = scope == 'weekly'
              ? 'No activity this week yet'
              : scope == 'squad'
                  ? 'Join a squad to see rankings'
                  : scope == 'event'
                      ? 'No live event rankings yet'
                      : scope == 'topic'
                          ? 'No topic rankings yet'
                          : 'No entries yet';
          return Center(
            child: Text(label, style: MimzTypography.bodySmall.copyWith(color: MimzColors.textSecondary)),
          );
        }
        final players = entries.map((e) => _LeaderboardEntry(
          rank: e.rank,
          name: e.displayName,
          xp: e.score,
          district: e.districtName ?? '',
          isCurrentUser: currentUser?.id == e.userId,
        )).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MimzSpacing.xl,
                vertical: MimzSpacing.base,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: players.length > 1 ? _PodiumItem(
                      entry: players[1], height: 80,
                      color: MimzColors.textSecondary, medal: '🥈',
                    ) : const SizedBox(),
                  ),
                  const SizedBox(width: MimzSpacing.md),
                  Expanded(
                    child: players.isNotEmpty ? _PodiumItem(
                      entry: players[0], height: 100,
                      color: MimzColors.dustyGold, medal: '🥇',
                    ) : const SizedBox(),
                  ),
                  const SizedBox(width: MimzSpacing.md),
                  Expanded(
                    child: players.length > 2 ? _PodiumItem(
                      entry: players[2], height: 64,
                      color: MimzColors.persimmonHit, medal: '🥉',
                    ) : const SizedBox(),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            ),
            const SizedBox(height: MimzSpacing.md),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: MimzSpacing.base),
                itemCount: players.length > 3 ? players.length - 3 : 0,
                itemBuilder: (context, index) {
                  final entry = players[index + 3];
                  return _RankingTile(entry: entry)
                      .animate(delay: Duration(milliseconds: 100 * index))
                      .fadeIn(duration: 300.ms);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeaderboardEntry {
  final int rank;
  final String name;
  final int xp;
  final String district;
  final bool isCurrentUser;

  const _LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.xp,
    required this.district,
    this.isCurrentUser = false,
  });
}

class _PodiumItem extends StatelessWidget {
  final _LeaderboardEntry entry;
  final double height;
  final Color color;
  final String medal;

  const _PodiumItem({
    required this.entry,
    required this.height,
    required this.color,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: MimzSpacing.sm),
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            entry.name[0],
            style: MimzTypography.headlineMedium.copyWith(color: color),
          ),
        ),
        const SizedBox(height: MimzSpacing.sm),
        Text(
          entry.name,
          style: MimzTypography.labelLarge.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${_formatXp(entry.xp)} XP',
          style: MimzTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: MimzSpacing.sm),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(MimzRadius.md),
              topRight: Radius.circular(MimzRadius.md),
            ),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: MimzTypography.headlineLarge.copyWith(
                color: color,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankingTile extends StatelessWidget {
  final _LeaderboardEntry entry;

  const _RankingTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: MimzSpacing.sm),
      padding: const EdgeInsets.all(MimzSpacing.base),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? MimzColors.mossCore.withValues(alpha: 0.05)
            : MimzColors.white,
        borderRadius: BorderRadius.circular(MimzRadius.md),
        border: Border.all(
          color: entry.isCurrentUser
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
              color: entry.isCurrentUser
                  ? MimzColors.mossCore
                  : MimzColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: MimzTypography.caption.copyWith(
                  color: entry.isCurrentUser
                      ? MimzColors.white
                      : MimzColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: MimzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: MimzTypography.headlineSmall,
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: MimzSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MimzSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MimzColors.mossCore,
                          borderRadius: BorderRadius.circular(MimzRadius.sm),
                        ),
                        child: Text(
                          'YOU',
                          style: MimzTypography.caption.copyWith(
                            color: MimzColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(entry.district, style: MimzTypography.bodySmall),
              ],
            ),
          ),
          Text(
            '${_formatXp(entry.xp)} XP',
            style: MimzTypography.bodySmall.copyWith(
              color: MimzColors.mossCore,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatXp(int xp) {
  if (xp >= 1000) {
    return '${(xp / 1000).toStringAsFixed(1)}k';
  }
  return '$xp';
}
