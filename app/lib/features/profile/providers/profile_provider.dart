import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers.dart';
import '../../../data/models/user.dart';

/// Profile provider delegates to currentUser
final profileProvider = Provider<AsyncValue<MimzUser>>((ref) {
  return ref.watch(currentUserProvider);
});

class BadgeInfo {
  final String achievementId;
  final String name;
  final String description;
  final String icon;
  final String rarity;
  final String? unlockedAt;

  BadgeInfo({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.unlockedAt,
  });
}

/// User's achievements/badges — fetched from API
final badgesProvider = FutureProvider<List<BadgeInfo>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final data = await apiClient.getBadges();
    final badges = data['badges'] as List<dynamic>? ?? [];
    final catalog = data['catalog'] as List<dynamic>? ?? [];

    final catalogMap = <String, Map<String, dynamic>>{};
    for (final c in catalog) {
      final cm = c as Map<String, dynamic>;
      catalogMap[cm['id'] as String] = cm;
    }

    return badges.map((b) {
      final bm = b as Map<String, dynamic>;
      final id = bm['achievementId'] as String? ?? '';
      final entry = catalogMap[id];
      return BadgeInfo(
        achievementId: id,
        name: entry?['name'] as String? ?? id,
        description: entry?['description'] as String? ?? '',
        icon: entry?['icon'] as String? ?? 'star',
        rarity: entry?['rarity'] as String? ?? 'common',
        unlockedAt: bm['unlockedAt'] as String?,
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

/// Stats derived from user. Returns zeros when no user (no demo fallback).
final userStatsProvider = Provider<Map<String, String>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final xp = user?.xp ?? 0;
  final streak = user?.streak ?? 0;
  final dailyStreak = user?.dailyStreak ?? 0;
  final sectors = user?.sectors ?? 0;
  return {
    'TOTAL XP': '$xp',
    'STREAK': '$streak',
    'DAILY STREAK': '$dailyStreak',
    'SECTORS': '$sectors',
  };
});
